import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/depth_card.dart';
import '../widgets/primary_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metodist Desktop'),
        actions: const [ThemeSwitcher()],
      ),
      body: Center(
        child: DepthCard(
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Добро пожаловать!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Создать урок',
                  onTap: () {
                    // TODO: open creation sheet
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
