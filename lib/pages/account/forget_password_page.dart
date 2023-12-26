import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/common/show_toast.dart';
import 'package:flutter_chat/components/base_text_form_filed.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  State<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  resetPassword() async {
    if (email.isEmpty) {
      return showToast('Email is not empty!');
    }
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: email)
          .then((value) {
        showToast('Mail sent successfully');
      });
    } on FirebaseAuthException catch (e) {
      showOkAlertDialog(context: context, message: e.message!);
    }
  }

  String email = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Forget password', context),
      body: Center(
          child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'We need to verify your email',
            style: TextStyle(
                fontSize: ScreenUtil().setSp(18), fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: ScreenUtil().setHeight(20),
          ),
          FractionallySizedBox(
            widthFactor: 0.8,
            child: BaseTextFormFiled(
              obscureText: false,
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) {
                email = value!;
              },
              hintText: 'Your email',
            ),
          ),
          SizedBox(
            height: ScreenUtil().setHeight(15),
          ),
          FractionallySizedBox(
            widthFactor: 0.8,
            child: ElevatedButton(
                onPressed: resetPassword, child: const Text('Send request')),
          )
        ],
      )),
    );
  }
}
