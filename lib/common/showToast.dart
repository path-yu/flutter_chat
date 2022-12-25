import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

showToast(String message) {
  Fluttertoast.showToast(
      msg: message,
      fontSize: 16.0,
      webBgColor: "rgba(0,0,0,.8)",
      textColor: Colors.white,
      timeInSecForIosWeb: 2,
      gravity: ToastGravity.CENTER,
      webPosition: 'center');
}
