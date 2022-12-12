import 'package:flutter/material.dart';

class DrawerHead extends StatelessWidget {
  const DrawerHead({super.key});

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
            accountName: const Text('path-yu',
                style: TextStyle(fontWeight: FontWeight.bold)),
            // 副标题
            accountEmail: const Text('https://github.com/path-yu'),
            // Emails
            currentAccountPicture: const CircleAvatar(
              // 使用网络加载图像
              backgroundImage: NetworkImage(
                  'https://avatars.githubusercontent.com/u/59117479?v=4'),
            ),
            // 圆角头像
            decoration: BoxDecoration(
                color: Colors.yellow[400],
                image: DecorationImage(
                    image: const NetworkImage(
                        'https://avatars.githubusercontent.com/u/59117479?v=4'),
                    fit: BoxFit.cover, // 一种图像的布局方式
                    colorFilter: ColorFilter.mode(
                        Colors.grey[400]!.withOpacity(0.6),
                        BlendMode.hardLight))),
            //  BoxDecoration 用于制作背景
          ),
          // ListTile是下方的几个可点按List
          ListTile(
            // List标题
            title: const Text('details'),
            leading: const Icon(
              Icons.favorite, // Icon种类
              color: Colors.black12, // Icon颜色
              size: 22.0, // Icon大小
            ),
            // 点按时间，这里可以做你想做的事情，如跳转、判断等等
            // 此处博主只使用了 Navigator.pop(context) 来手动关闭Drawer
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            title: const Text('Favorite'),
            leading: const Icon(
              Icons.favorite,
              color: Colors.black12,
              size: 22.0,
            ),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            title: const Text('Settings'),
            leading: const Icon(
              Icons.settings,
              color: Colors.black12,
              size: 22.0,
            ),
            onTap: () {
              Navigator.pushNamed(context, '/setting');
            },
          ),
        ],
      ),
    );
  }
}
