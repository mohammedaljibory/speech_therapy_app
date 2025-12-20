import 'package:flutter/material.dart';

class ExportReportScreen extends StatelessWidget {
  final String childId;
  final String reportType;

  const ExportReportScreen({
    super.key,
    required this.childId,
    required this.reportType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تصدير التقرير')),
      body: const Center(child: Text('Export Report Screen - Coming Soon')),
    );
  }
}
