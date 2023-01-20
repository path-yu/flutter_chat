import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_chat/provider/current_chat_gpt_setting.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

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
            onLongPress: () {},
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
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Chat GPT mode'),
            subtitle: Text(
              context.watch<CurrentChatGPTSetting>().modelLabel,
              style: TextStyle(fontSize: ScreenUtil().setSp(10)),
            ),
            onTap: () async {
              var result = await showConfirmationDialog(
                  barrierDismissible: false,
                  fullyCapitalizedForMaterial: false,
                  title: 'Select mode ',
                  context: context,
                  cancelLabel: 'Cancel',
                  okLabel: 'Ok',
                  initialSelectedActionKey:
                      context.read<CurrentChatGPTSetting>().model,
                  actions: [
                    const AlertDialogAction(
                      label: 'QA',
                      key: 0,
                    ),
                    const AlertDialogAction(
                      label: 'Image create',
                      key: 1,
                    ),
                  ]);
              context.read<CurrentChatGPTSetting>().changeMode(result!);
            },
          )
        ],
      ),
    );
  }
}
