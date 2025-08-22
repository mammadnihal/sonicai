<img src="https://raw.githubusercontent.com/mammadnihal/sonicai/refs/heads/main/assets/sonicai.gif" alt="Chat Screen" width="50"/>
sonicAI - Flutter AI Chat App </br>
<img src="https://raw.githubusercontent.com/mammadnihal/sonicai/refs/heads/main/assets/chat_screen.png" alt="Chat Screen" width="300"/>
<img src="ttps://raw.githubusercontent.com/mammadnihal/sonicai/refs/heads/main/assets/drawler.png" alt="Drawler Menu" width="300"/>

This is a powerful AI chat application built with Flutter, featuring a user-friendly interface. The app uses local storage to save chat sessions and integrates with Azure OpenAI services.

Features

Modern UI/UX Design: Sleek and intuitive user interface.

Side Menu: Easily create new chats and access previous conversations.

Live Typing Animation: Shows AI typing animation to enhance user experience.

Chat Session Management: Automatically manages chat sessions to save conversation history.

Provider Package Usage: Efficient state management using the Provider package.

Local Storage: Saves chats on the device using shared_preferences.

Visual Preview

(Insert screenshots or GIFs of the app here)

Getting Started

Follow these steps to run the project locally.

Prerequisites

Flutter SDK

Android Studio or VS Code

Access to Azure OpenAI services and an API key

Installation

Clone the repository:

```yaml
git clone https://github.com/mammadnihal/sonicai.git
cd sonicai
```

Install the required packages:
```yaml
flutter pub get
```

Open lib/main.dart and configure your Azure API settings:

```dart
// Provider class
class ChatProvider with ChangeNotifier {
    ...
    final String _azureEndpoint = "YOUR AZURE ENDPOINT";
    final String _azureApiKey = "YOUR AZURE API KEY";
    ...
}
```

Run the app:
```yaml
flutter run
```

Contact
If you have any questions or suggestions about this project, you can email me at:
nihalmammad@gmail.com