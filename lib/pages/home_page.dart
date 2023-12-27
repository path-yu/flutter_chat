import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/common/utils.dart';
import 'package:flutter_chat/eventBus/index.dart';
import 'package:flutter_chat/pages/components/home/home_contacts.dart';
import 'package:flutter_chat/pages/components/home/home_messages.dart';
import 'package:flutter_chat/provider/current_agora_engine.dart';
import 'package:flutter_chat/provider/current_chat_setting.dart';
import 'package:flutter_chat/provider/current_user.dart';
import 'package:flutter_chat/utils/notification.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import "package:universal_html/html.dart";

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

WebSocketChannel? webSocketChannel;

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int currentIndex = 0;
  int newFriendsBadgeCount = 0;
  // int newMessageCount = 0;
  Map messageNotificationMaps = {};
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioElement? audio;
  int get newMessageCount {
    return messageNotificationMaps.values.fold(0, (previousValue, element) {
      int count = element['count'];
      return previousValue + count;
    });
  }

  List<int>? message_soundBytes;
  void handleOnTap(int? index) {
    setState(() {
      currentIndex = index!;
    });
  }

  @override
  void initState() {
    super.initState();
    db
        .collection(UsersDbKey)
        .doc(getCurrentUser().uid)
        .snapshots()
        .listen((doc) {
      var data = doc.data()!;
      context.read<CurrentUser>().setCurrentUser(data);
      eventBus.fire(UserChangeEvent(data));
    });
    listenAddContactNotification();
    listenMessageNotification();
    listenCallMessage();
    setNotificationListener();
    initWebSocket();
    _audioPlayer.setAsset('assets/new_message_sound.wav');
    if (kIsWeb) {
      rootBundle.load('assets/new_message_sound.wav').then((value) {
        message_soundBytes = value.buffer.asUint8List();
        audio = AudioElement(
            'data:audio/mp3;base64,${base64Encode(message_soundBytes!)}');
        audio!.load();
      });
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    webSocketChannel?.sink.close();
    print('close');
  }

  void initWebSocket() async {
    final wsUrl = Uri.parse(kDebugMode
        ? 'ws://localhost:8080/start_web_socket?userId=${getCurrentUser().uid}'
        : 'wss://old-heron-24.deno.dev/start_web_socket?userId=${getCurrentUser().uid}');
    webSocketChannel = WebSocketChannel.connect(wsUrl);

    eventBus.on<CloseSocketEvent>().listen((event) {
      webSocketChannel?.sink.close();
    });
    await webSocketChannel?.ready;
    webSocketChannel?.stream.listen(
      (message) {
        // channel.sink.add('received!');
        var data = jsonDecode(message);
        // update online status
        if (data['type'] == 'userJoinedConnected') {
          eventBus.fire(
              UserOnlineChangeEvent(data['chatIds'], 'userJoinedConnected'));
        }
        if (data['type'] == 'userDisconnected') {
          eventBus
              .fire(UserOnlineChangeEvent(data['chatIds'], 'userDisconnected'));
        }
        if (data['type'] == 'isTyping') {
          eventBus.fire(TypingEvent(data['value']));
        }
      },
    );
  }

  void listenAddContactNotification() {
    db
        .collection(NOTIFICATION)
        .where('targetEmail', isEqualTo: getCurrentUser().email)
        .where('type', isEqualTo: 'addContact')
        .snapshots()
        .listen((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        // filter pending
        setState(() {
          newFriendsBadgeCount = querySnapshot.docs
              .where((element) {
                return element.data()['status'] == 'pending';
              })
              .toList()
              .length;
        });
      } else {
        setState(() {
          newFriendsBadgeCount = 0;
        });
      }
    });
  }

  void listenCallMessage() {
    db
        .collection(CALLMESSAGE)
        .where('targetUserId', isEqualTo: getCurrentUser().uid)
        .snapshots()
        .listen((querySnapshot) {
      var docs = querySnapshot.docs;
      if (docs.isNotEmpty) {
        var callMessageData = querySnapshot.docs.first.data();
        callMessageData['id'] = querySnapshot.docs.first.id;
        eventBus.fire(CallMessageChangeEvent(callMessageData));
        var status = callMessageData['status'];
        if (callMessageData['status'] == 1) {
          toVoiceCallingPage(context, callMessageData);
        }
        if (status == 4 || status == 3 || status == 5) {
          context.read<CurrentAgoraEngine>().leaveChannel();
        }
      }
    });
    db
        .collection(CALLMESSAGE)
        .where('uid', isEqualTo: getCurrentUser().uid)
        .snapshots()
        .listen((querySnapshot) {
      var docs = querySnapshot.docs;
      if (docs.isNotEmpty) {
        var callMessageData = querySnapshot.docs.first.data();
        callMessageData['id'] = querySnapshot.docs.first.id;
        var status = callMessageData['status'];
        eventBus.fire(CallMessageChangeEvent(callMessageData));
        if (status == 4 || status == 3 || status == 5) {
          context.read<CurrentAgoraEngine>().leaveChannel();
        }
      }
    });
  }

  void listenMessageNotification() {
    db
        .collection(NOTIFICATION)
        .where('targetUid', isEqualTo: getCurrentUser().uid)
        .where('type', isEqualTo: 'newMessage')
        .snapshots()
        .listen((querySnapshot) {
      void setAction() {
        for (var e in querySnapshot.docs) {
          var data = e.data();
          data['id'] = e.id;
          messageNotificationMaps[e['chatId']] = data;
          if (data['count'] != 0 &&
              context.read<CurrentChatSetting>().openNotification) {
            // not support web
            if (!kIsWeb) {
              addNotification(
                  '${data['userName']}:${data['count']} new messages',
                  {'chatId': data['chatId'], 'notificationId': e.id},
                  e['localNotificationId']);
            }
            if (context.read<CurrentChatSetting>().openNotificationSound) {
              if (kIsWeb) {
                audio?.play();
              } else {
                // An error will be reported on the web
                _audioPlayer.play();
              }
            }
          }
        }
      }

      if (mounted) {
        setState(setAction);
      } else {
        setAction();
      }
    });
  }
  // Future<void> initUniLinks() async {
  //   print('init');
  //   // ... check initialLink

  //   // Attach a listener to the stream
  //   _sub = linkStream.listen((String? link) {
  //     print('openAPPPPP');
  //     print(link);
  //     // Parse the link and warn the user, if it is not correct
  //   }, onError: (err) {
  //     // Handle exception by warning the user their action did not succeed
  //   });

  //   // NOTE: Don't forget to call _sub.cancel() in dispose()
  // }

  @override
  Widget build(BuildContext context) {
    final List<BottomNavigationBarItem> bottomTabsList = [
      BottomNavigationBarItem(
          label: 'Messages',
          icon: newMessageCount != 0
              ? Badge.count(
                  count: newMessageCount,
                  child: const Icon(Icons.message),
                )
              : const Icon(Icons.message)),
      BottomNavigationBarItem(
          icon: newFriendsBadgeCount != 0
              ? Badge.count(
                  count: newFriendsBadgeCount,
                  child: const Icon(Icons.people),
                )
              : const Icon(Icons.people),
          label: 'Contacts'),
    ];

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        items: bottomTabsList,
        onTap: handleOnTap,
      ),
      body: IndexedStack(
        index: currentIndex,
        children: [
          HomeMessages(
            messageNotificationMaps: messageNotificationMaps,
          ),
          HomeContacts(
            hasNewFriends: newFriendsBadgeCount != 0,
            messageNotificationMaps: messageNotificationMaps,
          ),
        ],
      ),
    );
  }
}
