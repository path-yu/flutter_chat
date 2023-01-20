import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const chatGPTModelKey = 'chatGPTModelKey';

var modelMap = {0: 'QA', 1: 'Image create'};

class CurrentChatGPTSetting with ChangeNotifier {
  // 0 -> qa 1 -> image create
  int model = 0;
  String get modelLabel => modelMap[model]!;
  CurrentChatGPTSetting(this.model);

  changeMode(int index) {
    model = index;
    SharedPreferences.getInstance().then((value) {
      value.setInt(chatGPTModelKey, index);
    });
    notifyListeners();
  }
}
