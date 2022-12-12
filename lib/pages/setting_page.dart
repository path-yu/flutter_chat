import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/components/common.dart';

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
      body: ListView(
        children: [
          ListTile(
            onTap: () {
              FirebaseAuth.instance.signOut().then((value) {
                showMessage(context: context, title: 'success');
                Navigator.popAndPushNamed(context, '/login', arguments: true);
              });
            },
            title: const Text('Exit login'),
          )
        ],
      ),
    );
  }
}
