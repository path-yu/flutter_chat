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

  String email = '1974675011@qq.com';
  String password = '123456';
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
    return WillPopScope(
      onWillPop: () async {
        if (args != null) {
          return false;
        }
        return true;
      },
      child: Scaffold(
          appBar: buildAppBar('Welcome to login', context,
              showBackButton:
                  args != null ? false : Navigator.of(context).canPop()),
          body: Container(
            color: Colors.white54,
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
                            return 'please enter a valid email address';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                            suffixIcon: email.isNotEmpty
                                ? buildClearInputIcon((() {
                                    _emailController.clear();
                                  }))
                                : null,
                            hintText: 'please input your email',
                            prefixIcon: buildIcon(Icons.email)),
                      ),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'please input your password';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                            suffixIcon: password.isNotEmpty
                                ? buildClearInputIcon((() {
                                    _passwordController.clear();
                                  }))
                                : null,
                            hintText: 'please input your password',
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
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  setState(() => loginButtonLoading = true);
                                  FirebaseAuth.instance
                                      .signInWithEmailAndPassword(
                                          email: email, password: password)
                                      .then((value) {
                                    showMessage(
                                        context: context, title: '登录成功');
                                    Navigator.pushNamed(context, '/');
                                  }).onError((error, stackTrace) {
                                    showMessage(
                                        context: context,
                                        title: error.toString(),
                                        type: 'danger');
                                  }).whenComplete(() => setState(
                                          () => loginButtonLoading = false));
                                }
                              },
                        child: loginButtonLoading
                            ? buttonLoading
                            : const Text('Sign in'))),
                SizedBox(
                  height: ScreenUtil().setHeight(10),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('not yet registered?'),
                    TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text('Click to register'))
                  ],
                )
              ],
            ),
          )),
    );
  }
}
