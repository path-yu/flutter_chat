import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/components/base_text_form_filed.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/components/hide_key_bord.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  bool btnLoading = false;
  var oldPassword = "";
  var newPassword = "";
  final _formKey = GlobalKey<FormState>();

  void handleConfirmClick() async {
    var user = getCurrentUser();
    if (_formKey.currentState!.validate()) {
      setState(() {
        btnLoading = true;
      });
      try {
        await FirebaseAuth.instance.currentUser!.reauthenticateWithCredential(
            EmailAuthProvider.credential(
                email: user.email!, password: oldPassword));
        await FirebaseAuth.instance.currentUser?.updatePassword(newPassword);
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: user.email!, password: newPassword);
        showMessage(context: context, title: 'Change success');
        setState(() {
          btnLoading = false;
        });
        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        showMessage(context: context, title: e.message.toString());
        setState(() {
          btnLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return HideKeyboard(
      child: Scaffold(
        appBar: buildAppBar('Change password', context),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(20)),
          child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  BaseTextFormFiled(
                    prefixIcon: Icons.lock_open,
                    obscureText: true,
                    onChanged: (value) {
                      oldPassword = value!;
                    },
                    validator: (value) {
                      if (value!.isEmpty || value.length < 6) {
                        return 'Password should be at least 6 characters';
                      }
                      return null;
                    },
                    hintText: 'old password',
                  ),
                  BaseTextFormFiled(
                    prefixIcon: Icons.lock,
                    obscureText: true,
                    onChanged: (value) {
                      newPassword = value!;
                    },
                    validator: (value) {
                      if (value!.isEmpty || value.length < 6) {
                        return 'Password should be at least 6 characters';
                      }
                      return null;
                    },
                    hintText: 'your new password',
                  ),
                  SizedBox(
                    height: ScreenUtil().setHeight(40),
                  ),
                  FractionallySizedBox(
                      widthFactor: 0.8,
                      child: ElevatedButton(
                          onPressed: handleConfirmClick,
                          child: btnLoading
                              ? buttonLoading
                              : const Text('Confirm')))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
