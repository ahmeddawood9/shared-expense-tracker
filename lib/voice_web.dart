import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:web/web.dart' as web;
import 'models.dart';

// ════════════════════════════════════════════════════════════
//  WEB SPEECH API — dart:js_interop extension types
// ════════════════════════════════════════════════════════════

@JS('SpeechRecognition')
@staticInterop
class SpeechRecognitionJS {
  external factory SpeechRecognitionJS();
}

extension SpeechRecognitionJSExtension on SpeechRecognitionJS {
  external set lang(String v);
  external set continuous(bool v);
  external set interimResults(bool v);
  external set maxAlternatives(int v);
  external set onresult(JSFunction v);
  external set onend(JSFunction v);
  external set onerror(JSFunction v);
  external void start();
  external void stop();
}

// Minimal binding for the result event
extension type SpeechRecognitionEvent._(JSObject _) implements JSObject {
  external int get resultIndex;
  external SpeechRecognitionResultList get results;
}

extension type SpeechRecognitionResultList._(JSObject _) implements JSObject {
  external SpeechRecognitionResult item(int index);
}

extension type SpeechRecognitionResult._(JSObject _) implements JSObject {
  external bool get isFinal;
  external SpeechRecognitionAlternative item(int index);
}

extension type SpeechRecognitionAlternative._(JSObject _) implements JSObject {
  external String get transcript;
}

// Minimal binding for the error event
extension type SpeechRecognitionErrorEvent._(JSObject _) implements JSObject {
  external String get error;
}

class VoiceController extends ChangeNotifier {
  final ExpenseState _expenseState;

  late final GenerativeModel _model;
  bool _isListening = false;
  bool get isListening => _isListening;
  String _status = "Idle";
  String get status => _status;
  String _lastWords = "";
  String get lastWords => _lastWords;
  bool _isProcessing = false;

  SpeechRecognitionJS? _webRecognition;

  VoiceController(this._expenseState) {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
  }

  Future<void> init() async {
    _initWebSpeech();
  }

  void _initWebSpeech() {
    final win = globalContext;
    final hasSR  = win.has('SpeechRecognition');
    final hasWSR = win.has('webkitSpeechRecognition');
    if (!hasSR && !hasWSR) {
      print("VUI Web: SpeechRecognition not available.");
      return;
    }

    final ctorName = hasSR ? 'SpeechRecognition' : 'webkitSpeechRecognition';
    final ctor     = win.getProperty(ctorName.toJS) as JSFunction;
    _webRecognition = ctor.callAsConstructor<SpeechRecognitionJS>();

    _webRecognition!.lang           = 'en-US';
    _webRecognition!.interimResults = true;
    _webRecognition!.continuous     = false;
    _webRecognition!.maxAlternatives = 1;

    _webRecognition!.onresult = ((SpeechRecognitionEvent event) {
      try {
        final idx      = event.resultIndex;
        final result   = event.results.item(idx);
        final isFinal  = result.isFinal;
        final transcript = result.item(0).transcript.trim();

        _lastWords = transcript;
        _updateStatus(isFinal ? "Processing..." : "Heard: $_lastWords");
        notifyListeners();

        if (isFinal && _lastWords.isNotEmpty) {
          _isListening = false;
          notifyListeners();
          _processVoiceInput(_lastWords);
        }
      } catch (e) {
        print("VUI Web onresult error: $e");
      }
    }.toJS);

    _webRecognition!.onend = ((JSObject _) {
      if (_isListening) {
        _isListening = false;
        if (_lastWords.isNotEmpty) _processVoiceInput(_lastWords);
        notifyListeners();
      }
    }.toJS);

    _webRecognition!.onerror = ((SpeechRecognitionErrorEvent event) {
      final err = event.error;
      print("VUI Web error: $err");
      _isListening = false;
      _updateStatus(
        (err == 'not-allowed' || err == 'service-not-allowed')
            ? "Mic blocked — allow access in Safari"
            : "Error: $err",
      );
      notifyListeners();
    }.toJS);

    print("VUI Web: SpeechRecognition initialised.");
  }

  void _updateStatus(String s) { _status = s; notifyListeners(); }

  Future<void> speak(String text) async {
    try {
      final utterance = web.SpeechSynthesisUtterance(text);
      utterance.lang  = 'en-US';
      utterance.rate  = 0.9;
      web.window.speechSynthesis.speak(utterance);
    } catch (e) { print("VUI Web TTS error: $e"); }
  }

  Future<void> listen() async {
    if (_webRecognition == null) {
      _updateStatus("Speech API not supported in this browser");
      return;
    }
    if (_isListening) {
      _webRecognition!.stop();
      _isListening = false;
      _updateStatus("Stopped");
      notifyListeners();
      return;
    }
    _isListening = true;
    _lastWords   = "";
    _updateStatus("Listening...");
    notifyListeners();
    try {
      _webRecognition!.start();
    } catch (e) {
      print("VUI Web start error: $e");
      _isListening = false;
      _updateStatus("Error starting mic");
      notifyListeners();
    }
  }

  Future<void> _processVoiceInput(String input) async {
    if (_isProcessing) return;
    if (input.trim().isEmpty) { _updateStatus("Empty input"); return; }
    _isProcessing = true;

    const prompt = """You are an expense parser. Extract the following from the user's input: title (string), amount (number), paidBy (strictly 'Me' or 'Roommate'), and category (strictly one of: 'General', 'Utilities', 'Groceries', 'Internet', 'Food', 'Transport'). Return ONLY a valid JSON object. No markdown, no explanations. Example: {"title":"Electricity","amount":1500,"paidBy":"Me","category":"Utilities"}""";

    try {
      _updateStatus("Parsing with AI...");
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) throw Exception('GEMINI_API_KEY is empty');

      final data = await _callGeminiViaFetch(apiKey, prompt, input);

      final title        = data['title']    as String;
      final amount       = (data['amount']  as num).toDouble();
      final paidBy       = data['paidBy']   as String;
      final categoryName = data['category'] as String;
      final cat = cats.firstWhere(
        (c) => c.label == categoryName, orElse: () => cats[0]);
      _expenseState.add(title, amount, paidBy, cat);
      final who = paidBy == 'Me' ? 'you' : _expenseState.roommateName;
      await speak("Added ${amount.toStringAsFixed(0)} rupees for $title, paid by $who.");
      _lastWords = "";
      _updateStatus("Idle");
      notifyListeners();
    } catch (e) {
      _updateStatus("Error: ${e.toString()}");
      await speak("Sorry, I couldn't parse that.");
    } finally {
      _isProcessing = false;
    }
  }

  Future<Map<String, dynamic>> _callGeminiViaFetch(
      String apiKey, String prompt, String input) async {
    const model   = 'gemini-2.5-flash';
    final url     = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';
    final body    = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': '$prompt\nUser input: "$input"'}
          ]
        }
      ]
    });

    final headers = web.Headers();
    headers.append('Content-Type', 'application/json');

    final fetchResult = await web.window.fetch(
      url.toJS,
      web.RequestInit(
        method: 'POST',
        body: body.toJS,
        headers: headers,
      ),
    ).toDart;

    if (!fetchResult.ok) {
      final errTextJS = await fetchResult.text().toDart;
      throw Exception('Gemini HTTP ${fetchResult.status}');
    }

    final responseTextJS = await fetchResult.text().toDart;
    final responseJson = jsonDecode(responseTextJS.toDart) as Map<String, dynamic>;

    final candidates = responseJson['candidates'] as List?;
    final firstCandidate = candidates?.firstOrNull as Map<String, dynamic>?;
    final content = firstCandidate?['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    final firstPart = parts?.firstOrNull as Map<String, dynamic>?;
    final text = firstPart?['text'] as String?;

    if (text == null) throw Exception('No text in Gemini response');
    final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
    return jsonDecode(cleaned) as Map<String, dynamic>;
  }
}
