import 'package:flutter/material.dart';
import 'package:flutter_chat/components/color.dart';
import 'package:flutter_chat/pages/components/home/home_contacts.dart';
import 'package:flutter_chat/pages/components/home/home_messages.dart';

class HomePage extends StatefulWidget {
  //
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final tabsList = [
    const HomeMessages(),
    const HomeContacts(),
  ];
  //
  int currentIndex = 1;
  late Widget currentPage = tabsList[1];
  DateTime? _lastQuitTime;
  final List<BottomNavigationBarItem> bottomTabsList = [
    const BottomNavigationBarItem(
        icon: Icon(
          Icons.chat,
        ),
        label: 'Messages'),
    const BottomNavigationBarItem(
        icon: Icon(
          Icons.people,
        ),
        label: 'Contacts'),
  ];
  @override
  Widget build(BuildContext context) {
    //
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        items: bottomTabsList,
        selectedItemColor: primaryColor,
        onTap: (index) {
          setState(() {
            currentIndex = index;
            currentPage = tabsList[currentIndex];
          });
        },
      ),
      body: currentPage,
    );
  }
}
