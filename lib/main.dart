import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/components/color.dart';
import 'package:flutter_chat/provider/current_brightness.dart';
import 'package:flutter_chat/provider/current_user.dart';
import 'package:flutter_chat/router/index.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Global contentKey
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  var currentUser = CurrentUser();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? brightnessValue = prefs.getString('currentBrightness');
  if (FirebaseAuth.instance.currentUser != null) {
    searchUserByEmail(getCurrentUser().email!).then((user) {
      currentUser.setCurrentUser(user.docs[0].data());
    });
  }
  var currentBrightness =
      CurrentBrightness(brightnessValue ?? 'light', window.platformBrightness);
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => currentUser),
      ChangeNotifierProvider(create: (_) => currentBrightness),
    ],
    child: const MyApp(),
  ));
  SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  );
  window.onPlatformBrightnessChanged = () {
    if (navigatorKey.currentContext!.read<CurrentBrightness>().brightness ==
        'system') {
      navigatorKey.currentContext!
          .read<CurrentBrightness>()
          .changeSystemBrightness(window.platformBrightness);
    }
  };
  SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
              title: 'chatApp',
              navigatorKey: navigatorKey, // set property
              debugShowCheckedModeBanner: false,
              routes: baseRoutes,
              initialRoute: '/',
              builder: EasyLoading.init(),
              theme: ThemeData(
                  useMaterial3: true,
                  primarySwatch: primaryColor,
                  brightness: context.watch<CurrentBrightness>().value),
              onGenerateRoute: (RouteSettings settings) {
                // 检查路由是否需要拦截
                if (settings.name != '/login' || settings.name != 'register') {
                  // 检查用户是否已登录
                  var user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    // 如果用户未登录，跳转到登录页面
                    return getPage('/login', context);
                  } else {
                    // 如果用户已登录，继续导航
                    return getAuthPage(settings.name!, context);
                  }
                }
                // 否则直接跳转到登录或注册
                return getPage(settings.name!, context);
              });
        });
  }
}
