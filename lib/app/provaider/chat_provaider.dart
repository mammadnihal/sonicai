import 'dart:async';
import 'dart:convert';
import 'package:sweetnotify/sweetnotify.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonicai/app/class/chat_message_class.dart';
import 'package:sonicai/app/session/chat_session.dart';

class ChatProvider with ChangeNotifier {
  // List of all chat sessions
  List<ChatSession> _chatSessions = [];

  // Current active chat session
  late ChatSession _currentSession;

  // Displayed chat title (animated)
  String _displayedTitle = 'New Chat';

  // Loading and typing indicators
  bool _isLoading = false;
  bool _isTyping = false;

  // Current AI-typed text (animated)
  String _typedText = '';

  // Timer for typing animations
  Timer? _typingTimer;

  // Public getters
  List<ChatSession> get chatSessions => _chatSessions;
  ChatSession get currentSession => _currentSession;
  String get displayedTitle => _displayedTitle;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;
  String get typedText => _typedText;

  // Azure OpenAI configuration
  final String _azureEndpoint = "######";
  final String _azureApiKey = "######";
  final String _deploymentName = "gpt-4o";
  final String _apiVersion = "2025-01-01-preview";

  // Constructor loads previous chat sessions
  ChatProvider(BuildContext context) {
    _loadChatSessions(context);
  }

  // Load chat sessions from local storage
  void _loadChatSessions(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? sessionsJson = prefs.getString('chat_sessions');

      if (sessionsJson != null) {
        final List<dynamic> sessionsData = jsonDecode(sessionsJson);
        _chatSessions = sessionsData
            .map((session) => ChatSession.fromJson(session))
            .toList();
      }

      // Create initial chat session
      // ignore: use_build_context_synchronously
      createNewChat(context, isInitial: true);
    } catch (e) {
      NotificationManager.show(
        // ignore: use_build_context_synchronously
        context, // Add the required BuildContext here
        title: "Error",
        subtitle: "Failed to load chat sessions: $e",
      );
    }
  }

  // Save chat sessions to local storage
  void _saveChatSessions(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String sessionsJson = jsonEncode(
        _chatSessions.map((session) => session.toJson()).toList(),
      );
      await prefs.setString('chat_sessions', sessionsJson);
    } catch (e) {
      NotificationManager.show(
        // ignore: use_build_context_synchronously
        context, // Add the required BuildContext here
        title: "Error",
        subtitle: "Failed to save chat sessions: $e",
      );
    }
  }

  // Create a new chat session
  void createNewChat(BuildContext context, {bool isInitial = false}) {
    // Prevent creating a new empty session if previous session has no messages
    if (_chatSessions.isNotEmpty &&
        _chatSessions.first.messages.isEmpty &&
        !isInitial) {
      return;
    }

    final newSession = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Chat',
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _chatSessions.insert(0, newSession);
    _currentSession = newSession;
    _displayedTitle = newSession.title;
    notifyListeners();

    _saveChatSessions(context);

    // Send a welcome message if this is the initial session
    if (isInitial) {
      _sendInitialAIMessage(context);
    }
  }

  // Update a session in the list and save it
  void _updateChatSession(BuildContext context, ChatSession updatedSession) {
    final index = _chatSessions.indexWhere((s) => s.id == updatedSession.id);
    if (index != -1) {
      _chatSessions[index] = updatedSession;
      // Sort sessions by last updated
      _chatSessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    _saveChatSessions(context);
    notifyListeners();
  }

  // Switch to another chat session
  void switchChatSession(ChatSession session) {
    _currentSession = session;
    _displayedTitle = session.title;
    _isTyping = false;
    _typingTimer?.cancel();
    notifyListeners();
  }

  // Send initial AI greeting
  void _sendInitialAIMessage(BuildContext context) {
    _startTypingAnimation(
      context,
      "Hello! How can I help you today?",
      isInitial: true,
    );
  }

  // Send a user message and request AI response
  void sendMessage(BuildContext context, String text) async {
    if (text.isEmpty || _isLoading || _isTyping) return;

    _currentSession.messages.add(
      ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
    );
    _currentSession.updatedAt = DateTime.now();
    _isLoading = true;
    notifyListeners();

    _updateChatSession(context, _currentSession);

    // Generate a chat title if first message
    if (_currentSession.messages.length == 1 &&
        _currentSession.title == 'New Chat') {
      await _generateChatTitle(context, text);
    }

    try {
      // ignore: use_build_context_synchronously
      final response = await _getAzureResponse(context, text);
      // ignore: use_build_context_synchronously
      _startTypingAnimation(context, response);
    } catch (e) {
      // ignore: use_build_context_synchronously
      _startTypingAnimation(context, "Error: ${e.toString()}");
      NotificationManager.show(
        // ignore: use_build_context_synchronously
        context, // Add the required BuildContext here
        title: "API Error",
        subtitle: "Failed to get AI response: $e",
      );
      /*
      SweetNotify.error(
        title: "API Error",
        message: "Failed to get AI response: $e",
      );*/
    }
  }

  // Call Azure OpenAI API
  Future<String> _getAzureResponse(BuildContext context, String prompt) async {
    try {
      final url = Uri.parse(
        '$_azureEndpoint/openai/deployments/$_deploymentName/chat/completions?api-version=$_apiVersion',
      );
      final headers = {
        'Content-Type': 'application/json',
        'api-key': _azureApiKey,
      };

      final List<Map<String, dynamic>> messages = [
        {
          "role": "system",
          "content": "You are a helpful assistant. Respond in Azerbaijani.",
        },
      ];

      for (var msg in _currentSession.messages) {
        messages.add({
          "role": msg.isUser ? "user" : "assistant",
          "content": msg.text,
        });
      }

      final body = jsonEncode({
        "messages": messages,
        "max_tokens": 800,
        "temperature": 0.7,
        "top_p": 0.95,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        NotificationManager.show(
          // ignore: use_build_context_synchronously
          context, // Add the required BuildContext here
          title: "API Error",
          subtitle: "Failed to get AI response: ${response.statusCode}",
        );
        throw Exception('Azure API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception("Network or API Error: $e");
    }
  }

  // Generate chat title from first user message
  Future<void> _generateChatTitle(
    BuildContext context,
    String initialPrompt,
  ) async {
    try {
      final url = Uri.parse(
        '$_azureEndpoint/openai/deployments/$_deploymentName/chat/completions?api-version=$_apiVersion',
      );
      final headers = {
        'Content-Type': 'application/json',
        'api-key': _azureApiKey,
      };
      final body = jsonEncode({
        "messages": [
          {
            "role": "system",
            "content":
                "Create a short title for a chat from the first user message. Respond in 2-5 words in Azerbaijani.",
          },
          {"role": "user", "content": initialPrompt},
        ],
        "max_tokens": 20,
        "temperature": 0.7,
      });

      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fullTitle = data['choices'][0]['message']['content'].trim();
        // ignore: use_build_context_synchronously
        _startTitleAnimation(context, fullTitle);
      } else {
        /*
        SweetNotify.error(
          title: "API Error",
          message: "Failed to generate chat title",
        );*/
      }
    } catch (e) {
      /*
      SweetNotify.error(
        title: "Error",
        message: "Failed to generate chat title: $e",
      );*/
    }
  }

  // Animate title display
  void _startTitleAnimation(BuildContext context, String fullTitle) {
    int index = 0;
    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (index < fullTitle.length) {
        _displayedTitle = fullTitle.substring(0, index + 1);
        index++;
        notifyListeners();
      } else {
        timer.cancel();
        _currentSession.title = fullTitle;
        _updateChatSession(context, _currentSession);
      }
    });
  }

  // Animate AI typing for messages
  void _startTypingAnimation(
    BuildContext context,
    String fullText, {
    bool isInitial = false,
  }) {
    _typingTimer?.cancel();
    _isLoading = false;
    _isTyping = true;
    _typedText = '';
    notifyListeners();

    int index = 0;
    _typingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (index < fullText.length) {
        _typedText += fullText[index];
        index++;
        notifyListeners();
      } else {
        timer.cancel();
        _isTyping = false;
        _currentSession.messages.add(
          ChatMessage(text: fullText, isUser: false, timestamp: DateTime.now()),
        );
        _currentSession.updatedAt = DateTime.now();
        _updateChatSession(context, _currentSession);
        notifyListeners();
      }
    });
  }

  // Add a message manually to current session
  void addMessage(ChatMessage message) {
    _currentSession.messages.add(message);
    notifyListeners();
  }
}
