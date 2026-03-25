import 'package:flutter/material.dart';

class OutlamaApp extends StatelessWidget {
  const OutlamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Outlama',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B5FFF)),
        useMaterial3: true,
      ),
      home: const Placeholder(),
    );
  }
}
