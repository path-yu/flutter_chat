import 'package:flutter/material.dart';
import 'package:flutter_chat/components/build_base_image.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/components/drawer.dart';
import 'package:flutter_chat/provider/current_user.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class HomeMessages extends StatefulWidget {
  const HomeMessages({super.key});

  @override
  State<HomeMessages> createState() => _HomeMessagesState();
}

class _HomeMessagesState extends State<HomeMessages> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
      appBar: buildAppBar('Chat', context,
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
      body: ListView.separated(
        itemBuilder: (context, index) {
          return ListTile(
            onTap: () {
              Navigator.pushNamed(context, '/chat');
            },
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(5.0),
              child: Image(
                width: ScreenUtil().setWidth(45),
                height: ScreenUtil().setHeight(45),
                image: const NetworkImage(
                    'https://firebasestorage.googleapis.com/v0/b/chat-fe875.appspot.com/o/images%20(1).jpg?alt=media&token=eb206a7a-1802-48ec-b3e5-44d74857ab5f'),
              ),
            ),
            title: const Text('path-yu'),
            subtitle: Text(
              'hello what are you doing',
              style: subtitleTextStyle,
            ),
            trailing: Text('20:20', style: subtitleTextStyle),
          );
        },
        itemCount: 30,
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
