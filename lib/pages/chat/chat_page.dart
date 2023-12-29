// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/common/show_toast.dart';
import 'package:flutter_chat/common/upload.dart';
import 'package:flutter_chat/common/utils.dart';
import 'package:flutter_chat/components/build_base_image.dart';
import 'package:flutter_chat/components/build_scale_animated_switcher.dart';
import 'package:flutter_chat/components/color.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/components/fade_indexed_stack.dart';
import 'package:flutter_chat/components/hide_key_bord.dart';
import 'package:flutter_chat/eventBus/index.dart';
import 'package:flutter_chat/pages/chat/chat_setting_page.dart';
import 'package:flutter_chat/pages/home_page.dart';
import 'package:flutter_chat/pages/photo_view.dart';
import 'package:flutter_chat/provider/current_agora_engine.dart';
import 'package:flutter_chat/provider/current_brightness.dart';
import 'package:flutter_chat/provider/current_primary_swatch.dart';
import 'package:flutter_chat/provider/current_user.dart';
import 'package:flutter_chat/utils/web_audio_recorder_io.dart'
    if (dart.library.html) 'package:flutter_chat/utils/web_audio_recorder.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:record/record.dart';

import 'package:path/path.dart' as p;

class ChatPage extends StatefulWidget {
  final Map<String, dynamic>? parentChatData;
  final double? initialScrollOffset;
  final String? notificationId;
  const ChatPage(
      {super.key,
      this.parentChatData,
      this.initialScrollOffset,
      this.notificationId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

enum MoveDirection { down, up }

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
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
  AudioRecorder? record;
  int startSeconds = 0;
  int sendNewMessageCount = 0;
  final recordStream = <Uint8List>[];
  int? prevSendMessageTime;
  WebAudioRecorder? webAudioRecorder;
  // The other person is typing status
  bool isOtherPersonTyping = false;
  Timer? typingTimer; //  handle delayed tasks
  // 创建一个 FocusNode
  final FocusNode _focusNode = FocusNode();
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
      messageList =
          handleVoiceMessageList(widget.parentChatData!['messageList']);
      Future.delayed(const Duration(milliseconds: 100), () {
        loadMessageListVoiceData();
      });
      chatId = widget.parentChatData!['chatId'];
      replyUid = widget.parentChatData!['replyUid'];
      isMyRequest = widget.parentChatData!['isMyRequest'];
      if (widget.notificationId != null) {
        updateMessageNotification(widget.notificationId!, 0);
      }
    });
    initEventListener();
    initScrollListener();
    // 监听 FocusNode 的焦点变化
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        scrollToBottom();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollController.jumpTo(widget.initialScrollOffset!));
    initListenerMessage();
  }

  initEventListener() {
    eventBus.on<ChatsChangeEvent>().listen((data) {
      var index = data.value.indexWhere((element) => element['id'] == chatId);
      if (index != -1) {
        var target = data.value[index];
        var newMessageList = target['messageList'] as List<Map>;
        if (newMessageList.length == messageList.length) {
          return;
        }
        setState(() {
          if (newMessageList.length > messageList.length) {
            var diffMessageList = newMessageList.sublist(
                messageList.length - 1, newMessageList.length);
            var diffMessageResult = handleVoiceMessageList(diffMessageList);
            messageList = [...messageList, ...diffMessageResult];
            Future.delayed(const Duration(milliseconds: 100), () {
              loadMessageListVoiceData(list: diffMessageResult);
            });
          } else {
            messageList = handleVoiceMessageList(newMessageList);
          }
          if (widget.notificationId != null) {
            updateMessageNotification(widget.notificationId!, 0);
          }
        });
      }
    });
    eventBus.on<TypingEvent>().listen((event) {
      setState(() {
        isOtherPersonTyping = event.isTyping;
      });
    });
  }

  initScrollListener() {
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

  List<Map> handleVoiceMessageList(List<Map> list) {
    return list.map((item) {
      var result = {...item};
      if (item['type'] == 'voice') {
        result = {...item, ...createVoiceMessageData()};
      }
      return result;
    }).toList();
  }

  void loadMessageListVoiceData({List<Map>? list}) async {
    var voiceMessageList = list ?? getVoiceMessageList();
    for (var element in voiceMessageList) {
      if (element?['load'] != null && element['load']) return;
      if (element?['type'] != 'voice') return;
      final player = AudioPlayer(); // Create a player
      Future<Duration?>? futureDuration;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      var filePath = prefs.getString(element['content']);

      if (filePath != null) {
        var file = File(filePath);
        if (file.existsSync()) {
          futureDuration =
              player.setAudioSource(AudioSource.uri(Uri.file(filePath)));
        }
      } else {
        futureDuration = player.setUrl(element['content']);
      }

      futureDuration!.then((value) async {
        setState(() {
          element['load'] = true;
          element['player'] = player;
        });
        player.playerStateStream.listen((state) {
          // play end
          if (state.processingState == ProcessingState.completed) {
            setState(() {
              element['currentSliderValue'] = 100;
              var lastTime = Duration(seconds: element['time']);
              element['currentPlayTimeStr'] =
                  '${lastTime.inMinutes}:${lastTime.inSeconds}';
              element['currentPlayDuration'] = lastTime;
              pause(element['controller'], player, element);
              player.seek(const Duration(seconds: 0));
            });
          }
        });
        player.positionStream.listen((event) {
          double currentSliderValue;
          String currentPlayTimeStr;
          currentSliderValue =
              (event.inSeconds / element['time'] * 100).round().toDouble();
          currentPlayTimeStr = '${event.inMinutes}:${event.inSeconds}';
          setState(() {
            element['currentSliderValue'] = currentSliderValue;
            element['currentPlayTimeStr'] = currentPlayTimeStr;
            element['currentPlayDuration'] = event;
          });
        });
      }, onError: (err) {
        setState(() {
          element['load'] = true;
          element['error'] = 'resource does not exist';
        });
      });
    }
  }

  createVoiceMessageData() {
    var controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    return {
      'pause': true,
      'currentSliderValue': 0.0,
      'controller': controller,
      'animation': Tween<double>(begin: 0.0, end: 1.0).animate(controller),
      'load': false,
      'currentPlayTimeStr': "0:0",
      'currentPlayDuration': const Duration(seconds: 0),
      'error': null
    };
  }

  Debouncer debouncerSendTypingEvent = Debouncer(
    milliseconds: 300, // 1秒的延迟
    action: (replyUid) {
      webSocketChannel?.sink.add(jsonEncode(
          {'type': 'isTyping', 'value': true, 'receiveUid': replyUid}));
    },
  );

  void initListenerMessage() {
    _controller.addListener(() {
      typingTimer?.cancel();
      // 清除之前的延迟任务
      debouncerSendTypingEvent.run(replyUid);
      setState(() {
        if (_controller.text.contains('\n')) {
          showSendBtn = true;
        } else {
          showSendBtn = _controller.text.trim().isNotEmpty;
        }
      });
      typingTimer = Timer(const Duration(milliseconds: 1000), () {
        webSocketChannel?.sink.add(jsonEncode(
            {'type': 'isTyping', 'value': false, 'receiveUid': replyUid}));
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
    webAudioRecorder?.dispose();
    record?.dispose();
    for (var element in messageList) {
      if (element['type'] == 'voice') {
        element['controller'].dispose();
        element['player']?.dispose();
      }
    }
    clearTimer();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Map<String, Map<String, dynamic>> createMessageData(
      {String type = 'text',
      Map<String, dynamic>? payloadValue,
      String? content}) {
    payloadValue ??= {};
    content ?? _controller.text;
    var now = DateTime.now().millisecondsSinceEpoch;
    // add message
    var baseMessageData = {
      'content': content,
      'type': type,
      'uid': getCurrentUser().uid,
      'targetUid': replyUid,
      'createTime': now,
      ...payloadValue,
    };
    var currentUser = context.read<CurrentUser>().value;
    var messageItem = {
      ...baseMessageData,
      'isMyRequest': true,
      'userName': currentUser['userName'],
      'avatar': currentUser['photoURL'],
      'showCreateTime': formatMessageDate(now)
    };

    return {'baseMessageData': baseMessageData, 'messageItem': messageItem};
  }

  handleSendClick() {
    var data = createMessageData(content: _controller.text);
    setState(() {
      messageList.add(data['messageItem']);
      _controller.text = '';
    });
    sendMessage(chatId, data['baseMessageData']!);
    scrollToBottom();
  }

  void sendMessage(String chatId, Map<dynamic, dynamic> message) {
    addMessage(chatId, message);
    addMessageNotification(
        targetUid: replyUid, chatId: chatId, id: widget.notificationId);
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
    scrollToBottom();
  }

  void scrollToBottom() {
    if (_scrollController.hasClients) {
      final position = _scrollController.position.maxScrollExtent;
      Future.delayed(const Duration(milliseconds: 150)).then((value) {
        _scrollController.jumpTo(
          position,
        );
      });
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

  Future<String> _getPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(
      dir.path,
      'audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
  }

  void startRecording() async {
    startSeconds = 0;
    setState(() {
      recordingTime = '0:0';
      stopRecording = false;
      isRecordEnd = false;
    });
    record = AudioRecorder();
    if (kIsWeb) {}
    // Check and request permission
    if (await record!.hasPermission()) {
      // Start recording
      if (kIsWeb) {
        webAudioRecorder = WebAudioRecorder();
        webAudioRecorder!.start();
      } else {
        final path = await _getPath();
        await record!.start(const RecordConfig(), path: path);
      }

      recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (stopRecording) {
          return;
        }
        startSeconds++;
        if (startSeconds >= maxSeconds) {
          startSeconds = 120;
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
    } else {
      showOkAlertDialog(
          message: 'Please enable recording permission', context: context);
    }
  }

  void handSendVoiceClick() async {
    closeRecording();
    var path = await record?.stop();
    var url = '';
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (path != null) {
      File file = File(path);
      // Todo
      url = await uploadFile(file, context);
      prefs.setString(url, path);
    } else {
      // var metadata = await convertStreamToUint8List(recordStream);
      final data = await webAudioRecorder!.stop();
      if (isUint8ListAllZeros(data)) {
        showOkAlertDialog(
          context: context,
          message:
              'Microphone abnormality, Please check if the microphone is work',
        );
        return;
      }
      var fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.mp4';
      url = await uploadFileByStream(data, context, fileName);
    }
    var data = createMessageData(
        type: 'voice', payloadValue: {'time': startSeconds}, content: url);
    setState(() {
      messageList
          .add({...data['messageItem'] as Map, ...createVoiceMessageData()});
      sendMessage(chatId, data['baseMessageData']!);
      Future.delayed(const Duration(milliseconds: 300)).then((value) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      });
    });
    // load audio
    Future.delayed(const Duration(seconds: 0)).then((value) {
      loadMessageListVoiceData(list: [messageList.last]);
    });
  }

  void handleVoicePlayOrPauseClick(
    Map<dynamic, dynamic> item,
  ) {
    var controller = item['controller'] as AnimationController;
    var player = item['player'] as AudioPlayer;
    if (item['currentSliderValue'] == 100) {
      setState(() {
        item['currentPlayDuration'] = const Duration(seconds: 0);
        item['currentPlayTimeStr'] = '0:0';
        item['currentSliderValue'] = 0.0;
        play(controller, player, item);
      });
    } else {
      if (item['pause']) {
        play(controller, player, item);
      } else {
        pause(controller, player, item);
      }
    }
    // stop other player
    var messageVoiceList =
        getVoiceMessageList().where((element) => element != item).toList();
    for (var element in messageVoiceList) {
      if (element['player'] != null) {
        var player = element['player'] as AudioPlayer;
        var controller = element['controller'] as AnimationController;
        if (player.playing) {
          pause(controller, player, element);
        }
      }
    }
  }

  List getVoiceMessageList() {
    return messageList.where((element) => element['type'] == 'voice').toList();
  }

  void play(AnimationController controller, AudioPlayer player, Map item) {
    controller.forward();
    item['pause'] = false;
    player.play();
  }

  void pause(AnimationController controller, AudioPlayer player, Map item) {
    controller.reverse();
    player.pause();
    item['pause'] = true;
  }

  void handlePickerImage() async {
    if (kIsWeb) {
      pickerImgAndUpload((url) {
        addImgMessage([url]);
      }, cropped: false, context: context);
    } else {
      final List<AssetEntity>? result = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
            maxAssets: 3,
            themeColor: context.read<CurrentPrimarySwatch>().color),
      );
      if (result != null) {
        var urlList = await uploadAssetsImage(result);
        addImgMessage(urlList);
      }
    }
  }

  void handleSliderChange(double value, int index) {
    setState(() {
      var item = messageList[index];
      item['currentSliderValue'] = value;
      var currentPlayTime = (value / 100 * item['time']).round();
      (item['player'] as AudioPlayer).seek(Duration(seconds: currentPlayTime));
    });
  }

  // void handleKeyboardOpen() {
  //   var keyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;
  //   if (keyboardVisible) {
  //     Future.delayed(const Duration(milliseconds: 150)).then((value) {
  //       _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  //     });
  //   }
  // }

  handleVoiceCallingPress() async {
    Navigator.pop(context);
    // retrieve or request microphone permission
    var currentAgoraEngine = context.read<CurrentAgoraEngine>();
    currentAgoraEngine.channelName = getCurrentUser().email;
    // currentAgoraEngine.uid = createRandomId();
    EasyLoading.show(status: 'loading...');
    var callMessageData = await addCallMessage(
        chatId, widget.parentChatData!, currentAgoraEngine.channelName!);
    if (callMessageData != null) {
      try {
        if (currentAgoraEngine.token == null) {
          // await currentAgoraEngine.fetchToken();
        }
        await currentAgoraEngine.joinChannel();
        EasyLoading.dismiss();
        toVoiceCallingPage(context, callMessageData);
      } catch (e) {
        EasyLoading.dismiss();
        currentAgoraEngine.leaveChannel();
        showToast('Connection failed, please try again');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // handleKeyboardOpen();
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    var fillColor = context.watch<CurrentBrightness>().isDarkMode
        ? darkMainColor
        : Colors.white;
    return HideKeyboard(
      child: Scaffold(
        appBar: buildAppBar(
            isOtherPersonTyping
                ? 'User is typing...'
                : widget.parentChatData!['targetUserName'],
            context,
            actions: [
              buildIconButton(Icons.phone, () {
                showCupertinoModalPopup<void>(
                    context: context,
                    builder: (BuildContext context) => CupertinoActionSheet(
                          actions: <CupertinoActionSheetAction>[
                            CupertinoActionSheetAction(
                              onPressed: handleVoiceCallingPress,
                              child: const Text('Voice calling'),
                            ),
                            CupertinoActionSheetAction(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Video calling'),
                            ),
                            CupertinoActionSheetAction(
                              /// This parameter indicates the action would perform
                              /// a destructive action such as delete or exit and turns
                              /// the action's text color to red.
                              isDestructiveAction: true,
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Cancel'),
                            ),
                          ],
                        ));
              }),
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
                      bool isDarkMode =
                          context.watch<CurrentBrightness>().isDarkMode;
                      var isMyRequest = item['isMyRequest'];
                      StatelessWidget bubble;
                      Color bubbleBackgroundColor = isMyRequest
                          ? context
                              .read<CurrentPrimarySwatch>()
                              .color
                              .withOpacity(0.4)
                          : isDarkMode
                              ? Colors.black26
                              : Colors.white;
                      TextStyle textStyle = TextStyle(
                          color: isMyRequest
                              ? Colors.white
                              : isDarkMode
                                  ? Colors.white
                                  : Colors.black);

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
                            backGroundColor: bubbleBackgroundColor,
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
                                maxWidth: item['type'] == 'voice'
                                    ? screenWidth * 0.45
                                    : screenWidth * 0.6,
                              ),
                              child: item['type'] == 'voice'
                                  ? buildScaleAnimatedSwitcher(item['load']
                                      ? item['error'] != null
                                          ? Center(
                                              child: Text(
                                                item['error'].toString(),
                                                style: const TextStyle(
                                                    color: Colors.red),
                                              ),
                                            )
                                          : Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Container(
                                                  width:
                                                      ScreenUtil().setWidth(28),
                                                  height:
                                                      ScreenUtil().setWidth(28),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: context
                                                        .read<
                                                            CurrentPrimarySwatch>()
                                                        .color,
                                                  ),
                                                  child: Center(
                                                    child: GestureDetector(
                                                      onTap: () =>
                                                          handleVoicePlayOrPauseClick(
                                                              item),
                                                      child: AnimatedIcon(
                                                        icon: AnimatedIcons
                                                            .play_pause,
                                                        progress:
                                                            item['animation'],
                                                        size: 25.0,
                                                        color: Colors.white,
                                                        semanticLabel:
                                                            'Show menu',
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                buildSpace(
                                                    ScreenUtil().setWidth(5)),
                                                Expanded(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      SliderTheme(
                                                        data: SliderTheme.of(
                                                                context)
                                                            .copyWith(
                                                          trackShape:
                                                              const RectangularSliderTrackShape(),
                                                          thumbShape:
                                                              const RoundSliderThumbShape(
                                                                  enabledThumbRadius:
                                                                      5.0),
                                                          overlayShape:
                                                              const RoundSliderOverlayShape(
                                                                  overlayRadius:
                                                                      5.0),
                                                        ),
                                                        child: Slider(
                                                          value: item[
                                                              'currentSliderValue'],
                                                          max: 100,
                                                          label: item[
                                                                  'currentSliderValue']
                                                              .round()
                                                              .toString(),
                                                          onChanged: (value) =>
                                                              handleSliderChange(
                                                                  value, index),
                                                        ),
                                                      ),
                                                      Opacity(
                                                        opacity: 0.6,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Transform.translate(
                                                              offset: Offset(
                                                                  ScreenUtil()
                                                                      .setWidth(
                                                                          5),
                                                                  0),
                                                              child: Text(
                                                                  item[
                                                                      'currentPlayTimeStr'],
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          ScreenUtil()
                                                                              .setSp(10))),
                                                            ),
                                                            Text(
                                                              '${item['time']}s',
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      ScreenUtil()
                                                                          .setSp(
                                                                              10)),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              ],
                                            )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const CupertinoActivityIndicator(),
                                            SizedBox(
                                              width: ScreenUtil().setWidth(5),
                                            ),
                                            Text(
                                              'Loading',
                                              style: TextStyle(
                                                  fontSize:
                                                      ScreenUtil().setSp(12),
                                                  color: CupertinoColors
                                                      .inactiveGray),
                                            )
                                          ],
                                        ))
                                  : item['type'] == 'callMessage'
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.phone,
                                              color: textStyle.color,
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            SelectableText(
                                                getCallMessageText(
                                                    isMyRequest,
                                                    item['status'],
                                                    item['callTime']),
                                                style: textStyle)
                                          ],
                                        )
                                      : SelectableText(
                                          item['content'].toString(),
                                          style: textStyle),
                            ));
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
                                        child: Text(
                                            formatMessageDate(
                                                item['createTime']),
                                            style: TextStyle(
                                                fontSize:
                                                    ScreenUtil().setSp(10))),
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
                                                    ScreenUtil().setSp(10))),
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
                    height: 0.5,
                    thickness: 0.5,
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
                                    onTap: handlePickerImage,
                                    child: const Icon(
                                      Icons.image,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    keyboardType: TextInputType.multiline,
                                    focusNode: _focusNode,
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
                                              Icons.send, handleSendClick,
                                              size: 20,
                                              iconColor: context
                                                  .read<CurrentPrimarySwatch>()
                                                  .color)
                                          : const SizedBox(),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.all(8),
                                      fillColor: fillColor,
                                      filled: true,
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
                                          if (kIsWeb) {
                                            stopRecording
                                                ? webAudioRecorder?.pause()
                                                : webAudioRecorder?.resume();
                                          } else {
                                            stopRecording
                                                ? record?.pause()
                                                : record?.resume();
                                          }
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
                  bottom: ScreenUtil().setHeight(40),
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
