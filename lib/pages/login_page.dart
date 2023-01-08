import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../components/common.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String email = '';
  String password = '';
  bool loginButtonLoading = false;

  @override
  // 覆写`wantKeepAlive`返回`true`
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _emailController.text = email;
    _passwordController.text = password;
    _emailController.addListener(() {
      setState(() => email = _emailController.text);
    });
    _passwordController.addListener(() {
      setState(() => password = _passwordController.text);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final args = ModalRoute.of(context)!.settings.arguments;

    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: buildAppBar('Welcome to login', context,
            showBackButton: Navigator.of(context).canPop()),
        body: Container(
          padding: EdgeInsets.all(ScreenUtil().setWidth(20)),
          margin: EdgeInsets.only(top: ScreenUtil().setHeight(20)),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      validator: (value) {
                        if (value!.isEmpty || !value.contains('@')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                          suffixIcon: email.isNotEmpty
                              ? buildClearInputIcon((() {
                                  _emailController.clear();
                                }))
                              : null,
                          hintText: 'type email',
                          prefixIcon: buildIcon(Icons.email)),
                    ),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      validator: (value) {
                        if (value!.isEmpty || value.length < 6) {
                          return 'Password should be at least 6 characters';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                          suffixIcon: password.isNotEmpty
                              ? buildClearInputIcon((() {
                                  _passwordController.clear();
                                }))
                              : null,
                          hintText: ' type password',
                          prefixIcon: buildIcon(Icons.lock)),
                    ),
                  ],
                ),
              ),
              Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: ScreenUtil().setWidth(20)),
                  child: ElevatedButton(
                      onPressed: loginButtonLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => loginButtonLoading = true);
                                try {
                                  await FirebaseAuth.instance
                                      .signInWithEmailAndPassword(
                                          email: email, password: password);
                                  showMessage(
                                      context: context,
                                      title: 'login successful');
                                  Navigator.pushNamed(context, '/');
                                } on FirebaseAuthException catch (e) {
                                  showOkAlertDialog(
                                      context: context, message: e.message!);
                                }
                                setState(() => loginButtonLoading = false);
                                setState(() => loginButtonLoading = false);
                              }
                            },
                      child: loginButtonLoading
                          ? buttonLoading
                          : const Text('Sign in'))),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: 0.6,
                    child: Text('not yet registered?',
                        style: TextStyle(fontSize: ScreenUtil().setSp(12))),
                  ),
                  TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: Text(
                        'Click to register',
                        style: TextStyle(fontSize: ScreenUtil().setSp(12)),
                      ))
                ],
              ),
              TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forget');
                  },
                  child: Text(
                    'Forget password',
                    style: TextStyle(fontSize: ScreenUtil().setSp(12)),
                  )),
            ],
          ),
        ));
  }
}
