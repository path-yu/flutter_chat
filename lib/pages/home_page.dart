import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/eventBus/index.dart';
import 'package:flutter_chat/pages/components/home/home_contacts.dart';
import 'package:flutter_chat/pages/components/home/home_messages.dart';
import 'package:flutter_chat/provider/current_user.dart';
import 'package:flutter_chat/utils/notification.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int currentIndex = 0;
  int newFriendsBadgeCount = 0;
  // int newMessageCount = 0;
  Map messageNotificationMaps = {};

  int get newMessageCount {
    return messageNotificationMaps.values.fold(0, (previousValue, element) {
      int count = element['count'];
      return previousValue + count;
    });
  }

  void handleOnTap(int? index) {
    setState(() {
      currentIndex = index!;
    });
  }

  @override
  void initState() {
    super.initState();
    db
        .collection(UsersDbKey)
        .doc(getCurrentUser().uid)
        .snapshots()
        .listen((doc) {
      var data = doc.data()!;
      context.read<CurrentUser>().setCurrentUser(data);
      eventBus.fire(UserChangeEvent(data));
    });
    listenAddContactNotification();
    listenMessageNotification();
    setNotificationListener();
    print('init');
  }

  void listenAddContactNotification() {
    db
        .collection(NOTIFICATION)
        .where('targetEmail', isEqualTo: getCurrentUser().email)
        .where('type', isEqualTo: 'addContact')
        .snapshots()
        .listen((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        // filter pending
        setState(() {
          newFriendsBadgeCount = querySnapshot.docs
              .where((element) {
                return element.data()['status'] == 'pending';
              })
              .toList()
              .length;
        });
      }
    });
  }

  void listenMessageNotification() {
    db
        .collection(NOTIFICATION)
        .where('targetUid', isEqualTo: getCurrentUser().uid)
        .where('type', isEqualTo: 'newMessage')
        .snapshots()
        .listen((querySnapshot) {
      setState(() {
        for (var e in querySnapshot.docs) {
          var data = e.data();
          data['id'] = e.id;
          messageNotificationMaps[e['chatId']] = data;
          if (data['count'] != 0) {
            addNotification(
                '${data['userName']}:${data['count']} new messages',
                {'chatId': data['chatId'], 'notificationId': e.id},
                e['localNotificationId']);
          }
        }
      });
    });
  }
  // Future<void> initUniLinks() async {
  //   print('init');
  //   // ... check initialLink

  //   // Attach a listener to the stream
  //   _sub = linkStream.listen((String? link) {
  //     print('openAPPPPP');
  //     print(link);
  //     // Parse the link and warn the user, if it is not correct
  //   }, onError: (err) {
  //     // Handle exception by warning the user their action did not succeed
  //   });

  //   // NOTE: Don't forget to call _sub.cancel() in dispose()
  // }

  @override
  Widget build(BuildContext context) {
    final List<BottomNavigationBarItem> bottomTabsList = [
      BottomNavigationBarItem(
          label: 'Messages',
          icon: newMessageCount != 0
              ? Badge.count(
                  count: newMessageCount,
                  child: const Icon(Icons.message),
                )
              : const Icon(Icons.message)),
      BottomNavigationBarItem(
          icon: newFriendsBadgeCount != 0
              ? Badge.count(
                  count: newFriendsBadgeCount,
                  child: const Icon(Icons.people),
                )
              : const Icon(Icons.people),
          label: 'Contacts'),
    ];

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        items: bottomTabsList,
        onTap: handleOnTap,
      ),
      body: IndexedStack(
        index: currentIndex,
        children: [
          HomeMessages(
            messageNotificationMaps: messageNotificationMaps,
          ),
          HomeContacts(
            hasNewFriends: newFriendsBadgeCount != 0,
          ),
        ],
      ),
    );
  }
}
