import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/common/showToast.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';

class ChatSettingPage extends StatefulWidget {
  final String? chatId;
  final String? messageListKey;
  const ChatSettingPage({Key? key, this.chatId, this.messageListKey})
      : super(key: key);

  @override
  State<ChatSettingPage> createState() => _ChatSettingPageState();
}

class _ChatSettingPageState extends State<ChatSettingPage> {
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
                      message: 'Are you sure to delete the chat history?')
                  .then((value) {
                if (value == OkCancelResult.ok) {
                  db
                      .collection(ChatsKey)
                      .doc(widget.chatId!)
                      .update({widget.messageListKey!: []}).then((value) {
                    Navigator.pop(context);
                    showToast('success');
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
