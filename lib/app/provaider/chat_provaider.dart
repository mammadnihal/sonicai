import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonicai/app/class/chat_message_class.dart';
import 'package:sonicai/app/session/chat_session.dart';

class ChatProvider with ChangeNotifier {
  List<ChatSession> _chatSessions = [];
  late ChatSession _currentSession;
  String _displayedTitle = 'Yeni Söhbət';
  bool _isLoading = false;
  bool _isTyping = false;
  String _typedText = '';
  Timer? _typingTimer;

  List<ChatSession> get chatSessions => _chatSessions;
  ChatSession get currentSession => _currentSession;
  String get displayedTitle => _displayedTitle;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;
  String get typedText => _typedText;

  final String _azureEndpoint = "######";
  final String _azureApiKey = "######";
  final String _deploymentName = "gpt-4o";
  final String _apiVersion = "2025-01-01-preview";

  ChatProvider() {
    _loadChatSessions();
  }

  void _loadChatSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? sessionsJson = prefs.getString('chat_sessions');

    if (sessionsJson != null) {
      final List<dynamic> sessionsData = jsonDecode(sessionsJson);
      _chatSessions = sessionsData
          .map((session) => ChatSession.fromJson(session))
          .toList();
    }
    createNewChat(isInitial: true);
  }

  void _saveChatSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String sessionsJson = jsonEncode(
      _chatSessions.map((session) => session.toJson()).toList(),
    );
    await prefs.setString('chat_sessions', sessionsJson);
  }

  void createNewChat({bool isInitial = false}) {
    if (_chatSessions.isNotEmpty &&
        _chatSessions.first.messages.isEmpty &&
        !isInitial) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Söhbətə başlamaq üçün mesaj yazın')),
      // );
      return;
    }

    final newSession = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Yeni Söhbət',
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _chatSessions.insert(0, newSession);

    _currentSession = newSession;
    _displayedTitle = newSession.title;
    notifyListeners();

    _saveChatSessions();

    if (isInitial) {
      _sendInitialAIMessage();
    }
  }

  void _updateChatSession(ChatSession updatedSession) {
    final index = _chatSessions.indexWhere((s) => s.id == updatedSession.id);
    if (index != -1) {
      _chatSessions[index] = updatedSession;
      _chatSessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    _saveChatSessions();
    notifyListeners();
  }

  void switchChatSession(ChatSession session) {
    _currentSession = session;
    _displayedTitle = session.title;
    _isTyping = false;
    _typingTimer?.cancel();
    notifyListeners();
  }

  void _sendInitialAIMessage() {
    _startTypingAnimation(
      "Salam! Sizə necə kömək edə bilərəm?",
      isInitial: true,
    );
  }

  void sendMessage(String text) async {
    if (text.isEmpty || _isLoading || _isTyping) return;

    _currentSession.messages.add(
      ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
    );
    _currentSession.updatedAt = DateTime.now();
    _isLoading = true;
    notifyListeners();

    _updateChatSession(_currentSession);

    if (_currentSession.messages.length == 1 &&
        _currentSession.title == 'Yeni Söhbət') {
      await _generateChatTitle(text);
    }

    try {
      final response = await _getAzureResponse(text);
      _startTypingAnimation(response);
    } catch (e) {
      _startTypingAnimation("Xəta: ${e.toString()}");
    }
  }

  Future<String> _getAzureResponse(String prompt) async {
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
        "content":
            "Siz faydalı bir assistentsiniz. Azərbaycan dilində cavab verin.",
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
      throw Exception('Azure API xətası: ${response.statusCode}');
    }
  }

  Future<void> _generateChatTitle(String initialPrompt) async {
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
              "Bir söhbətin ilk mesajından qısa bir başlıq yaradın. Cavabınız sadəcə 2-5 sözdən ibarət olmalıdır. Azərbaycan dilində başlıq yaradın.",
        },
        {"role": "user", "content": initialPrompt},
      ],
      "max_tokens": 20,
      "temperature": 0.7,
    });
    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fullTitle = data['choices'][0]['message']['content'].trim();
        _startTitleAnimation(fullTitle);
      }
    } catch (e) {
      debugPrint("Başlıq yaratma xətası: $e");
    }
  }

  void _startTitleAnimation(String fullTitle) {
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
        _updateChatSession(_currentSession);
      }
    });
  }

  void _startTypingAnimation(String fullText, {bool isInitial = false}) {
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
        _updateChatSession(_currentSession);
        notifyListeners();
      }
    });
  }

  void addMessage(ChatMessage message) {
    _currentSession.messages.add(message);
    notifyListeners();
  }
}