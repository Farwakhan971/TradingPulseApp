import 'package:flutter/material.dart';
class FullScreenImagePage extends StatelessWidget {
  final String imageUrl; // Define imageUrl as a String

  FullScreenImagePage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}
