import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const openNotificationKey = 'openNotificationKey';
const openNotificationSoundKey = 'openNotificationSoundKey';

class CurrentChatSetting with ChangeNotifier {
  bool openNotification = false;
  bool openNotificationSound = false;

  CurrentChatSetting(this.openNotification, this.openNotificationSound);

  changeOpenNotification(bool value) async {
    openNotification = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(openNotificationKey, value);
    notifyListeners();
  }

  changeOpenNotificationSound(bool value) async {
    openNotificationSound = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(openNotificationSoundKey, value);
    notifyListeners();
  }
}
