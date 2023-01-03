import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const currentPrimarySwatchKey = 'currentPrimarySwatchKey';

class CurrentPrimarySwatch with ChangeNotifier {
  MaterialColor color;
  CurrentPrimarySwatch(this.color);
  String get colorName => ColorTools.materialName(color);
  changeColor(Color value) async {
    color = ColorTools.createPrimarySwatch(value);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(currentPrimarySwatchKey, value.value);
    notifyListeners();
  }
}
