import 'package:flutter/material.dart';

class ComparisonScreen extends StatelessWidget {
  final String childId;
  final String wordId;

  const ComparisonScreen({
    super.key,
    required this.childId,
    required this.wordId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المقارنة')),
      body: const Center(child: Text('Comparison Screen - Coming Soon')),
    );
  }
}
