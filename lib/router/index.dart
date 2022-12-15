import 'package:flutter/material.dart';
import 'package:flutter_chat/pages/add_contact_page.dart';
import 'package:flutter_chat/pages/chat_page.dart';
import 'package:flutter_chat/pages/edit_user_page.dart';
import 'package:flutter_chat/pages/home_page.dart';
import 'package:flutter_chat/pages/login_page.dart';
import 'package:flutter_chat/pages/new_friends_page.dart';
import 'package:flutter_chat/pages/register_page.dart';
import 'package:flutter_chat/pages/search_page.dart';
import 'package:flutter_chat/pages/setting_page.dart';

final baseRoutes = {
  '/login': (BuildContext context) => const LoginPage(),
  '/register': (BuildContext context) => const RegisterPage(),
};
final authRoutes = {
  '/': (BuildContext context) => HomePage(),
  '/chat': (BuildContext context) => const ChatPage(),
  '/search': (BuildContext context) => const SearchPage(),
  '/addContact': (BuildContext context) => const AddContactPage(),
  '/setting': (BuildContext context) => const SettingPage(),
  '/newFriends': (BuildContext context) => const NewFriendsPage(),
  '/editUser': (BuildContext context) => const EditUserPage(),
};
MaterialPageRoute<Widget> getPage(String key, BuildContext context) {
  return MaterialPageRoute<Widget>(builder: (BuildContext context) {
    return baseRoutes[key]!(context);
  });
}

MaterialPageRoute<Widget> getAuthPage(String key, BuildContext context) {
  return MaterialPageRoute<Widget>(builder: (BuildContext context) {
    return authRoutes[key]!(context);
  });
}
