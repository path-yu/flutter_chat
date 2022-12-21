import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/components/build_base_image.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/components/drawer.dart';
import 'package:flutter_chat/eventBus/index.dart';
import 'package:flutter_chat/pages/chat_page.dart';
import 'package:flutter_chat/provider/current_user.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeContacts extends StatefulWidget {
  final bool? hasNewFriends;
  const HomeContacts({super.key, this.hasNewFriends});

  @override
  State<HomeContacts> createState() => _HomeContactsState();
}

class _HomeContactsState extends State<HomeContacts> {
  void handleAddContactClick() {
    Navigator.pushNamed(context, '/addContact');
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> contactList = [];
  List<dynamic> chats = [];

  bool loading = true;
  bool callTapLock = false;

  @override
  void initState() {
    super.initState();
    eventBus.on<UserChangeEvent>().listen((event) async {
      var contacts = event.user['contacts'];
      if (contacts.length == 0) {
        return setState(() {
          loading = false;
        });
      }
      var contactsList = await searchUserByEmails(contacts);
      var data = mapQuerySnapshotData(contactsList,
          otherValue: {'hasChats': false, 'chatId': ''});
      setState(() {
        contactList = data;
        loading = false;
      });
    });
    eventBus.on<ChatsChangeEvent>().listen((event) {
      chats = event.value;
    });
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void handleContactItemClick(int index) {
    if (callTapLock) {
      return;
    }
    var item = contactList[index];
    if (item['hasChats']) {
      toChatPage(item['chatId']);
    } else {
      callTapLock = true;
      EasyLoading.show(status: 'loading...');
      // search chat
      searchChat(index);
    }
  }

  void toChatPage(String chatId) {
    SharedPreferences.getInstance().then((prefs) {
      var offset = prefs.getString(chatId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            parentChatData: getChatDataById(chats, chatId),
            initialScrollOffset: offset != null ? double.parse(offset) : 0,
          ),
        ),
      );
    });
  }

  void searchChat(int index) async {
    var cur = getCurrentUser();
    var item = contactList[index];

    var myChat = await queryMyChat(cur.uid, item['uid']).get();
    if (myChat.docs.isNotEmpty) {
      setState(() {
        var id = myChat.docs[0].id;
        contactList[index]['hasChats'] = true;
        contactList[index]['chatId'] = id;
        toChatPage(id);
      });
      EasyLoading.dismiss();
      callTapLock = false;
    }
    var toMyChat = await queryMyChat(item['uid'], cur.uid).get();
    if (toMyChat.docs.isNotEmpty) {
      setState(() {
        var id = toMyChat.docs[0].id;
        contactList[index]['hasChats'] = true;
        contactList[index]['chatId'] = id;
        toChatPage(id);
      });
      EasyLoading.dismiss();
      callTapLock = false;
    }
    // create new chat
    if (contactList[index]['chatId'].isEmpty) {
      addNewChat(contactList[index]['uid']).then((value) {
        EasyLoading.dismiss();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              parentChatData: {
                'chatId': value,
                'messageList': const [],
                'replyUid': contactList[index]['uid'],
                'appbarTitle': contactList[index]['userName']
              },
              initialScrollOffset: 0,
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: DrawerHead(
        scaffoldKey: _scaffoldKey,
      ),
      appBar: buildAppBar('Contacts', context,
          showBackButton: false,
          actions: [
            buildIconButton(Icons.search, (() {
              Navigator.pushNamed(context, '/search');
            }), size: ScreenUtil().setSp(20)),
            buildIconButton(Icons.add, handleAddContactClick,
                size: ScreenUtil().setSp(20))
          ],
          leading: GestureDetector(
            onTap: () {
              _scaffoldKey.currentState!.openDrawer();
            },
            child: Container(
              margin: EdgeInsets.all(ScreenUtil().setWidth(10)),
              child: ClipOval(
                child: Image.network(
                  context.watch<CurrentUser>().value['photoURL'],
                  fit: BoxFit.fill,
                  height: ScreenUtil().setHeight(40),
                ),
              ),
            ),
          )),
      body: Column(
        children: [
          ListTile(
            onTap: () {
              Navigator.pushNamed(context, '/newFriends');
            },
            leading:
                widget.hasNewFriends != null && widget.hasNewFriends == true
                    ? Badge(
                        position: BadgePosition.topEnd(top: -2),
                        child: Icon(
                          Icons.person_add,
                          size: ScreenUtil().setSp(25),
                        ),
                      )
                    : Icon(
                        Icons.person_add,
                        size: ScreenUtil().setSp(25),
                      ),
            title: const Text('new friends'),
          ),
          ListTile(
            onTap: () {},
            leading: Icon(
              Icons.groups,
              size: ScreenUtil().setSp(25),
            ),
            title: const Text('group chat'),
          ),
          Expanded(
              child: loading
                  ? baseLoading
                  : contactList.isEmpty
                      ? buildBaseEmptyWidget('no contacts')
                      : ListView.separated(
                          itemBuilder: ((context, index) {
                            return ListTile(
                              onTap: () => handleContactItemClick(index),
                              contentPadding:
                                  EdgeInsets.all(ScreenUtil().setWidth(10)),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(5.0),
                                child: buildBaseImage(
                                  width: ScreenUtil().setWidth(40),
                                  height: ScreenUtil().setHeight(40),
                                  url: contactList[index]['photoURL'],
                                ),
                              ),
                              title: buildOneLineText(
                                  contactList[index]['userName']),
                            );
                          }),
                          separatorBuilder: (BuildContext context, int index) {
                            return baseDivider;
                          },
                          itemCount: contactList.length))
        ],
      ),
    );
  }
}
