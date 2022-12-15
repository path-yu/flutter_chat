import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/components/color.dart';
import 'package:flutter_chat/pages/components/home/home_contacts.dart';
import 'package:flutter_chat/pages/components/home/home_messages.dart';
import 'package:badges/badges.dart';
import 'package:flutter_chat/provider/current_user.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

class HomePage extends HookWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentIndex = useState(0);

    final newFriendsBadgeCount = useState(0);
    Widget currentPage;
    if (currentIndex.value == 1) {
      currentPage = HomeContacts(
        hasNewFriends: newFriendsBadgeCount.value != 0,
      );
    } else {
      currentPage = const HomeMessages();
    }
    num count = newFriendsBadgeCount.value;

    useEffect(() {
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
          newFriendsBadgeCount.value = querySnapshot.docs
              .where((element) {
                return element.data()['status'] == 'pending';
              })
              .toList()
              .length;
        }
      });
      db
          .collection(UsersDbKey)
          .doc(getCurrentUser().uid)
          .snapshots()
          .listen((doc) {
        if (doc.exists) {
          var data = doc.data()!;
          context.read<CurrentUser>().setCurrentUser(MyUser.fromJson(data));
        }
      });
      return null;
    }, []);
    final List<BottomNavigationBarItem> bottomTabsList = [
      const BottomNavigationBarItem(
          icon: Icon(Icons.message), label: 'Messages'),
      BottomNavigationBarItem(
          icon: newFriendsBadgeCount.value != 0
              ? Badge(
                  badgeContent: Text(
                    '$count',
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
        currentIndex: currentIndex.value,
        items: bottomTabsList,
        selectedItemColor: primaryColor,
        onTap: (index) {
          currentIndex.value = index;
        },
      ),
      body: currentPage,
    );
  }
}
