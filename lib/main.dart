import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Forwarder',
      home: Scaffold(
        appBar: AppBar(title: const Text('SMS Forwarder')),
        body: const Center(child: Text('Hello, it builds!')),
      ),
    );
  }
}
