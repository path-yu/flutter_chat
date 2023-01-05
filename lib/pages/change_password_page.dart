import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/components/base_text_form_filed.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  bool btnLoading = false;

  void handleSendClick() async {
    final authCredential = EmailAuthProvider.credentialWithLink(
        email: getCurrentUser().email!,
        emailLink:
            'https://firebase.google.com/docs/auth/flutter/email-link-auth?hl=zh&authuser=0#linkingre-authentication_with_email_link');
    try {
      await FirebaseAuth.instance.currentUser!
          .sendEmailVerification()
          .then((value) => {print('success')});
    } catch (error) {
      print("Error reauthenticating credential.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Change password', context),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(20)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              const Text('We need to verify your email '),
              SizedBox(
                height: ScreenUtil().setHeight(10),
              ),
              BaseTextFormFiled(
                initialValue: getCurrentUser().email,
                onChanged: (value) {},
                hintText: 'your email address',
              ),
              SizedBox(
                height: ScreenUtil().setHeight(40),
              ),
              FractionallySizedBox(
                  widthFactor: 0.8,
                  child: ElevatedButton(
                      onPressed: handleSendClick,
                      child: btnLoading ? buttonLoading : const Text('Send')))
            ],
          ),
        ),
      ),
    );
  }
}
