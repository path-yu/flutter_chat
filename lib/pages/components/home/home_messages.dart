import 'package:flutter/material.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/components/drawer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeMessages extends StatefulWidget {
  const HomeMessages({super.key});

  @override
  State<HomeMessages> createState() => _HomeMessagesState();
}

class _HomeMessagesState extends State<HomeMessages> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const DrawerHead(),
      appBar: buildAppBar('Chat', context,
          showBackButton: false,
          leadingWidth: ScreenUtil().setWidth(30),
          leading: GestureDetector(
            onTap: () {
              _scaffoldKey.currentState!.openDrawer();
            },
            child: Padding(
              padding: EdgeInsets.only(left: ScreenUtil().setWidth(5)),
              child: const Image(
                image: NetworkImage(
                    'https://avatars.githubusercontent.com/u/59117479?v=4'),
              ),
            ),
          )),
      body: ListView.builder(
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
                    'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg'),
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
      ),
    );
  }
}
