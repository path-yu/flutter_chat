import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/eventBus/index.dart';
import 'package:permission_handler/permission_handler.dart';

var appId = '8eb6f164191846e78f446285151c0560';
var serverUrl = 'https://agora-token-service-production-242d.up.railway.app';

// import 'package:flutter/'
class CurrentAgoraEngine with ChangeNotifier {
  RtcEngine agoraEngine = createAgoraRtcEngine();
  bool isTokenExpiring = false;
  final ChannelProfileType _channelProfileType =
      ChannelProfileType.channelProfileLiveBroadcasting;
  String? token;
  int tokenRole = 1;
  int? uid = 0;
  String? channelName;
  // bool hasInit = false;
  bool isJoined = false;
  Future<void> setupVoiceSDKEngine(
      {Function(RtcConnection, int)? onJoinChannelSuccess,
      Function(RtcConnection, int, int)? onUserJoined,
      Function(RtcConnection, int, UserOfflineReasonType)?
          onUserOffline}) async {
    agoraEngine = createAgoraRtcEngine();
    await agoraEngine.initialize(RtcEngineContext(
      appId: appId,
    ));

    agoraEngine.registerEventHandler(RtcEngineEventHandler(
      onError: (ErrorCodeType err, String msg) {
        print('[onError] err: $err, msg: $msg');
      },
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        print(
            '[onJoinChannelSuccess] connection: ${connection.toJson()} elapsed: $elapsed');
        isJoined = true;
        notifyListeners();
        eventBus.fire(OnJoinChannelSuccessEvent(connection, elapsed));
      },
      onLeaveChannel: (RtcConnection connection, RtcStats stats) {
        print(
            '[onLeaveChannel] connection: ${connection.toJson()} stats: ${stats.toJson()}');
        isJoined = false;
        notifyListeners();
      },
      onTokenPrivilegeWillExpire: (connection, token) {
        isTokenExpiring = true;
        fetchToken();
      },
      onUserOffline: (connection, remoteUid, reason) {
        eventBus.fire(OnUserOfflineEvent(connection, remoteUid, reason));
      },
    ));

    await agoraEngine.enableAudio();
    await agoraEngine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await agoraEngine.setAudioProfile(
      profile: AudioProfileType.audioProfileDefault,
      scenario: AudioScenarioType.audioScenarioGameStreaming,
    );
  }

  Future<void> fetchToken() async {
    // Prepare the Url
    String url =
        '$serverUrl/rtc/$channelName/${tokenRole.toString()}/uid/${uid.toString()}?expiry=3600';
    debugPrint('url Received: $url');
    // Send the request
    final response = await Dio().get(url);

    if (response.statusCode == 200) {
      // If the server returns an OK response, then parse the JSON.
      String newToken = response.data['rtcToken'];
      debugPrint('Token Received: $newToken');
      // Use the token to join a channel or renew an expiring token
      setToken(newToken);
    } else {
      // If the server did not return an OK response,
      // then throw an exception.
      throw Exception(
          'Failed to fetch a token. Make sure that your server URL is valid');
    }
  }

  void setToken(String newToken) async {
    token = newToken;

    if (isTokenExpiring) {
      // Renew the token
      agoraEngine.renewToken(token!).then((value) {
        isTokenExpiring = false;
        joinChannel();
      });
    } else {
      joinChannel();
    }
  }

  joinChannel() async {
    await Permission.microphone.request();

    await agoraEngine.joinChannel(
        token: token!,
        channelId: channelName!,
        uid: 0,
        options: ChannelMediaOptions(
          channelProfile: _channelProfileType,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ));
  }

  leaveChannel() {
    agoraEngine.leaveChannel();
  }
}
