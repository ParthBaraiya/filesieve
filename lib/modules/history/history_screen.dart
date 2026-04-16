import 'package:flutter/material.dart';

/// HistoryScreen — stub screen for the History module.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'History',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
