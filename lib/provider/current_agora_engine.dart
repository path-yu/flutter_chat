import 'package:flutter/material.dart';

var appId = '8eb6f164191846e78f446285151c0560';
var serverUrl = 'https://agora-token-service-production-242d.up.railway.app';

// import 'package:flutter/'
class CurrentAgoraEngine with ChangeNotifier {
  String? token;
  int tokenRole = 1;
  int? uid = 0;
  String? channelName;
  // bool hasInit = false;
  bool isJoined = false;

  joinChannel() async {}

  leaveChannel() {}
}
