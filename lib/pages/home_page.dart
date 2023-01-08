import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/eventBus/index.dart';
import 'package:flutter_chat/pages/components/home/home_contacts.dart';
import 'package:flutter_chat/pages/components/home/home_messages.dart';
import 'package:badges/badges.dart';
import 'package:flutter_chat/provider/current_user.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int currentIndex = 0;
  int newFriendsBadgeCount = 0;
  int newMessageCount = 0;

  var _sub;
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
    initUniLinks();
  }

  Future<void> initUniLinks() async {
    print('init');
    // ... check initialLink

    // Attach a listener to the stream
    _sub = linkStream.listen((String? link) {
      print('openAPPPPP');
      print(link);
      // Parse the link and warn the user, if it is not correct
    }, onError: (err) {
      // Handle exception by warning the user their action did not succeed
    });

    // NOTE: Don't forget to call _sub.cancel() in dispose()
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
