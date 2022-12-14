import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/components/build_base_image.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/components/drawer.dart';
import 'package:flutter_chat/eventBus/index.dart';
import 'package:flutter_chat/pages/chat_page.dart';
import 'package:flutter_chat/provider/current_user.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeMessages extends StatefulWidget {
  const HomeMessages({super.key});

  @override
  State<HomeMessages> createState() => _HomeMessagesState();
}

class _HomeMessagesState extends State<HomeMessages> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List chatList = [];
  bool loading = true;
  List chatIdList = [];

  Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>?
      unSubscribeMap = {};
  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    listenChatData();
    initGetChatData();
  }

  void listenChatData() {
    eventBus.on<UserChangeEvent>().listen((event) async {
      List chats = event.user['chats'];
      if (chats.length == chatList.length) {
        return;
      }
      if (unSubscribeMap!.values.isNotEmpty) {
        for (var element in unSubscribeMap!.values) {
          element.cancel();
        }
      }
      if (chats.isNotEmpty) {
        for (var chatId in chats) {
          unSubscribeMap![chatId] = db
              .collection(ChatsKey)
              .where('id', isEqualTo: chatId)
              .snapshots()
              .listen((event) async {
            var data = await handleChatData(event);
            var index = chatList.indexWhere((ele) => ele['id'] == data['id']);
            setState(() {
              if (index == -1) {
                chatList.add(data);
              } else {
                chatList[index] = data;
              }
            });
            eventBus.fire(ChatsChangeEvent(chatList));
          });
        }
      } else {
        setState(() {
          chatList = [];
        });
      }
    });
    // listen message
  }

  initGetChatData() async {
    var user = await searchUserByEmail(getCurrentUser().email!);
    var userData = user.docs[0].data();
    List chats = userData['chats'];
    if (chats.isEmpty) {
      return setState(() {
        loading = false;
        chatList = [];
      });
    }
    var data = await queryChats(chats);
    setState(() {
      loading = false;
      chatList = [data];
      eventBus.fire(ChatsChangeEvent(chatList));
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: DrawerHead(
        scaffoldKey: _scaffoldKey,
      ),
      appBar: buildAppBar('Messages', context,
          showBackButton: false,
          leading: GestureDetector(
            onTap: () {
              _scaffoldKey.currentState!.openDrawer();
            },
            child: Container(
              margin: EdgeInsets.all(ScreenUtil().setWidth(10)),
              child: ClipOval(
                child: buildBaseImage(
                    width: ScreenUtil().setWidth(40),
                    height: ScreenUtil().setHeight(40),
                    url: context.watch<CurrentUser>().value['photoURL']),
              ),
            ),
          )),
      body: loading
          ? baseLoading
          : chatList.isEmpty
              ? buildBaseEmptyWidget('no chats')
              : RefreshIndicator(
                  onRefresh: () async {
                    await initGetChatData();
                    return;
                  },
                  child: ListView.separated(
                    itemBuilder: (context, index) {
                      var item = chatList[index];
                      return ListTile(
                        onTap: () {
                          // Obtain shared preferences.
                          SharedPreferences.getInstance().then((prefs) {
                            var offset = prefs.getString(item['id']);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  parentChatData: item,
                                  initialScrollOffset:
                                      offset != null ? double.parse(offset) : 0,
                                ),
                              ),
                            );
                          });
                        },
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(5.0),
                          child: ClipOval(
                            child: buildBaseImage(
                                width: ScreenUtil().setWidth(40),
                                height: ScreenUtil().setHeight(40),
                                url: item['showAvatar']),
                          ),
                        ),
                        title: buildOneLineText(item['showUserName']),
                        subtitle: item['lastMessage'] != null
                            ? buildOneLineText(
                                item['lastMessage'],
                              )
                            : null,
                        trailing: Text(item['showUpdateTime'],
                            style: subtitleTextStyle),
                      );
                    },
                    itemCount: chatList.length,
                    separatorBuilder: (BuildContext context, int index) {
                      return Divider(
                        color: Colors.grey,
                        height: ScreenUtil().setHeight(1),
                        indent: ScreenUtil().setWidth(65),
                      );
                    },
                  ),
                ),
    );
  }
}
