import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat/router/index.dart';
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
  runApp(const MyApp());
  // 以下两行 设置android状态栏为透明的沉浸。写在组件渲染之后，
  SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.blue,
  );
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
              theme: ThemeData(
                // is not restarted.
                primarySwatch: Colors.blue,
              ),
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
