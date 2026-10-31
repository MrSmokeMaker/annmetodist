import 'package:flutter/material.dart';
import '../widgets/depth_card.dart';
import '../widgets/primary_button.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Библиотека')), 
      body: Center(
        child: DepthCard(
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Список конспектов будет здесь'),
          ),
        ),
      ),
    );
  }
}
