// ignore_for_file: use_build_context_synchronously

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/eventBus/index.dart';
import 'package:flutter_chat/provider/current_brightness.dart';
import 'package:flutter_chat/provider/current_chat_setting.dart';
import 'package:flutter_chat/provider/current_primary_swatch.dart';
import 'package:flutter_chat/provider/current_switch.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  Color? screenPickerColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Settings', context),
      body: SettingsList(
        platform: DevicePlatform.iOS,
        sections: [
          SettingsSection(
            title: const Text('Theme'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.brightness_6_outlined),
                title: const Text('Brightness'),
                value: Text(context.watch<CurrentBrightness>().brightness),
                onPressed: (_) async {
                  var brightnessKey =
                      context.read<CurrentBrightness>().brightnessKey;
                  var result = await showConfirmationDialog(
                      barrierDismissible: false,
                      fullyCapitalizedForMaterial: false,
                      title: 'Select mode ',
                      context: context,
                      cancelLabel: 'Cancel',
                      okLabel: 'Ok',
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
              SettingsTile.switchTile(
                onToggle: (value) {
                  context.read<CurrentSwitch>().changeUseMaterial3(value);
                },
                initialValue: context.watch<CurrentSwitch>().useMaterial3,
                leading: const Icon(
                  Icons.design_services,
                ),
                title: const Text('UseMaterial3'),
              ),
              SettingsTile.navigation(
                leading: const Icon(
                  Icons.color_lens,
                ),
                title: const Text('Theme color'),
                value: Text(context.watch<CurrentPrimarySwatch>().colorName),
                onPressed: (context) async {
                  await showBaseAlertDialog(
                    contentWidget: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ColorPicker(
                          // Use the screenPickerColor as start color.
                          color: Color(
                              context.read<CurrentPrimarySwatch>().color.value),
                          // Update the screenPickerColor using the callback.
                          onColorChanged: (Color color) {
                            screenPickerColor = color;
                          },
                          pickersEnabled: const {ColorPickerType.accent: false},
                          width: 45,
                          height: 45,
                          showMaterialName: true,
                          heading: Text(
                            'Select color',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          subheading: Text(
                            'Select color shade',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    onConfirm: () {
                      if (screenPickerColor != null) {
                        context
                            .read<CurrentPrimarySwatch>()
                            .changeColor(screenPickerColor!);
                        Navigator.pop(context);
                      }
                    },
                  );
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text('Account'),
            tiles: <SettingsTile>[
              SettingsTile(
                title: const Text('Sign out'),
                leading: const Icon(Icons.logout),
                onPressed: (_) async {
                  var result = await showOkCancelAlertDialog(
                      fullyCapitalizedForMaterial: false,
                      context: context,
                      title: 'Are you sure to exit?');
                  if (result == OkCancelResult.ok) {
                    eventBus.fire(CloseSocketEvent());
                    FirebaseAuth.instance.signOut().then((value) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (route) => false);
                    });
                  }
                },
              ),
              SettingsTile(
                title: const Text('Change password'),
                leading: const Icon(Icons.lock),
                onPressed: (_) {
                  Navigator.pushNamed(context, '/changePassword',
                      arguments: true);
                },
              )
            ],
          ),
          SettingsSection(title: const Text('Notifications'), tiles: [
            SettingsTile.switchTile(
              onToggle: (value) {
                context
                    .read<CurrentChatSetting>()
                    .changeOpenNotification(value);
              },
              initialValue:
                  context.watch<CurrentChatSetting>().openNotification,
              leading: Icon(
                context.watch<CurrentChatSetting>().openNotification
                    ? Icons.notification_add
                    : Icons.notifications_off,
              ),
              title: const Text('Turn on message notifications'),
            ),
            SettingsTile.switchTile(
              onToggle: (value) {
                context
                    .read<CurrentChatSetting>()
                    .changeOpenNotificationSound(value);
              },
              initialValue:
                  context.watch<CurrentChatSetting>().openNotificationSound,
              leading: Icon(
                context.watch<CurrentChatSetting>().openNotificationSound
                    ? Icons.music_note_outlined
                    : Icons.music_off_outlined,
              ),
              title: const Text('Turn on notification sound'),
            ),
          ])
        ],
      ),
    );
  }
}
