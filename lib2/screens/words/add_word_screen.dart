import 'package:flutter/material.dart';

class AddWordScreen extends StatelessWidget {
  final String? categoryId;

  const AddWordScreen({super.key, this.categoryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة كلمة')),
      body: const Center(child: Text('Add Word Screen - Coming Soon')),
    );
  }
}
