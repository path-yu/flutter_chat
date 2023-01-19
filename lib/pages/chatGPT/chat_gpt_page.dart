import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/common/utils.dart';
import 'package:flutter_chat/components/build_base_image.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/components/hide_key_bord.dart';
import 'package:flutter_chat/pages/chatGPT/chat_gpt_setting_page.dart';
import 'package:flutter_chat/pages/chat_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatGPTPage extends StatefulWidget {
  const ChatGPTPage({super.key});

  @override
  State<ChatGPTPage> createState() => _ChatGPTPageState();
}

class _ChatGPTPageState extends State<ChatGPTPage> {
  bool showSendBtn = true;
  String message = '';
  List messageList = [];
  var apiKey = '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';
  String? chatId;
  bool sendLoading = false;
  final TextEditingController _editingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isLoading = false;
  bool hasScrollBottom = false;
  bool showToBottomBtn = false;
  MoveDirection? moveDirection;
  double scrollMove = 0;
  double startMoveOffset = 0;
  double offset = 0;

  void _getMessageData() async {
    setState(() {
      isLoading = true;
    });
    var currentUser = getCurrentUser();
    var result = await db
        .collection(chatGPTDbKey)
        .where('uid', isEqualTo: currentUser.uid)
        .get();
    if (result.size != 0) {
      chatId = result.docs[0].id;
      setState(() {
        isLoading = false;
        messageList = result.docs[0].data()['messages'];
      });
    } else {
      var addData = await db.collection('chat_gpt_messages').add({
        'uid': currentUser.uid,
        'messages': [],
        'createTime': DateTime.now().millisecondsSinceEpoch,
        'updateTime': DateTime.now().millisecondsSinceEpoch,
      });
      chatId = addData.id;
      setState(() {
        isLoading = false;
        messageList = [];
      });
    }
    Future.delayed(const Duration(milliseconds: 300)).then((value) async {
      if (messageList.isNotEmpty) {
        _scrollController.jumpTo(await getScrollOffset());
      }
    });
  }

  void scrollToBottom() {
    if (_scrollController.hasClients && messageList.isNotEmpty) {
      final position = _scrollController.position.maxScrollExtent;
      Future.delayed(const Duration(milliseconds: 150)).then((value) {
        _scrollController.jumpTo(
          position,
        );
      });
    }
  }

  Future<Response<dynamic>> requestApi(String prompt) async {
    var response = await Dio().post('https://api.openai.com/v1/completions',
        data: {
          'model': 'text-davinci-003',
          'prompt': prompt,
          "temperature": 0,
          "max_tokens": 300,
          "top_p": 1,
          "frequency_penalty": 0.0,
          "presence_penalty": 0.0,
        },
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}));
    return response;
  }

  void handSendClick() async {
    var prompt = message.toString();
    List data = [
      {
        'type': 'question',
        'content': message,
        'createTime': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'type': 'answer',
        'content': '',
        'status': 0, // 0 pending 1 success 2 error
        'createTime': DateTime.now().millisecondsSinceEpoch,
      }
    ];
    setState(() {
      messageList.addAll(data);
      message = '';
      _editingController.text = '';
      sendLoading = true;
    });
    try {
      var response = await requestApi(prompt);
      _editingController.text = '';
      String answer = response.data['choices'][0]['text'];
      data[1]['content'] = answer.trim();
      data[1]['status'] = 1;
      db.collection(chatGPTDbKey).doc(chatId).update({
        'updateTime': DateTime.now().millisecondsSinceEpoch,
        'messages': FieldValue.arrayUnion(data)
      });
      setState(() {
        messageList.last['content'] = answer.trim();
        messageList.last['status'] = 1;
        sendLoading = false;
        hasScrollBottom = true;
      });
    } catch (e) {
      setState(() {
        messageList.last['content'] = '';
        messageList.last['status'] = 2;
        sendLoading = false;
        hasScrollBottom = true;
      });
    }
  }

  void handleBuildScrollToBottom(context) {
    var keyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;
    if (keyboardVisible && messageList.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 150)).then((value) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }
    if (hasScrollBottom && messageList.isNotEmpty) {
      scrollToBottom();
      hasScrollBottom = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _editingController.text = message;
    _getMessageData();

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
  }

  getScrollOffset() async {
    var instance = await SharedPreferences.getInstance();
    return instance.getDouble(chatId!) ?? 0.0;
  }

  @override
  void dispose() {
    super.dispose();
    _editingController.dispose();
    _scrollController.dispose();

    if (chatId != null) {
      SharedPreferences.getInstance().then((instance) {
        instance.setDouble(chatId!, offset);
      });
    }
  }

  void handleRefreshPress(int index) async {
    var targetMessage = messageList[index - 1];
    var data = messageList.sublist(index - 1, index + 1);
    setState(() {
      messageList[index]['status'] = 0;
    });
    try {
      var response = await requestApi(targetMessage['content']);
      _editingController.text = '';
      String answer = response.data['choices'][0]['text'];
      data[1]['content'] = answer.trim();
      data[1]['status'] = 1;
      db.collection(chatGPTDbKey).doc(chatId).update({
        'updateTime': DateTime.now().millisecondsSinceEpoch,
        'messages': FieldValue.arrayUnion(data)
      });
      setState(() {
        messageList.last['content'] = answer.trim();
        messageList.last['status'] = 1;
        sendLoading = false;
        hasScrollBottom = true;
      });
    } catch (e) {
      setState(() {
        messageList.last['content'] = '';
        messageList.last['status'] = 2;
        sendLoading = false;
        hasScrollBottom = true;
      });
    }
  }

  var spin = Opacity(
    opacity: 0.6,
    child: Text(
      'loading...',
      style: TextStyle(
          fontWeight: FontWeight.normal, fontSize: ScreenUtil().setSp(14)),
    ),
  );
  @override
  Widget build(BuildContext context) {
    handleBuildScrollToBottom(context);
    return HideKeyboard(
      child: SelectionArea(
        child: Scaffold(
            appBar: buildAppBar('ChatGPT', context, actions: [
              buildIconButton(Icons.menu, () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatGPTSettingPage(
                        chatId: chatId,
                      ),
                    )).then((value) {
                  if (value != null) {
                    if (value['removeAllChat']) {
                      setState(() {
                        messageList = [];
                        offset = 0;
                      });
                    }
                  }
                });
              })
            ]),
            body: isLoading
                ? baseLoading
                : Column(
                    children: [
                      Expanded(
                        child: messageList.isEmpty
                            ? buildBaseEmptyWidget('No data')
                            : ListView.separated(
                                controller: _scrollController,
                                separatorBuilder: (context, index) {
                                  return const Divider();
                                },
                                itemBuilder: (context, index) {
                                  var item = messageList[index];
                                  var isQuestion = item['type'] == 'question';
                                  var ele = SelectableText(
                                    item['content'],
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: ScreenUtil().setSp(12)),
                                  );
                                  var resultEle = ListTile(
                                    leading: isQuestion
                                        ? ClipOval(
                                            child: buildBaseImage(
                                                width:
                                                    ScreenUtil().setWidth(40),
                                                height:
                                                    ScreenUtil().setHeight(40),
                                                url:
                                                    getCurrentUser().photoURL!),
                                          )
                                        : ClipOval(
                                            child: Container(
                                              color: const Color.fromRGBO(
                                                  16, 163, 127, 1),
                                              width: ScreenUtil().setWidth(40),
                                              height:
                                                  ScreenUtil().setHeight(40),
                                              child: Center(
                                                child: SvgPicture.asset(
                                                  'assets/chat_gpt.svg',
                                                  width:
                                                      ScreenUtil().setWidth(20),
                                                  height:
                                                      ScreenUtil().setWidth(20),
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                    title: isQuestion
                                        ? ele
                                        : item['status'] == 0
                                            ? spin
                                            : item['status'] == 2
                                                ? const Text(
                                                    'An error occurred, you can wait and try',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        color: Colors.red),
                                                  )
                                                : ele,
                                    subtitle: Text(
                                      formatMessageDate(item['createTime']),
                                      style: TextStyle(
                                          fontSize: ScreenUtil().setSp(10)),
                                    ),
                                  );
                                  return item['status'] == 2
                                      ? Column(
                                          children: [
                                            resultEle,
                                            SizedBox(
                                              height: ScreenUtil().setWidth(25),
                                              child: ElevatedButton(
                                                  onPressed: () =>
                                                      handleRefreshPress(index),
                                                  child: Text(
                                                    'Refresh',
                                                    style: TextStyle(
                                                        fontSize: ScreenUtil()
                                                            .setSp(10)),
                                                  )),
                                            ),
                                          ],
                                        )
                                      : resultEle;
                                },
                                itemCount: messageList.length,
                              ),
                      ),
                      Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          TextField(
                            controller: _editingController,
                            maxLines: 6,
                            minLines: 1,
                            onChanged: (value) {
                              setState(() {
                                message = value;
                              });
                            },
                            decoration: const InputDecoration(
                              hintText: 'Your question',
                              border: InputBorder.none,
                              isDense: true,

                              filled: true, // dont forget this line
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showToBottomBtn)
                                GestureDetector(
                                    child: Container(
                                      margin: EdgeInsets.only(
                                          right: ScreenUtil().setWidth(10)),
                                      child: const Icon(
                                        Icons.keyboard_arrow_down_sharp,
                                        size: 20,
                                      ),
                                    ),
                                    onTap: () {
                                      //返回到顶部时执行动画
                                      scrollToBottom();
                                      setState(() {
                                        showToBottomBtn = false;
                                      });
                                    }),
                              if (message.isNotEmpty)
                                GestureDetector(
                                  onTap: handSendClick,
                                  child: const Padding(
                                    padding: EdgeInsets.all(5),
                                    child: Icon(
                                      Icons.send,
                                      size: 20,
                                    ),
                                  ),
                                )
                            ],
                          ),
                        ],
                      )
                    ],
                  )),
      ),
    );
  }
}
