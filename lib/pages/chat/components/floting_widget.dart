import 'package:flutter/material.dart';

class FloatingWidget extends StatelessWidget {
  const FloatingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      right: 20,
      child: Container(
        width: 100,
        height: 100,
        color: Colors.red,
        child: const Center(
          child: Text(
            'Floating Widget',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
