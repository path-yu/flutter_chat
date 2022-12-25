import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/provider/current_brightness.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Setting page', context),
      body: SettingsList(
        contentPadding: EdgeInsets.all(ScreenUtil().setWidth(15)),
        sections: [
          SettingsSection(
            title: Text('theme'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: Icon(Icons.brightness_6_outlined),
                title: Text('brightness'),
                value: Text(context.watch<CurrentBrightness>().brightness),
                onPressed: (_) async {
                  var brightnessKey =
                      context.read<CurrentBrightness>().brightnessKey;
                  var result = await showConfirmationDialog(
                      title: 'select mode ',
                      context: context,
                      initialSelectedActionKey: brightnessKey,
                      actions: [
                        const AlertDialogAction(
                          label: 'follow system',
                          key: 0,
                        ),
                        const AlertDialogAction(
                          label: 'dark',
                          key: 1,
                        ),
                        const AlertDialogAction(
                          label: 'light',
                          key: 2,
                        ),
                      ]);
                  context.read<CurrentBrightness>().changeBrightness(result == 0
                      ? 'system'
                      : result == 1
                          ? 'dark'
                          : 'light');
                },
              ),
            ],
          ),
          SettingsSection(
            title: Text('account'),
            tiles: <SettingsTile>[
              SettingsTile(
                title: Text('Sign out'),
                leading: const Icon(Icons.logout),
                onPressed: (_) {
                  FirebaseAuth.instance.signOut().then((value) {
                    Navigator.popAndPushNamed(context, '/login',
                        arguments: true);
                  });
                },
              )
            ],
          ),
        ],
      ),
    );
  }
}
