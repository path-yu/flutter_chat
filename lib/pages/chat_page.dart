import 'package:flutter/material.dart';
import 'package:flutter_chat/components/common.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Text('chat page'),
      appBar: buildAppBar('Chat page', context),
    );
  }
}
