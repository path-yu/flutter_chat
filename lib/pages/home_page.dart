import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/eventBus/index.dart';
import 'package:flutter_chat/pages/components/home/home_contacts.dart';
import 'package:flutter_chat/pages/components/home/home_messages.dart';
import 'package:badges/badges.dart';
import 'package:flutter_chat/provider/current_brightness.dart';
import 'package:flutter_chat/provider/current_user.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int currentIndex = 0;
  int newFriendsBadgeCount = 0;
  int newMessageCount = 0;
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
    // listener add contact notification
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

    window.onPlatformBrightnessChanged = () {
      if (context.read<CurrentBrightness>().brightness == 'system') {
        context
            .read<CurrentBrightness>()
            .changeSystemBrightness(window.platformBrightness);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final List<BottomNavigationBarItem> bottomTabsList = [
      const BottomNavigationBarItem(
          icon: Icon(Icons.message), label: 'Messages'),
      BottomNavigationBarItem(
          icon: newFriendsBadgeCount != 0
              ? Badge(
                  badgeContent: Text(
                    '$newFriendsBadgeCount',
                    style: const TextStyle(color: Colors.white),
                  ),
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
          const HomeMessages(),
          HomeContacts(
            hasNewFriends: newFriendsBadgeCount != 0,
          ),
        ],
      ),
    );
  }
}
