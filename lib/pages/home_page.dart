import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/components/color.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/pages/components/home/home_contacts.dart';
import 'package:flutter_chat/pages/components/home/home_messages.dart';
import 'package:badges/badges.dart';
import 'package:flutter_chat/provider/current_user.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  int newFriendsBadgeCount = 0;

  void handleOnTap(int? index) {
    setState(() {
      currentIndex = index!;
    });
    var currentUser = FirebaseAuth.instance.currentUser!;
    // listener add contact notification
    db
        .collection(NOTIFICATION)
        .where('targetEmail', isEqualTo: currentUser.email)
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
    db
        .collection(UsersDbKey)
        .doc(getCurrentUser().uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        var data = doc.data()!;
        context.read<CurrentUser>().setCurrentUser(data);
      }
    });
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
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
    Widget currentPage;

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        items: bottomTabsList,
        selectedItemColor: primaryColor,
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
