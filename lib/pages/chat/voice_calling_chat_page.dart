// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/common/show_toast.dart';
import 'package:flutter_chat/components/build_base_image.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/eventBus/index.dart';
import 'package:flutter_chat/provider/current_agora_engine.dart';
import 'package:flutter_chat/provider/current_brightness.dart';
import 'package:flutter_chat/provider/current_primary_swatch.dart';
import 'package:flutter_chat/provider/current_user.dart';
import 'package:provider/provider.dart';

class VoiceCallingChatPage extends StatefulWidget {
  final Map<String, dynamic>? callMessageData;
  const VoiceCallingChatPage({Key? key, this.callMessageData})
      : super(key: key);

  @override
  _VoiceCallingChatPageState createState() => _VoiceCallingChatPageState();
}

class _VoiceCallingChatPageState extends State<VoiceCallingChatPage> {
  final bool _isMuted = false;
  final bool _isSpeakerOn = false;
  final int _callDuration = 0;
  bool loginButtonLoading = false;
  bool rejectButtonLoading = false;
  Map<String, dynamic> messageData = {};

  void _toggleMute() async {
    // await await _engine.muteLocalAudioStream(!openMicrophone);
    // await context
    //     .read<CurrentAgoraEngine>()
    //     .agoraEngine
    //     .enableLocalAudio(!_isMuted);
    // setState(() {
    //   _isMuted = !_isMuted;
    // });
  }

  void _toggleSpeaker() async {
    // await context
    //     .read<CurrentAgoraEngine>()
    //     .agoraEngine
    //     .setEnableSpeakerphone(!_isSpeakerOn);

    // setState(() {
    //   _isSpeakerOn = !_isSpeakerOn;
    // });
  }

  void handleCancelOrEndCallPress(bool isMyRequest) {
    // context.read<CurrentAgoraEngine>().agoraEngine.leaveChannel();

    Navigator.of(context).pop();
    // cancel
    if (isMyRequest && widget.callMessageData!['status'] == 1) {
      updateCallMessage(widget.callMessageData!['id'], 4);
      updateChatData(isMyRequest, 4);
    }
  }

  void handleAcceptPress(bool isMyRequest) async {
    setState(() {
      loginButtonLoading = true;
    });
    var currentAgoraEngine = context.read<CurrentAgoraEngine>();
    currentAgoraEngine.channelName = messageData['channelName'];
    // await currentAgoraEngine.fetchToken();
    await currentAgoraEngine.joinChannel();
    setState(() {
      loginButtonLoading = false;
    });
  }

  void handleRejectPress(bool isMyRequest) async {
    setState(() {
      rejectButtonLoading = true;
    });
    if (loginButtonLoading) return;
    await updateCallMessage(messageData['id'], 3);
    await updateChatData(isMyRequest, 3);
    if (context.mounted) {
      Navigator.pop(context);
    }
    setState(() {
      rejectButtonLoading = false;
    });
  }

  updateChatData(bool isMyRequest, int status) async {
    await updateChatCallCancelMessage(
        chatId: messageData['chatId'],
        status: status,
        targetUid: isMyRequest
            ? messageData['targetUserId']
            : messageData['targetUserId']);
  }

  @override
  void initState() {
    super.initState();
    if (widget.callMessageData == null) {
      return;
    }
    setState(() {
      messageData = widget.callMessageData!;
    });
    eventBus.on<CallMessageChangeEvent>().listen((event) {
      // if(event.data)
      var data = event.data;
      setState(() {
        messageData = data;
      });
      if (data['status'] == 4 || data['status'] == 3 || data['status'] == 5) {
        Navigator.pop(context);
        context.read<CurrentAgoraEngine>().leaveChannel();
      }
    });

    eventBus.on<OnJoinChannelSuccessEvent>().listen((event) {
      var isMyRequest =
          context.read<CurrentUser>().value['uid'] == messageData['uid'];
      updateCallMessage(messageData['id'], 2);
      updateChatData(isMyRequest, 2);
      setState(() {
        loginButtonLoading = false;
      });
      messageData['status'] = 2;
      showToast('join success');
    });
    eventBus.on<OnUserOfflineEvent>().listen((event) {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    var isMyRequest =
        context.read<CurrentUser>().value['uid'] == messageData['uid'];
    var status = messageData['status'];
    var textStyle = const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 16.0,
    );
    return Scaffold(
      appBar: buildAppBar('Voice Call', context,
          leading:
              buildIconButton(Icons.close_fullscreen_sharp, () {}, size: 20)),
      // appBar: AppBar(
      //   title: Text(widget.title),
      // ),

      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              color: context.read<CurrentBrightness>().isDarkMode
                  ? const Color.fromRGBO(0, 0, 0, 0.259)
                  : Colors.grey[200],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    buildBaseCircleImage(
                        url: isMyRequest
                            ? messageData['targetUserAvatar']
                            : messageData['userAvatar'],
                        width: 100,
                        height: 100),
                    const SizedBox(height: 20.0),
                    Text(
                      isMyRequest
                          ? messageData['targetUserUserName']
                          : messageData['userName'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24.0,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    if (status == 1 || status == 2)
                      Text(
                        isMyRequest && status == 1
                            ? 'Waiting for the other party to answer'
                            : status == 2
                                ? 'Calling'
                                : 'Inviting you to a voice call',
                        style: TextStyle(
                          color: context.read<CurrentBrightness>().isDarkMode
                              ? Colors.white24
                              : Colors.grey[600],
                          fontSize: 18.0,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 20.0, horizontal: 40.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    IconButton(
                      icon: _isMuted
                          ? const Icon(Icons.mic_off)
                          : const Icon(Icons.mic),
                      onPressed: _toggleMute,
                    ),
                    const SizedBox(height: 5.0),
                    Text(
                      _isMuted ? 'Muted' : 'Unmuted',
                      style: const TextStyle(fontSize: 12.0),
                    ),
                  ],
                ),
                Column(
                  children: <Widget>[
                    IconButton(
                      icon: _isSpeakerOn
                          ? const Icon(Icons.volume_up)
                          : const Icon(Icons.volume_off),
                      onPressed: _toggleSpeaker,
                    ),
                    const SizedBox(height: 5.0),
                    Text(
                      _isSpeakerOn ? 'Speaker On' : 'Speaker Off',
                      style: const TextStyle(fontSize: 12.0),
                    ),
                  ],
                ),
                Column(
                  children: <Widget>[
                    const Icon(Icons.timer),
                    const SizedBox(height: 5.0),
                    Text(
                      '$_callDuration seconds',
                      style: const TextStyle(fontSize: 12.0),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isMyRequest && status == 1)
            Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.8,
                    child: ElevatedButton(
                        onPressed: () => handleAcceptPress(isMyRequest),
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                context.read<CurrentPrimarySwatch>().color),
                        child: loginButtonLoading
                            ? buttonLoading
                            : Text(
                                'Accept',
                                style: textStyle,
                              )),
                  ),
                  FractionallySizedBox(
                    widthFactor: 0.8,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent),
                        onPressed: () => handleRejectPress(isMyRequest),
                        child: rejectButtonLoading
                            ? buttonLoading
                            : Text(
                                'Reject',
                                style: textStyle,
                              )),
                  )
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              // color: Colors.redAccent,
              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => handleCancelOrEndCallPress(isMyRequest),
                child: Text(
                  isMyRequest && status == 1 ? 'Cancel' : 'End Call',
                  style: textStyle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
