import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/common/showToast.dart';
import 'package:flutter_chat/common/utils.dart';
import 'package:flutter_chat/components/build_base_image.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/components/hide_key_bord.dart';
import 'package:flutter_chat/eventBus/index.dart';
import 'package:flutter_chat/provider/current_user.dart';

import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_4.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic>? parentChatData;
  const ChatPage({super.key, this.parentChatData});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List messageList = [];
  var chatId = '';
  var replyUid = '';
  final TextEditingController _controller = TextEditingController();
  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    if (widget.parentChatData == null) {
      return;
    }
    setState(() {
      messageList = widget.parentChatData!['messages'];
      chatId = widget.parentChatData!['chatId'];
      replyUid = widget.parentChatData!['replyUid'];
    });
    eventBus.on<ChatsChangeEvent>().listen((data) {
      // find chat
      var chatDataIndex =
          data.value.indexWhere((element) => element['id'] == chatId);
      var chatData = data.value[chatDataIndex];
      setState(() {
        messageList = chatData['messages'];
      });
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void handSendClick() {
    if (_controller.text.isEmpty) {
      showToast('not empty!');
    }
    var now = DateTime.now().millisecondsSinceEpoch;
    // add message
    var baseMessageData = {
      'content': _controller.text,
      'type': 'text',
      'uid': getCurrentUser().uid,
      'targetUid': replyUid,
      'createTime': now
    };
    var currentUser = context.read<CurrentUser>().value;
    var messageItem = {
      ...baseMessageData,
      'isMyRequest': true,
      'userName': currentUser['userName'],
      'avatar': currentUser['photoURL'],
      'showCreateTime': formatMessageDate(now)
    };
    setState(() {
      messageList.add(messageItem);
      _controller.text = '';
    });
    addMessage(chatId, baseMessageData);
  }

  @override
  Widget build(BuildContext context) {
    return HideKeyboard(
      child: Scaffold(
        appBar: buildAppBar('Chat page', context),
        body: Column(
          children: <Widget>[
            Expanded(
                child: ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                var item = messageList[index];
                var isMyRequest = item['isMyRequest'];
                var bubble = ChatBubble(
                  clipper: ChatBubbleClipper4(
                      type: isMyRequest
                          ? BubbleType.sendBubble
                          : BubbleType.receiverBubble),
                  backGroundColor: const Color(0xffE7E7ED),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    child: item['type'] == 'text'
                        ? Text(
                            item['content'],
                            style: TextStyle(color: Colors.black),
                          )
                        : buildBaseImage(url: item['content']),
                  ),
                );
                return Container(
                  padding: EdgeInsets.all(ScreenUtil().setWidth(10)),
                  child: Row(
                    mainAxisAlignment: isMyRequest
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!item['isMyRequest'])
                        ClipOval(
                          child: buildBaseCircleImage(url: item['avatar']),
                        ),
                      if (!item['isMyRequest'])
                        Transform.translate(
                          offset: const Offset(5, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                    left: ScreenUtil().setWidth(10)),
                                child: Text(
                                  item['userName'],
                                  style: TextStyle(color: Colors.black45),
                                ),
                              ),
                              bubble
                            ],
                          ),
                        )
                      else
                        Transform.translate(
                          offset: const Offset(-5, 0),
                          child: bubble,
                        ),
                      if (isMyRequest) buildBaseCircleImage(url: item['avatar'])
                    ],
                  ),
                );
              },
              itemCount: messageList.length,
            )),
            Container(
                padding: EdgeInsets.all(ScreenUtil().setWidth(5)),
                decoration: BoxDecoration(
                    border: Border(
                  top: BorderSide(
                      color: const Color(
                        0xFFDFDFDF,
                      ),
                      width: ScreenUtil().setWidth(1)),
                )),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  buildIconButton(Icons.image, () {},
                      size: 20, iconColor: Colors.blue),

                  // First child is enter comment text input
                  Expanded(
                    child: TextFormField(
                      autocorrect: false,
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'some message',
                        isDense: true,
                        contentPadding: EdgeInsets.all(10),
                        fillColor: Colors.white,
                        filled: true, // dont forget this line
                      ),
                    ),
                  ),
                  // Second child is button
                  buildIconButton(Icons.send, handSendClick,
                      size: 20, iconColor: Colors.blue),
                ])),
          ],
        ),
      ),
    );
  }
}
