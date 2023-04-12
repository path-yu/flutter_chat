import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/common/defaultData.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/provider/current_user.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    try {
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
      EasyLoading.show(
          status: 'loading...', maskType: EasyLoadingMaskType.black);
      // Once signed in, return the UserCredential
      var userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      var user = await searchUserByEmail(userCredential.user!.email!);

      if (user.docs.isEmpty) {
        saveUser(userCredential);
      } else {
        // ignore: use_build_context_synchronously
        context.read<CurrentUser>().setCurrentUser(user.docs[0].data());
      }
      showMessage(context: context, title: 'login successful');
      Navigator.pushNamed(context, '/');
      EasyLoading.dismiss();
    } on FirebaseAuthException catch (e) {
      EasyLoading.dismiss();
      showOkAlertDialog(context: context, message: e.message!);
    }
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
    context.read<CurrentUser>().setCurrentUser(data);
  }

  void signWithGithub() async {
    EasyLoading.show(status: 'loading...', maskType: EasyLoadingMaskType.black);
    try {
      GithubAuthProvider githubProvider = GithubAuthProvider();

      var userCredential =
          await FirebaseAuth.instance.signInWithProvider(githubProvider);
      var user = await searchUserByEmail(userCredential.user!.email!);
      if (user.docs.isEmpty) {
        saveUser(userCredential);
      } else {
        // ignore: use_build_context_synchronously
        context.read<CurrentUser>().setCurrentUser(user.docs[0].data());
      }
      showMessage(context: context, title: 'login successful');
      Navigator.pushNamed(context, '/');
      EasyLoading.dismiss();
    } on FirebaseAuthException catch (e) {
      print(e);
      EasyLoading.dismiss();
      showOkAlertDialog(context: context, message: e.message!);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final args = ModalRoute.of(context)!.settings.arguments;
    final Widget svg = SvgPicture.asset(
      'assets/google_icon.svg',
      width: 20,
      height: 20,
    );
    final Widget githubSvg = SvgPicture.asset(
      'assets/github_icon.svg',
      width: 20,
      height: 20,
    );
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: buildAppBar('Welcome to login', context,
            showBackButton: Navigator.of(context).canPop()),
        body: Container(
          padding: EdgeInsets.all(ScreenUtil().setWidth(30)),
          margin: EdgeInsets.only(top: ScreenUtil().setHeight(20)),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
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
                          hintText: 'Type email',
                          prefixIcon: buildIcon(Icons.email)),
                    ),
                    TextFormField(
                      controller: _passwordController,
                      keyboardType: TextInputType.visiblePassword,
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
                          hintText: 'Type password',
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
              SizedBox(
                height: ScreenUtil().setHeight(10),
              ),
              FractionallySizedBox(
                widthFactor: 1,
                child: ElevatedButton(
                  onPressed: signInWithGoogle,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      svg,
                      SizedBox(
                        width: ScreenUtil().setWidth(5),
                      ),
                      const Text('Sign in with goggle')
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: ScreenUtil().setHeight(10),
              ),
              FractionallySizedBox(
                widthFactor: 1,
                child: ElevatedButton(
                  onPressed: signWithGithub,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      githubSvg,
                      SizedBox(
                        width: ScreenUtil().setWidth(5),
                      ),
                      const Text('Sign in with github')
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: 0.6,
                    child: Text('not yet registered?',
                        style: TextStyle(fontSize: ScreenUtil().setSp(12))),
                  ),
                  TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(50, 20),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: Text(
                        'Click to register',
                        style: TextStyle(fontSize: ScreenUtil().setSp(12)),
                      ))
                ],
              ),
              Transform.translate(
                offset: const Offset(0, -6),
                child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(50, 20),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/forget');
                    },
                    child: Text(
                      'Forget password',
                      style: TextStyle(fontSize: ScreenUtil().setSp(12)),
                    )),
              ),
            ],
          ),
        ));
  }
}
