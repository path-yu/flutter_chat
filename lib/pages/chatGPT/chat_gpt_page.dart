import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/common/showToast.dart';
import 'package:flutter_chat/common/utils.dart';
import 'package:flutter_chat/components/build_base_image.dart';
import 'package:flutter_chat/components/build_scale_animated_switcher.dart';
import 'package:flutter_chat/components/code_element_build.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/components/hide_key_bord.dart';
import 'package:flutter_chat/pages/chatGPT/chat_gpt_setting_page.dart';
import 'package:flutter_chat/pages/chat/chat_page.dart';
import 'package:flutter_chat/pages/photo_view.dart';
import 'package:flutter_chat/provider/current_chat_gpt_setting.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatGPTPage extends StatefulWidget {
  const ChatGPTPage({super.key});

  @override
  State<ChatGPTPage> createState() => _ChatGPTPageState();
}

class _ChatGPTPageState extends State<ChatGPTPage>
    with TickerProviderStateMixin {
  bool showSendBtn = true;
  String message = '';
  List messageList = [];
  var apiKey = '';
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

  // longPress
  bool hasLongPress = false;
  List<Map> selectedList = [];

  List<String> get pics => messageList
      .where((element) => element['contentType'] == 'image')
      .toList()
      .map((e) => e['content'] as String)
      .toList();
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
    setupRemoteConfig();
  }

  setupRemoteConfig() async {
    var remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.fetchAndActivate();
    apiKey = remoteConfig.getString('chatAPIKey');
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

  Future<String> requestApi(String prompt) async {
    if (apiKey.isEmpty) {
      showToast('apiKey is Empty');
      return throw Exception('apiKey is Empty');
    }
    String url = '';
    var data = {};
    int model = context.read<CurrentChatGPTSetting>().model;
    if (model == 0) {
      url = 'https://api.openai.com/v1/completions';
      data = {
        'model': 'text-davinci-003',
        'prompt': prompt,
        "temperature": 0,
        "max_tokens": 300,
        "top_p": 1,
        "frequency_penalty": 0.0,
        "presence_penalty": 0.0,
      };
    } else if (model == 1) {
      url = 'https://api.openai.com/v1/images/generations';
      data = {"prompt": prompt, "n": 1, "size": "1024x1024"};
    }
    try {
      var response = await Dio().post(url,
          data: data,
          options: Options(headers: {'Authorization': 'Bearer $apiKey'}));
      return model == 0
          ? response.data['choices'][0]['text']
          : response.data['data'][0]['url'];
    } catch (e) {
      rethrow;
    }
  }

  handSendClick() async {
    var prompt = message.toString();
    if (prompt.isEmpty) {
      return showToast('No empty');
    }
    List data = [
      {
        'type': 'question',
        'content': message,
        'contentType': 'text',
        'createTime': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'type': 'answer',
        'content': '',
        'status': 0, // 0 pending 1 success 2 error
        'contentType':
            context.read<CurrentChatGPTSetting>().model == 0 ? 'text' : 'image',
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
      var answer = await requestApi(prompt);
      _editingController.text = '';
      List<Map> writeData = data.map((e) => e as Map).toList();
      writeData[1].remove('status');
      writeData[1]['content'] = answer.trim();
      db.collection(chatGPTDbKey).doc(chatId).update({
        'updateTime': DateTime.now().millisecondsSinceEpoch,
        'messages': FieldValue.arrayUnion(writeData)
      });
      setState(() {
        messageList.last['content'] = answer.trim();
        messageList.last['status'] = 1;
        sendLoading = false;
        hasScrollBottom = true;
      });
    } on DioError catch (e) {
      if (e.response!.data != null) {
        showAlertDialog(
            context: context, message: e.response!.data!['error']['message']);
        // showGeneralDialog(context: context, pageBuilder: pageBuilder)
      }
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

  void handleOnLongPress(Map index) {
    setState(() {
      hasLongPress = true;
      selectedList.add(index);
    });
  }

  void handleOnTap(Map index) {
    if (hasLongPress) {
      toggleCheckBox(index);
    }
  }

  void toggleCheckBox(Map index) {
    setState(() {
      if (selectedList.contains(index)) {
        selectedList.remove(index);
      } else {
        selectedList.add(index);
      }
    });
  }

  void resetLongPressData() {
    setState(() {
      hasLongPress = false;
      selectedList = [];
    });
  }

  handleActionDeleteOnPress() async {
    if (selectedList.isEmpty) {
      return showToast('not empty');
    }
    var result = await showOkCancelAlertDialog(
        context: context,
        message: 'Confirm delete?',
        fullyCapitalizedForMaterial: false,
        okLabel: 'Confirm',
        cancelLabel: 'Cancel');
    if (result == OkCancelResult.ok) {
      var removeSelectedList = [...selectedList].map((item) {
        item.remove('status');
        return item;
      }).toList();
      db.collection(chatGPTDbKey).doc(chatId).update({
        'messages': FieldValue.arrayRemove(removeSelectedList)
      }).then((value) {
        showToast('Successfully deleted');
        setState(() {
          messageList = messageList
              .where((element) => !selectedList.contains(element))
              .toList();
          hasLongPress = false;
          selectedList = [];
        });
      });
    }
  }

  handleActionCopyOnPress() async {
    var text = selectedList.map((e) => e['content']).join();
    await Clipboard.setData(ClipboardData(text: text));
    showToast('Copy successfully');
  }

  void handleRefreshPress(int index) async {
    var targetMessage = messageList[index - 1];
    var data = messageList.sublist(index - 1, index + 1);
    setState(() {
      messageList[index]['status'] = 0;
    });
    try {
      var answer = await requestApi(targetMessage['content']);
      _editingController.text = '';
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
    double screenHeight = MediaQuery.of(context).size.height;
    return HideKeyboard(
      child: SelectionArea(
        child: WillPopScope(
          onWillPop: () async {
            if (hasLongPress) {
              resetLongPressData();
              return false;
            }
            return true;
          },
          child: Scaffold(
              appBar: buildAppBar(
                  hasLongPress
                      ? 'Selected ${selectedList.length} item '
                      : 'ChatGPT',
                  context,
                  actions: [
                    buildScaleAnimatedSwitcher(hasLongPress
                        ? IconButton(
                            onPressed: handleActionCopyOnPress,
                            icon: const Icon(
                              Icons.copy,
                              size: 18,
                            ))
                        : Container()),
                    buildScaleAnimatedSwitcher(hasLongPress
                        ? IconButton(
                            onPressed: handleActionDeleteOnPress,
                            icon: const Icon(Icons.delete, size: 18))
                        : buildIconButton(
                            Icons.menu,
                            () {
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
                            },
                          ))
                  ],
                  leading: buildScaleAnimatedSwitcher(hasLongPress
                      ? IconButton(
                          onPressed: resetLongPressData,
                          iconSize: 18,
                          icon: const Icon(Icons.close))
                      : const BackButton())),
              body: isLoading
                  ? baseLoading
                  : Column(
                      children: [
                        Expanded(
                          child: messageList.isEmpty
                              ? buildBaseEmptyWidget('No data')
                              : Scrollbar(
                                  child: ListView.separated(
                                    controller: _scrollController,
                                    separatorBuilder: (context, index) {
                                      return const Divider(
                                        height: 1,
                                      );
                                    },
                                    itemBuilder: (context, index) {
                                      var item = messageList[index];
                                      var isQuestion =
                                          item['type'] == 'question';
                                      var content = item['content'] as String;
                                      bool isMd = content.contains('```');
                                      var ele = item['contentType'] == 'text'
                                          ? isMd
                                              ? ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                      minHeight:
                                                          screenHeight * 0.4,
                                                      maxHeight:
                                                          screenHeight * 0.6),
                                                  child: Scrollbar(
                                                    child: Markdown(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(0),
                                                        shrinkWrap: true,
                                                        data: content,
                                                        builders: {
                                                          'code':
                                                              CodeElementBuilder(),
                                                        }),
                                                  ))
                                              : Text(
                                                  item['content'],
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontSize: ScreenUtil()
                                                          .setSp(12)),
                                                )
                                          : GestureDetector(
                                              onTap: () {
                                                var index = pics
                                                    .indexOf(item['content']);
                                                //打开B路由
                                                Navigator.push(context,
                                                    MaterialPageRoute(
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
                                                  child: SizedBox(
                                                    width: ScreenUtil()
                                                        .setWidth(250),
                                                    height: ScreenUtil()
                                                        .setWidth(250),
                                                    child:
                                                        ExtendedImage.network(
                                                      item['content'],
                                                      fit: BoxFit.contain,
                                                      mode: ExtendedImageMode
                                                          .gesture,
                                                      cache: true,
                                                    ),
                                                  )),
                                            );
                                      Widget resultEle = ListTile(
                                        selected: selectedList.contains(item),
                                        onTap: () => handleOnTap(item),
                                        onLongPress: () =>
                                            handleOnLongPress(item),
                                        contentPadding: EdgeInsets.all(
                                          ScreenUtil().setWidth(10),
                                        ),
                                        trailing: hasLongPress
                                            ? AnimatedOpacity(
                                                opacity: hasLongPress ? 1 : 0,
                                                duration: const Duration(
                                                    milliseconds: 300),
                                                child: SizedBox(
                                                  width:
                                                      ScreenUtil().setWidth(10),
                                                  height:
                                                      ScreenUtil().setWidth(10),
                                                  child: Checkbox(
                                                      value: selectedList
                                                          .contains(item),
                                                      onChanged: (value) {
                                                        toggleCheckBox(item);
                                                      }),
                                                ),
                                              )
                                            : null,
                                        horizontalTitleGap: 10,
                                        leading: isQuestion
                                            ? ClipOval(
                                                child: buildBaseImage(
                                                    width: ScreenUtil()
                                                        .setWidth(40),
                                                    height: ScreenUtil()
                                                        .setHeight(40),
                                                    url: getCurrentUser()
                                                        .photoURL!),
                                              )
                                            : isMd
                                                ? null
                                                : ClipOval(
                                                    child: Container(
                                                      color:
                                                          const Color.fromRGBO(
                                                              16, 163, 127, 1),
                                                      width: ScreenUtil()
                                                          .setWidth(40),
                                                      height: ScreenUtil()
                                                          .setHeight(40),
                                                      child: Center(
                                                        child: SvgPicture.asset(
                                                          'assets/chat_gpt.svg',
                                                          width: ScreenUtil()
                                                              .setWidth(20),
                                                          height: ScreenUtil()
                                                              .setWidth(20),
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
                                                                FontWeight
                                                                    .normal,
                                                            color: Colors.red),
                                                      )
                                                    : ele,
                                        subtitle: Padding(
                                          padding: EdgeInsets.only(
                                              top: ScreenUtil().setHeight(6)),
                                          child: Text(
                                            formatMessageDate(
                                                item['createTime']),
                                            style: TextStyle(
                                              fontSize: ScreenUtil().setSp(10),
                                            ),
                                          ),
                                        ),
                                      );
                                      return item['status'] == 2
                                          ? Column(
                                              children: [
                                                resultEle,
                                                Container(
                                                  margin: EdgeInsets.only(
                                                      bottom: ScreenUtil()
                                                          .setHeight(15)),
                                                  height:
                                                      ScreenUtil().setWidth(25),
                                                  child: ElevatedButton(
                                                      onPressed: () =>
                                                          handleRefreshPress(
                                                              index),
                                                      child: Text(
                                                        'Refresh',
                                                        style: TextStyle(
                                                            fontSize:
                                                                ScreenUtil()
                                                                    .setSp(10)),
                                                      )),
                                                ),
                                              ],
                                            )
                                          : Column(
                                              children: [
                                                resultEle,
                                                Container(
                                                  height: index ==
                                                          messageList.length - 1
                                                      ? 10
                                                      : 0,
                                                )
                                              ],
                                            );
                                    },
                                    itemCount: messageList.length,
                                  ),
                                ),
                        ),
                        Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            TextField(
                              controller: _editingController,
                              maxLines: 10,
                              minLines: 1,
                              onChanged: (value) {
                                setState(() {
                                  message = value;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: context
                                            .watch<CurrentChatGPTSetting>()
                                            .model ==
                                        0
                                    ? 'Your question'
                                    : 'Image description',
                                border: InputBorder.none,
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
                                  IconButton(
                                    onPressed:
                                        sendLoading ? null : handSendClick,
                                    icon: const Padding(
                                      padding: EdgeInsets.all(5),
                                      child: Icon(
                                        Icons.send,
                                        size: 15,
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
      ),
    );
  }
}
