import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/main.dart';
import 'package:flutter_chat/pages/chat_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> initNotification() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  var result = await AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      null,
      [
        NotificationChannel(
            channelGroupKey: 'basic_channel_group',
            channelKey: 'basic_channel',
            channelName: packageInfo.appName,
            channelDescription: 'ChatApp notification description',
            defaultColor: const Color(0xFF9D50DD),
            ledColor: Colors.white)
      ],
      debug: true);
  return result;
}

void setNotificationListener() {
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: (ReceivedAction receivedAction) async {
      if (receivedAction.category == NotificationCategory.Message) {
        var chatId = receivedAction.payload!['chatId'];
        var data =
            await db.collection(ChatsKey).where('id', isEqualTo: chatId).get();
        var chatData = await handleChatData(data);
        SharedPreferences.getInstance().then((prefs) {
          var offset = prefs.getString(chatId!);
          Navigator.push(
            navigatorKey.currentState!.context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                parentChatData: chatData,
                notificationId: receivedAction.payload!['localNotificationId'],
                initialScrollOffset: offset != null ? double.parse(offset) : 0,
              ),
            ),
          );
        });
      }

      // navigatorKey.currentState?.pushNamedAndRemoveUntil(
      //     '/chat', (route) => (route.settings.name != '/chat') || route.isFirst,
      //     arguments: receivedAction);
    },
  );
}

void addNotification(
    String body, Map<String, String?>? payload, int notificationId) {
  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      // This is just a basic example. For real apps, you must show some
      // friendly dialog box before call the request method.
      // This is very important to not harm the user experience
      AwesomeNotifications().requestPermissionToSendNotifications();
    } else {
      AwesomeNotifications().createNotification(
          content: NotificationContent(
              id: notificationId,
              channelKey: 'basic_channel',
              title: 'ChatApp',
              body: body,
              payload: payload,
              category: NotificationCategory.Message,
              actionType: ActionType.Default));
    }
  });
}
