import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';

class ChatGPTSettingPage extends StatefulWidget {
  final String? chatId;
  final String? messageListKey;
  const ChatGPTSettingPage({Key? key, this.chatId, this.messageListKey})
      : super(key: key);

  @override
  State<ChatGPTSettingPage> createState() => _ChatGPTSettingPageState();
}

class _ChatGPTSettingPageState extends State<ChatGPTSettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('chat setting', context),
      body: ListView(
        children: [
          ListTile(
            onTap: () {
              showOkCancelAlertDialog(
                      fullyCapitalizedForMaterial: false,
                      context: context,
                      title: 'hint',
                      cancelLabel: 'Cancel',
                      okLabel: 'Confirm',
                      message: 'Are you sure to delete the chat history?')
                  .then((value) {
                if (value == OkCancelResult.ok) {
                  db
                      .collection(chatGPTDbKey)
                      .doc(widget.chatId!)
                      .update({'messages': []}).then((value) {
                    Navigator.pop(context, {'removeAllChat': true});
                  });
                }
              });
            },
            leading: const Icon(Icons.delete_outline_outlined),
            title: const Text('delete chat history'),
          )
        ],
      ),
    );
  }
}
