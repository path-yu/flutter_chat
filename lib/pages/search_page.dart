import 'package:flutter/material.dart';
import 'package:flutter_chat/components/common.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Search', context),
      body: const Center(
        child: Text('search page'),
      ),
    );
  }
}
