import 'package:flutter/material.dart';
import 'package:flutter_chat/pages/account/forget_password_page.dart';
import 'package:flutter_chat/pages/add_contact_page.dart';
import 'package:flutter_chat/pages/change_password_page.dart';
import 'package:flutter_chat/pages/chatGPT/chat_gpt_page.dart';
import 'package:flutter_chat/pages/chat_page.dart';
import 'package:flutter_chat/pages/chat_setting_page.dart';
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
  '/forget': (BuildContext context) => const ForgetPasswordPage(),
};
final authRoutes = {
  '/': (BuildContext context) => const HomePage(),
  '/chat': (BuildContext context) => const ChatPage(),
  '/search': (BuildContext context) => const SearchPage(),
  '/addContact': (BuildContext context) => const AddContactPage(),
  '/setting': (BuildContext context) => const SettingPage(),
  '/newFriends': (BuildContext context) => const NewFriendsPage(),
  '/editUser': (BuildContext context) => const EditUserPage(),
  '/chatSetting': (BuildContext context) => const ChatSettingPage(),
  '/changePassword': (BuildContext context) => const ChangePasswordPage(),
  '/chatGPT': (BuildContext context) => const ChatGPTPage()
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
