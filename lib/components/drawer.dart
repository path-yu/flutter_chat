import 'package:flutter/material.dart';
import 'package:flutter_chat/provider/current_user.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DrawerHead extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const DrawerHead({super.key, required this.scaffoldKey});
  Future<void> _launchUrl() async {
    const url = 'https://github.com/path-yu/flutter_chat';
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      // 重要的Drawer组件
      child: ListView(
        // Flutter 可滚动组件
        padding: EdgeInsets.zero, // padding为0
        children: <Widget>[
          UserAccountsDrawerHeader(
            // UserAccountsDrawerHeader 可以设置用户头像、用户名、Email 等信息，显示一个符合纸墨设计规范的 drawer header。
            // 标题
            accountName: Text(context.watch<CurrentUser>().value['userName'],
                style: const TextStyle(fontWeight: FontWeight.bold)),
            // 副标题
            accountEmail: Text(context.watch<CurrentUser>().value['suggest']),
            // Emails
            currentAccountPicture: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/editUser');
                scaffoldKey.currentState!.closeDrawer();
              },
              child: CircleAvatar(
                // 使用网络加载图像
                backgroundImage: NetworkImage(
                  context.watch<CurrentUser>().value['photoURL'],
                ),
              ),
            ),
            //  BoxDecoration 用于制作背景
          ),
          // ListTile是下方的几个可点按List
          ListTile(
            title: const Text('Settings'),
            leading: const Icon(
              Icons.settings,
              size: 22.0,
            ),
            onTap: () {
              Navigator.pushNamed(context, '/setting');
            },
          ),
          ListTile(
            title: const Text('Source code'),
            leading: SvgPicture.asset(
              'assets/github_icon.svg',
              width: 22,
              height: 22,
            ),
            onTap: () {
              _launchUrl();
            },
          ),
        ],
      ),
    );
  }
}
