import 'dart:async';
import 'dart:io';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/common/showToast.dart';
import 'package:flutter_chat/common/upload.dart';
import 'package:flutter_chat/common/utils.dart';
import 'package:flutter_chat/components/build_base_image.dart';
import 'package:flutter_chat/components/build_scale_animated_switcher.dart';
import 'package:flutter_chat/components/color.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/components/fade_indexed_stack.dart';
import 'package:flutter_chat/components/hide_key_bord.dart';
import 'package:flutter_chat/eventBus/index.dart';
import 'package:flutter_chat/pages/chat_setting_page.dart';
import 'package:flutter_chat/pages/photo_view.dart';
import 'package:flutter_chat/provider/current_brightness.dart';
import 'package:flutter_chat/provider/current_user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_4.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:record/record.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic>? parentChatData;
  final double? initialScrollOffset;

  const ChatPage({super.key, this.parentChatData, this.initialScrollOffset});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

enum MoveDirection { down, up }

class _ChatPageState extends State<ChatPage> {
  List messageList = [];
  var chatId = '';
  var replyUid = '';
  bool isMyRequest = false;
  String imgUrl = '';
  double offset = 0;
  bool showToBottomBtn = false;
  bool showSendBtn = false;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  double scrollMove = 0;
  double startMoveOffset = 0;
  MoveDirection? moveDirection;
  bool hasLongPres = false;
  int indexedStackIndex = 0;
  String recordingTime = '';
  Timer? recordTimer;
  int maxSeconds = 120;
  bool stopRecording = false;
  bool isRecordEnd = false;
  Record? record;
  List<String> get pics => messageList
      .where((element) => element['type'] == 'pic')
      .toList()
      .map((e) => e['content'] as String)
      .toList();

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
      isMyRequest = widget.parentChatData!['isMyRequest'];
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
      var moveDiff = _scrollController.offset - offset;
      if (moveDiff > 0 && offset != 0) {
        moveDirection = MoveDirection.down;
      }
      if (moveDiff < 0 && offset != 0) {
        moveDirection = MoveDirection.up;
      }
      if (startMoveOffset == 0) {
        startMoveOffset = _scrollController.offset;
      } else {
        moveDiff = _scrollController.offset - startMoveOffset;
        if (moveDirection == MoveDirection.down) {
          if (!showToBottomBtn && moveDiff > 100) {
            setState(() => showToBottomBtn = true);
          }
        } else {
          if (showToBottomBtn) {
            setState(() => showToBottomBtn = false);
          }
        }
      }
      offset = _scrollController.offset;
      if (offset == _scrollController.position.maxScrollExtent &&
          showToBottomBtn) {
        setState(() => showToBottomBtn = false);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollController.jumpTo(widget.initialScrollOffset!));
    initListenerMessage();
  }

  void initListenerMessage() {
    _controller.addListener(() {
      setState(() {
        if (_controller.text.contains('\n')) {
          showSendBtn = true;
        } else {
          showSendBtn = _controller.text.trim().isNotEmpty;
        }
      });
    });
  }

  @override
  void dispose() {
    SharedPreferences.getInstance().then((instance) {
      instance.setString(chatId, offset.toString());
    });
    _scrollController.dispose();
    _controller.dispose();
    clearTimer();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  handSendClick() {
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

  void addImgMessage(List<String> urlList) {
    var now = DateTime.now().millisecondsSinceEpoch;
    var baseMessageData = urlList.map((url) {
      return {
        'content': url,
        'type': 'pic',
        'uid': getCurrentUser().uid,
        'targetUid': replyUid,
        'createTime': now
      };
    }).toList();
    var currentUser = context.read<CurrentUser>().value;
    var messages = baseMessageData.map((data) {
      return {
        ...data,
        'isMyRequest': true,
        'userName': currentUser['userName'],
        'avatar': currentUser['photoURL'],
        'showCreateTime': formatMessageDate(now)
      };
    }).toList();
    setState(() {
      messageList = [...messageList, ...messages];
    });
    addMultipleMessage(chatId, baseMessageData);
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

  void closeRecording() {
    setState(() {
      indexedStackIndex = 0;
    });
    clearTimer();
  }

  void clearTimer() {
    recordTimer?.cancel();
    record?.dispose();
  }

  void startRecording() async {
    int startSeconds = 0;
    setState(() {
      recordingTime = '0:0';
      stopRecording = false;
      isRecordEnd = false;
    });
    record = Record();
    // Check and request permission
    if (await record!.hasPermission()) {
      // Start recording
      await record!.start();
    }
    recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (stopRecording) {
        return;
      }
      startSeconds++;
      if (startSeconds >= maxSeconds) {
        showToast('Maximum recording time exceeded');
        isRecordEnd = true;
        clearTimer();
      }
      var time = Duration(seconds: startSeconds);
      var timeM = (time.inMinutes % 60).toInt();
      var timeS = time.inSeconds - (timeM * 60);
      setState(() {
        recordingTime = '$timeM:$timeS';
      });
    });
    setState(() {
      indexedStackIndex = 1;
    });
  }

  void handSendVoiceClick() async {
    closeRecording();
    var path = await record?.stop();
    if (path != null) {
      File file = File(path);
      // Todo
      var url = await uploadFile(file);
      print(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    var fillColor = context.watch<CurrentBrightness>().isDarkMode
        ? darkMainColor
        : Colors.white;
    return HideKeyboard(
      child: Scaffold(
        appBar: buildAppBar(widget.parentChatData!['appbarTitle'], context,
            actions: [
              buildIconButton(Icons.menu, () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatSettingPage(
                          chatId: chatId,
                          messageListKey:
                              isMyRequest ? 'messages' : 'targetMessages'),
                    ));
              })
            ]),
        body: Listener(
          onPointerUp: (event) {
            startMoveOffset = 0;
          },
          child: Stack(
            children: [
              Column(
                children: <Widget>[
                  Expanded(
                      child: ListView.builder(
                    controller: _scrollController,
                    itemBuilder: (BuildContext context, int index) {
                      var item = messageList[index];
                      var isMyRequest = item['isMyRequest'];
                      StatelessWidget bubble;
                      if (item['type'] == 'pic') {
                        bubble = GestureDetector(
                          onTap: () {
                            var index = pics.indexOf(item['content']);
                            //打开B路由
                            Navigator.push(context, MaterialPageRoute(
                              builder: (
                                BuildContext context,
                              ) {
                                return PhotoView(
                                  pics: pics,
                                  showIndex: index,
                                );
                              },
                            ));
                          },
                          child: Hero(
                              tag: item['content'],
                              child: Container(
                                constraints: BoxConstraints(
                                    maxWidth: screenWidth * 0.6,
                                    maxHeight: screenHeight * 0.4),
                                child: ExtendedImage.network(
                                  item['content'],
                                  fit: BoxFit.contain,
                                  mode: ExtendedImageMode.gesture,
                                  cache: true,
                                ),
                              )),
                        );
                      } else {
                        bubble = ChatBubble(
                          backGroundColor:
                              isMyRequest ? Colors.blueAccent : Colors.blue,
                          shadowColor:
                              context.watch<CurrentBrightness>().isDarkMode
                                  ? darkMainColor
                                  : Colors.grey,
                          clipper: ChatBubbleClipper4(
                              type: isMyRequest
                                  ? BubbleType.sendBubble
                                  : BubbleType.receiverBubble),
                          child: Container(
                              constraints: BoxConstraints(
                                maxWidth: screenWidth * 0.7,
                              ),
                              child: SelectableText(
                                item['content'],
                                style: const TextStyle(color: Colors.white),
                              )),
                        );
                      }
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
                                child:
                                    buildBaseCircleImage(url: item['avatar']),
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
                                      child: Opacity(
                                        opacity: 0.5,
                                        child: Text(item['showCreateTime'],
                                            style: TextStyle(
                                                fontSize:
                                                    ScreenUtil().setSp(12))),
                                      ),
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
                                      child: Opacity(
                                        opacity: 0.5,
                                        child: Text(item['showCreateTime'],
                                            style: TextStyle(
                                                fontSize:
                                                    ScreenUtil().setSp(12))),
                                      ),
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
                  const Divider(
                    height: 1,
                  ),
                  FadeIndexedStack(
                    index: indexedStackIndex,
                    duration: const Duration(milliseconds: 300),
                    children: [
                      Container(
                          color: fillColor,
                          height: ScreenUtil().setHeight(55),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                buildSpace(ScreenUtil().setWidth(10)),
                                Transform.translate(
                                  offset: const Offset(0, -2),
                                  child: GestureDetector(
                                    onTap: () async {
                                      final List<AssetEntity>? result =
                                          await AssetPicker.pickAssets(
                                        context,
                                        pickerConfig: const AssetPickerConfig(
                                            maxAssets: 3,
                                            themeColor: primaryColor),
                                      );
                                      if (result != null) {
                                        var urlList =
                                            await uploadAssetsImage(result);
                                        addImgMessage(urlList);
                                      }
                                    },
                                    child: const Icon(
                                      Icons.image,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    keyboardType: TextInputType.multiline,
                                    minLines:
                                        1, //Normal textInputField will be displayed
                                    maxLines:
                                        5, // when user presses enter it will adapt to it
                                    textInputAction: TextInputAction.newline,
                                    decoration: InputDecoration(
                                      hintText: 'some message',
                                      border: InputBorder.none,
                                      suffixIcon: showSendBtn
                                          ? buildIconButton(
                                              Icons.send, handSendClick,
                                              size: 20, iconColor: Colors.blue)
                                          : const SizedBox(),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.all(8),
                                      fillColor: fillColor,
                                      filled: true, // dont forget this line
                                    ),
                                  ),
                                ),
                                Transform.translate(
                                  offset: const Offset(0, -2),
                                  child: !showSendBtn
                                      ? GestureDetector(
                                          onTap: () {
                                            startRecording();
                                          },
                                          child: const Icon(
                                            Icons.mic,
                                          ),
                                        )
                                      : Container(),
                                ),
                                buildSpace(ScreenUtil().setWidth(10)),
                                // Second child is button
                              ])),
                      Container(
                        color: fillColor,
                        height: ScreenUtil().setHeight(55),
                        padding: const EdgeInsets.fromLTRB(10, 10, 2, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                buildScaleAnimatedSwitcher(Icon(
                                  stopRecording ? Icons.mic_off : Icons.mic,
                                  key: ValueKey(stopRecording),
                                )),
                                buildSpace(ScreenUtil().setWidth(10)),
                                Text(recordingTime,
                                    style: TextStyle(
                                        fontSize: ScreenUtil().setSp(16))),
                              ],
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: isRecordEnd
                                      ? null
                                      : () {
                                          setState(() {
                                            stopRecording = !stopRecording;
                                          });
                                          stopRecording
                                              ? record?.pause()
                                              : record?.resume();
                                        },
                                  child: Text(stopRecording ? 'Start' : 'Stop'),
                                ),
                                TextButton(
                                  onPressed: closeRecording,
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: handSendVoiceClick,
                                  child: const Text('Send'),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
              Positioned(
                  bottom: ScreenUtil().setHeight(30),
                  right: ScreenUtil().setWidth(20),
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
      ),
    );
  }
}
