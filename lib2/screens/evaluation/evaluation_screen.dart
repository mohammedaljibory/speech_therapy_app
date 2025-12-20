import 'package:flutter/material.dart';

class EvaluationScreen extends StatelessWidget {
  final String recordingId;
  final String childId;

  const EvaluationScreen({
    super.key,
    required this.recordingId,
    required this.childId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التقييم')),
      body: const Center(child: Text('Evaluation Screen - Coming Soon')),
    );
  }
}
