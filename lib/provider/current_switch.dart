import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const currentUseMaterial3Key = 'currentUseMaterial3';

class CurrentSwitch with ChangeNotifier {
  bool useMaterial3 = false;

  CurrentSwitch(this.useMaterial3);

  changeUseMaterial3(bool value) async {
    useMaterial3 = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(currentUseMaterial3Key, value);
    notifyListeners();
  }
}
