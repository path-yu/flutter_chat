import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/common/showToast.dart';
import 'package:flutter_chat/common/upload_img.dart';
import 'package:flutter_chat/common/utils.dart';
import 'package:flutter_chat/components/build_base_image.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/components/hide_key_bord.dart';
import 'package:flutter_chat/eventBus/index.dart';
import 'package:flutter_chat/provider/current_user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_4.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic>? parentChatData;
  final double? initialScrollOffset;

  const ChatPage({super.key, this.parentChatData, this.initialScrollOffset});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List messageList = [];
  var chatId = '';
  var replyUid = '';
  String imgUrl = '';
  double offset = 0;
  bool showToBottomBtn = false;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.parentChatData == null) {
      return;
    }
    setState(() {
      messageList = widget.parentChatData!['messageList'];
      chatId = widget.parentChatData!['chatId'];
      replyUid = widget.parentChatData!['replyUid'];
    });
    eventBus.on<ChatsChangeEvent>().listen((data) {
      var index = data.value.indexWhere((element) => element['id'] == chatId);
      if (index != -1) {
        var target = data.value[index];
        setState(() {
          messageList = target['messageList'];
        });
      }
    });
    _scrollController.addListener(() {
      if (_scrollController.offset > offset && offset != 0) {
        if (!showToBottomBtn) {
          setState(() {
            showToBottomBtn = true;
          });
        }
      } else {
        setState(() {
          if (showToBottomBtn) {
            setState(() {
              showToBottomBtn = false;
            });
          }
        });
      }
      if (_scrollController.position.maxScrollExtent - offset <= 150) {
        setState(() {
          showToBottomBtn = false;
        });
      }
      offset = _scrollController.offset;
    });
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollController.jumpTo(widget.initialScrollOffset!));
  }

  @override
  void dispose() {
    SharedPreferences.getInstance().then((instance) {
      instance.setString(chatId, offset.toString());
    });
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  handSendClick() {
    if (_controller.text.isEmpty) {
      return showToast('not empty!');
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
    Future.delayed(const Duration(milliseconds: 150)).then((value) {
      scrollToBottom();
    });
  }

  void scrollToBottom() {
    if (_scrollController.hasClients) {
      final position = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(
        position,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return HideKeyboard(
      child: Scaffold(
        appBar: buildAppBar(widget.parentChatData!['appbarTitle'], context,
            actions: [
              buildIconButton(Icons.menu, () {
                Navigator.pushNamed(context, '/chatSetting', arguments: {
                  chatId: chatId,
                  'messageListKey': replyUid == getCurrentUser().uid
                      ? 'messages'
                      : 'targetMessages'
                });
              })
            ]),
        body: Stack(
          children: [
            Column(
              children: <Widget>[
                Expanded(
                    child: ListView.builder(
                  controller: _scrollController,
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
                                style: const TextStyle(color: Colors.black),
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
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                                  bubble,
                                  Padding(
                                    padding: EdgeInsets.only(
                                        top: ScreenUtil().setHeight(5),
                                        left: ScreenUtil().setWidth(10)),
                                    child: Text(item['showCreateTime'],
                                        style: TextStyle(
                                            color: Colors.black45,
                                            fontSize: ScreenUtil().setSp(12))),
                                  )
                                ],
                              ),
                            )
                          else
                            Transform.translate(
                              offset: const Offset(-5, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  bubble,
                                  Padding(
                                    padding: EdgeInsets.only(
                                        top: ScreenUtil().setHeight(5)),
                                    child: Text(item['showCreateTime'],
                                        style: TextStyle(
                                            color: Colors.black45,
                                            fontSize: ScreenUtil().setSp(12))),
                                  )
                                ],
                              ),
                            ),
                          if (isMyRequest)
                            buildBaseCircleImage(url: item['avatar'])
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
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          buildIconButton(Icons.image, () {
                            pickerImgAndUpload((url) {
                              imgUrl = url;
                            });
                          }, size: 20, iconColor: Colors.blue),

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
            Positioned(
                top: MediaQuery.of(context).size.height -
                    ScreenUtil().setWidth(160),
                left: MediaQuery.of(context).size.width -
                    ScreenUtil().setWidth(50),
                child: !showToBottomBtn
                    ? Container()
                    : SizedBox(
                        width: ScreenUtil().setWidth(30),
                        height: ScreenUtil().setHeight(30),
                        child: FloatingActionButton(
                            child: const Icon(Icons.keyboard_arrow_down),
                            onPressed: () {
                              //返回到顶部时执行动画
                              scrollToBottom();
                              setState(() {
                                showToBottomBtn = false;
                              });
                            }),
                      ))
          ],
        ),
      ),
    );
  }
}
