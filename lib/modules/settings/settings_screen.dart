import 'package:flutter/material.dart';

/// SettingsScreen — stub screen for the Settings module.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
