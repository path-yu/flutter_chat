import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrentBrightness with ChangeNotifier {
  String brightness;
  Brightness systemBrightness;
  Brightness? get value => brightness == 'system'
      ? systemBrightness
      : brightness == 'dark'
          ? Brightness.dark
          : Brightness.light;

  int get brightnessKey => brightness == 'system'
      ? 0
      : brightness == 'dark'
          ? 1
          : 2;
  bool get isDarkMode => brightness == 'system'
      ? systemBrightness == Brightness.dark
      : value == Brightness.dark;

  CurrentBrightness(this.brightness, this.systemBrightness);

  changeBrightness(String value) async {
    brightness = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('currentBrightness', value);
    notifyListeners();
  }

  changeSystemBrightness(Brightness value) {
    systemBrightness = value;
    notifyListeners();
  }
}
