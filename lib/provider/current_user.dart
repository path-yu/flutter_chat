import 'package:flutter/material.dart';
import 'package:flutter_chat/common/defaultData.dart';

class CurrentUser with ChangeNotifier {
  Map<String, dynamic> _value = {
    'email': '',
    'createTime': DateTime.now().millisecondsSinceEpoch.toString(),
    'lastLoginTime': DateTime.now().millisecondsSinceEpoch.toString(),
    'suggest': '',
    'online': true,
    'contacts': [],
    'uid': '',
    'userName': '',
    'photoURL': defaultAvatar
  };

  Map<String, dynamic> get value => _value;

  void setCurrentUser(Map<String, dynamic> data) {
    _value = data;
    notifyListeners();
  }
}
