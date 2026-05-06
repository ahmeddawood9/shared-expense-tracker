# SharedSpace 🏠

**SharedSpace** is a modern, minimal Flutter application designed for roommates and partners to effortlessly track shared expenses. It combines a beautiful UI with an intelligent **Voice UI (VUI)** powered by Gemini AI, allowing you to log bills as naturally as you'd speak them.

##  Features

- ** AI Voice Logging**: Just say *"I paid 1200 for groceries"* and Gemini will parse the amount, category, and payer automatically.
- ** Live Balance Tracking**: Instantly see who owes whom and the current spending split.
- ** One-Tap Settlement**: Record settlement payments to clear the balance with a single tap.
- ** Smart Grouping**: Transactions are automatically grouped by date (Today, Yesterday, Earlier).
- ** Modern UI/UX**: Built with Material 3, Nunito typography, and smooth animations.
- ** Haptic Feedback**: Tactile responses for a premium app feel.
- ** Offline First**: Persistent local storage using SharedPreferences.
- ** Cross-Platform**: Supports Android, iOS, and Web (with experimental Speech Recognition).

##  Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- A Google Gemini API Key

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/shared-expense-tracker.git
   cd shared-expense-tracker
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Set up environment variables:
   Create a `.env` file in the root directory and add your API key:
   ```env
   GEMINI_API_KEY=your_api_key_here
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## 🛠 Tech Stack

- **Frontend**: Flutter
- **State Management**: Provider
- **AI**: Google Generative AI (Gemini 1.5 Flash)
- **Voice**: speech_to_text, flutter_tts
- **Storage**: SharedPreferences
- **Theming**: Google Fonts (Nunito)

##  Project Structure

- `lib/main.dart`: UI layer and app entry point.
- `lib/models.dart`: Data models, constants, and state management.
- `lib/voice_controller.dart`: Cross-platform voice service interface.
- `lib/voice_native.dart`: Native implementation of STT/TTS.
- `lib/voice_web.dart`: Web-specific implementation using Web Speech API.

##  Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

