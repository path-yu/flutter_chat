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
  bool loading = false;
  List chatIdList = [];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? unSubscribe;
  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    initData();
  }

  void initData() {
    eventBus.on<UserChangeEvent>().listen((event) async {
      List chats = event.user['chats'];
      if (chats.length == chatList.length) {
        return;
      }
      if (chats.isNotEmpty) {
        if (unSubscribe != null) {
          unSubscribe!.cancel();
        }
        setState(() => loading = true);
        unSubscribe = db
            .collection(ChatsKey)
            .where('id', whereIn: chats)
            .snapshots()
            .listen((event) async {
          var data = await handleChatData(event);
          setState(() {
            loading = false;
            chatList = data;
            eventBus.fire(ChatsChangeEvent(data));
          });
        });
      }
    });
    // listen message
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
              : ListView.separated(
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
                      subtitle: buildOneLineText(
                        item['lastMessage'],
                      ),
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
    );
  }
}
