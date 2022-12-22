import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/common/showToast.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';

class ChatSettingPage extends StatefulWidget {
  const ChatSettingPage({Key? key}) : super(key: key);

  @override
  State<ChatSettingPage> createState() => _ChatSettingPageState();
}

class _ChatSettingPageState extends State<ChatSettingPage> {
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return Scaffold(
      appBar: buildAppBar('chat setting', context),
      body: ListView(
        children: [
          ListTile(
            onTap: () {
              showOkCancelAlertDialog(
                      context: context,
                      title: 'hint',
                      message: 'Are you sure to delete the chat history?')
                  .then((value) {
                if (value == OkCancelResult.ok) {
                  db
                      .collection(ChatsKey)
                      .doc(args['chatId'])
                      .update({args['messageListKey']: []}).then((value) {
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
