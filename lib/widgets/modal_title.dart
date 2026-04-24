import 'package:flutter/material.dart';

class ModalTitle extends StatelessWidget {
  final String text;
  const ModalTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight(700),
        fontSize: 20,
      ),
    );
  }
}
