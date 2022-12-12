import 'package:flutter/material.dart';
import 'package:flutter_chat/components/common.dart';

class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Add contact page', context),
      body: const Center(
        child: Text('add contact page'),
      ),
    );
  }
}
