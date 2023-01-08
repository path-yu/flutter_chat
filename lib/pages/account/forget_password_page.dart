import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/common/showToast.dart';
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
    await FirebaseAuth.instance
        .sendPasswordResetEmail(email: email)
        .then((value) {
      showToast('Mail sent successfully');
    });
  }

  String email = '1974675011@qq.com';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Forget password', context),
      body: Center(
          child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'We need to verify your email',
          ),
          SizedBox(
            height: ScreenUtil().setHeight(20),
          ),
          FractionallySizedBox(
            widthFactor: 0.8,
            child: BaseTextFormFiled(
              prefixIcon: Icons.lock,
              obscureText: true,
              onChanged: (value) {
                email = value!;
              },
              validator: (value) {
                if (value!.isEmpty || value.length < 6) {
                  return 'Password should be at least 6 characters';
                }
                return null;
              },
              hintText: 'your email',
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
