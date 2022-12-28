import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/common/defaultData.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/provider/current_user.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String email = '';
  String password = '';
  bool loginButtonLoading = false;
  @override
  void initState() {
    super.initState();
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
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar:
            buildAppBar('Welcome to register', context, showBackButton: true),
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
                          hintText: 'type password',
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
                                  var userCredential = await FirebaseAuth
                                      .instance
                                      .createUserWithEmailAndPassword(
                                          email: email, password: password);
                                  var defaultUserName = 'user-$email';

                                  FirebaseAuth.instance.currentUser!
                                      .updateDisplayName(defaultUserName);

                                  FirebaseAuth.instance.currentUser!
                                      .updatePhotoURL(defaultAvatar);
                                  // save userData
                                  var data = {
                                    'email': userCredential.user!.email,
                                    'photoURL': defaultAvatar,
                                    'suggest': defaultSuggest,
                                    'createTime':
                                        DateTime.now().millisecondsSinceEpoch,
                                    'contacts': [],
                                    'lastLoginTime':
                                        DateTime.now().millisecondsSinceEpoch,
                                    'online': true,
                                    'userName': defaultUserName,
                                    'uid': userCredential.user!.uid,
                                    'chats': []
                                  };
                                  db
                                      .collection(UsersDbKey)
                                      .doc(userCredential.user!.uid)
                                      .set(data);
                                  context
                                      .read<CurrentUser>()
                                      .setCurrentUser(data);
                                  showMessage(
                                      context: context,
                                      title:
                                          'register success, logging you in');
                                  FirebaseAuth.instance
                                      .signInWithEmailAndPassword(
                                          email: email, password: password)
                                      .then((value) {
                                    Navigator.pushNamed(context, '/');
                                  });
                                  setState(() => loginButtonLoading = false);
                                } on FirebaseException catch (e) {
                                  showMessage(
                                    context: context,
                                    title: e.message!,
                                  );
                                  setState(() => loginButtonLoading = false);
                                }
                              }
                            },
                      child: loginButtonLoading
                          ? buttonLoading
                          : const Text('Sign up'))),
            ],
          ),
        ));
  }
}
