# SharedSpace - Project Understanding 🏠

This document provides a technical overview of the **SharedSpace** (shared-expense-tracker) project to help AI and developers understand the codebase and architectural decisions.

## 🚀 Project Overview
SharedSpace is a Flutter-based mobile application designed for roommates and partners to track shared expenses. It features a modern, minimal UI and a unique Voice UI (VUI) for natural language expense logging.

## 🛠 Tech Stack
- **Framework:** Flutter (Targeting Android, iOS, Web, Desktop)
- **State Management:** `provider` (ChangeNotifier)
- **AI Integration:** `google_generative_ai` (Gemini 1.5 Flash) for parsing voice input.
- **Voice Services:** `speech_to_text` (STT) and `flutter_tts` (TTS).
- **Persistence:** `shared_preferences` (Local JSON storage).
- **Configuration:** `flutter_dotenv` (for API keys).

## 📂 Project Structure
Currently, the project is largely centralized in `lib/main.dart` for simplicity, despite the README suggesting a modular structure. 

### Core Components (in `lib/main.dart`):
1.  **Palette (`class C`)**: Centralized color constants (Mango, Sage, Rose, Cream, etc.).
2.  **Categories (`class Cat`)**: Defines the six core categories: General, Utilities, Groceries, Internet, Food, and Transport.
3.  **Model (`class Expense`)**: The primary data structure. Includes `toMap`/`fromMap` for JSON persistence.
4.  **State Management (`class ExpenseState`)**:
    - Manages a list of expenses.
    - Calculates totals, splits (default 50/50), and balances.
    - Handles persistence via `SharedPreferences`.
    - Supports "Settle Up" functionality which adds a settlement transaction.
5.  **Voice UI Service (`class VoiceController`)**:
    - Initializes Speech-to-Text and Text-to-Speech.
    - Sends raw captured text to Gemini with a structured prompt to extract `title`, `amount`, `paidBy`, and `category`.
    - Updates `ExpenseState` directly upon successful parsing.
6.  **UI (`DashboardScreen` and Widgets)**:
    - **Header**: Shows house name and user avatars (supports renaming).
    - **Balance Card**: Shows who owes whom and the "Settle Up" button.
    - **Split Card**: Visual representation of the payment ratio.
    - **Transaction List**: Grouped by date (Today, Yesterday, Earlier) with swipe-to-delete.
    - **Add/Voice FABs**: Floating buttons for manual or voice entry.

## 🤖 Voice UI Workflow
1. User taps the Mic FAB.
2. `VoiceController` listens for speech.
3. Captured text is sent to Gemini 1.5 Flash.
4. Gemini returns a JSON object (e.g., `{"title": "Milk", "amount": 50, "paidBy": "Me", "category": "Groceries"}`).
5. The expense is automatically added, and the app "speaks" a confirmation.

## ⚠️ Important Notes
- **API Keys**: The app requires a `GEMINI_API_KEY` in a `.env` file at the root.
- **Single File**: Most logic is in `lib/main.dart`. As the project grows, these should be split into:
    - `lib/core/constants.dart`
    - `lib/models/expense.dart`
    - `lib/providers/expense_provider.dart`
    - `lib/services/voice_service.dart`
    - `lib/screens/` and `lib/widgets/`
- **Default Split**: The current logic assumes a two-person split (50/50).

## 🛠 Development Guidelines
- Use **Material 3** components.
- Adhere to the **Nunito** font family.
- Use `HapticFeedback` for interactive elements.
- When adding features, ensure they are compatible with both manual entry and the Voice UI parsing logic.
