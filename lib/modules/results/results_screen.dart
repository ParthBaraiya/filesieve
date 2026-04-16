import 'package:flutter/material.dart';

/// ResultsScreen — stub screen for the Results module.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Results',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
