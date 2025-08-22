import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sonicai/app/provaider/chat_provaider.dart';
import 'package:sonicai/view/main_chat_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ChatProvider(context),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Azure AI Chat',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF0EFEA),
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MainChatScreen(),
    );
  }
}
