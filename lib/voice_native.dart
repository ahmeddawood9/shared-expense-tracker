import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'models.dart';

class VoiceController extends ChangeNotifier {
  final ExpenseState _expenseState;

  // ── Native-only ───────────────────────────────────────────
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechInitialised = false;

  // ── Shared ────────────────────────────────────────────────
  late final GenerativeModel _model;
  bool _isListening = false;
  bool get isListening => _isListening;
  String _status = "Idle";
  String get status => _status;
  String _lastWords = "";
  String get lastWords => _lastWords;
  bool _isProcessing = false;

  VoiceController(this._expenseState) {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
  }

  Future<void> init() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
  }

  void _updateStatus(String s) { _status = s; notifyListeners(); }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> listen() async {
    _updateStatus("Initializing...");
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      _updateStatus("Stopped");
      return;
    }
    try {
      bool available;
      if (_speechInitialised) {
        available = true;
      } else {
        available = await _speech.initialize(
          onStatus: (s) {
            _updateStatus(s == 'listening' ? "Listening..." : s);
            if (s == 'done' || s == 'notListening' || s == 'doneNoResult') {
              if (_isListening && _lastWords.isNotEmpty) _processVoiceInput(_lastWords);
              _isListening = false;
              notifyListeners();
            }
          },
          onError: (e) {
            _updateStatus("Error: ${e.errorMsg}");
            _isListening = false;
            notifyListeners();
          },
        );
        if (available) _speechInitialised = true;
      }
      if (available) {
        _isListening = true;
        _lastWords   = "";
        _updateStatus("Listening...");
        notifyListeners();
        await _speech.listen(
          onResult: (result) {
            _lastWords = result.recognizedWords;
            _updateStatus("Heard: $_lastWords");
            if (result.finalResult) {
              _isListening = false;
              _updateStatus("Processing...");
              _processVoiceInput(_lastWords);
              notifyListeners();
            }
          },
          listenMode: stt.ListenMode.dictation,
          localeId: 'en_US',
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 4),
          cancelOnError: false,
        );
      } else {
        _updateStatus("Mic Unavailable");
        await speak("Please allow microphone access.");
      }
    } catch (e) {
      _updateStatus("Exception: $e");
      _isListening = false;
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

      final response = await _model.generateContent([
        Content.text("$prompt\nUser input: \"$input\""),
      ]);
      final jsonString = response.text
          ?.replaceAll('```json', '').replaceAll('```', '').trim();
      if (jsonString == null) throw Exception('Empty response from Gemini');
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

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
}
