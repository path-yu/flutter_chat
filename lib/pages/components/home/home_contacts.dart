import 'package:badges/badges.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/components/build_base_image.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/components/drawer.dart';
import 'package:flutter_chat/provider/current_user.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:octo_image/octo_image.dart';
import 'package:provider/provider.dart';

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
  bool loading = true;
  @override
  void initState() {
    super.initState();
    db
        .collection(UsersDbKey)
        .doc(getCurrentUser().uid)
        .snapshots()
        .listen((doc) async {
      if (doc.data() != null) {
        var contacts = doc.data()!['contacts'];
        if (contacts.length == 0) {
          return setState(() {
            loading = false;
          });
        }
        var contactsList = await searchUserByEmails(contacts);
        var data = mapQuerySnapshotData(contactsList);
        setState(() {
          contactList = data;
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
      }
    });
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
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
                              onTap: () {},
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
