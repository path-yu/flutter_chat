import 'package:flutter/material.dart';

class CurrentUser with ChangeNotifier {
  MyUser? _value;

  MyUser? get value => _value;

  void setCurrentUser(MyUser data) {
    _value = data;
    notifyListeners();
  }

  void initData(MyUser data) {
    _value = data;
  }
}

class MyUser {
  late String email;
  late String photoURL;
  late String suggest;
  late int createTime;
  late int lastLoginTime;
  late bool online;
  late String userName;
  late List contacts;
  late String uid;
  MyUser(
      {required this.email,
      required this.createTime,
      required this.suggest,
      required this.lastLoginTime,
      required this.online,
      required this.userName,
      required this.contacts,
      required this.uid,
      required this.photoURL});

  MyUser.fromJson(Map<String, dynamic> json) {
    email = json['email'];
    createTime = json['createTime'];
    suggest = json['suggest'];
    lastLoginTime = json['lastLoginTime'];
    online = json['online'];
    userName = json['userName'];
    contacts = json['contacts'];
    photoURL = json['photoURL'];
    uid = json['uid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['email'] = email;
    data['createTime'] = createTime;
    data['suggest'] = suggest;
    data['lastLoginTime'] = lastLoginTime;
    data['online'] = online;
    data['userName'] = userName;
    data['photoURL'] = photoURL;
    data['contacts'] = contacts;
    data['uid'] = uid;
    return data;
  }
}
