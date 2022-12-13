import 'package:flutter/material.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/components/drawer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeContacts extends StatefulWidget {
  const HomeContacts({super.key});

  @override
  State<HomeContacts> createState() => _HomeContactsState();
}

class _HomeContactsState extends State<HomeContacts> {
  void handleAddContactClick() {
    Navigator.pushNamed(context, '/addContact');
    // 显示对话框的代码
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerHead(),
      appBar: buildAppBar('Contacts', context,
          showBackButton: false,
          actions: [
            buildIconButton(Icons.search, (() {
              Navigator.pushNamed(context, '/search');
            }), size: ScreenUtil().setSp(20)),
            buildIconButton(Icons.add, handleAddContactClick,
                size: ScreenUtil().setSp(20))
          ],
          leadingWidth: ScreenUtil().setWidth(30),
          leading: GestureDetector(
            onTap: () {
              Scaffold.of(context).openDrawer();
            },
            child: Padding(
              padding: EdgeInsets.only(left: ScreenUtil().setWidth(5)),
              child: const Image(
                image: NetworkImage(
                    'https://avatars.githubusercontent.com/u/59117479?v=4'),
              ),
            ),
          )),
      body: Column(
        children: [
          ListTile(
            onTap: () {},
            leading: Icon(
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
          )
        ],
      ),
    );
  }
}
