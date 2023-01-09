import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/common/defaultData.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/provider/current_user.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

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

  signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    FirebaseAuth.instance
        .signInWithCredential(credential)
        .then((userCredential) async {
      var user = await searchUserByEmail(userCredential.user!.email!);

      if (user.docs.isEmpty) {
        saveUser(userCredential);
        showMessage(context: context, title: 'login successful');
      } else {
        // ignore: use_build_context_synchronously
        context.read<CurrentUser>().setCurrentUser(user.docs[0].data());
      }
      Navigator.pushNamed(context, '/');
    });
  }

  void saveUser(userCredential) {
    var defaultUserName = 'user-${userCredential.user!.email!}';

    // save userData
    var data = {
      'email': userCredential.user!.email,
      'photoURL': userCredential.user!.email,
      'suggest': defaultSuggest,
      'createTime': DateTime.now().millisecondsSinceEpoch,
      'contacts': [],
      'lastLoginTime': DateTime.now().millisecondsSinceEpoch,
      'online': true,
      'userName': defaultUserName,
      'uid': userCredential.user!.uid,
      'chats': []
    };
    db.collection(UsersDbKey).doc(userCredential.user!.uid).set(data);
  }

  void signWithGithub() {
    GithubAuthProvider githubProvider = GithubAuthProvider();

    try {
      FirebaseAuth.instance
          .signInWithProvider(githubProvider)
          .then((userCredential) async {
        var user = await searchUserByEmail(userCredential.user!.email!);
        if (user.docs.isEmpty) {
          // saveUser(userCredential);
          showMessage(context: context, title: 'login successful');
        } else {
          // ignore: use_build_context_synchronously
          // context.read<CurrentUser>().setCurrentUser(user.docs[0].data());
        }
        Navigator.pushNamed(context, '/');
      });
    } catch (e) {}
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
                              }
                            },
                      child: loginButtonLoading
                          ? buttonLoading
                          : const Text('Sign in'))),
              FractionallySizedBox(
                widthFactor: 1,
                child: ElevatedButton(
                  onPressed: signInWithGoogle,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.google,
                        size: 15,
                      ),
                      SizedBox(
                        width: ScreenUtil().setWidth(5),
                      ),
                      const Text('Sign in with goggle')
                    ],
                  ),
                ),
              ),
              // FractionallySizedBox(
              //   widthFactor: 1,
              //   child: ElevatedButton(
              //     onPressed: signWithGithub,
              //     child: Row(
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       children: [
              //         const FaIcon(
              //           FontAwesomeIcons.github,
              //           size: 15,
              //         ),
              //         SizedBox(
              //           width: ScreenUtil().setWidth(5),
              //         ),
              //         const Text('Sign in with github')
              //       ],
              //     ),
              //   ),
              // ),
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
