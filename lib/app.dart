import 'package:flutter/material.dart';

class CodecoreApp extends StatelessWidget {
  const CodecoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Codecore',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const Scaffold(body: Center(child: Text('Codecore'))),
    );
  }
}
