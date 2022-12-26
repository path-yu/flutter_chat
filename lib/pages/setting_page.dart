import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/provider/current_brightness.dart';
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
      appBar: buildAppBar('Settings', context),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: const Text('theme'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.brightness_6_outlined),
                title: const Text('brightness'),
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
            title: const Text('account'),
            tiles: <SettingsTile>[
              SettingsTile(
                title: const Text('Sign out'),
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
