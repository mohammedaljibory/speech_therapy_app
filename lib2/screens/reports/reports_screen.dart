import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/themes.dart';
import '../../providers/evaluation_provider.dart';
import '../../widgets/common/custom_button.dart';

class ReportsScreen extends StatefulWidget {
  final String? childId;

  const ReportsScreen({super.key, this.childId});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedType = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0FFF0), Color(0xFFFFFBF5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildFilters(),
              Expanded(
                child: _buildReportsList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: GradientFAB(
        icon: Icons.add,
        onPressed: () {
          _showGenerateReportDialog();
        },
        gradient: AppColors.gradientSuccess,
        tooltip: 'إنشاء تقرير',
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CustomIconButton(
            icon: Icons.arrow_forward,
            onPressed: () => Navigator.pop(context),
            backgroundColor: Colors.white,
          ),
          const SizedBox(width: 16),
          Text(
            'التقارير',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildFilters() {
    final filters = [
      {'id': 'all', 'label': 'الكل'},
      {'id': 'daily', 'label': 'يومي'},
      {'id': 'weekly', 'label': 'أسبوعي'},
      {'id': 'monthly', 'label': 'شهري'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedType == filter['id'];
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilterChip(
                label: Text(filter['label']!),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedType = filter['id']!);
                },
                selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                checkmarkColor: AppColors.primaryGreen,
              ),
            );
          }).toList(),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildReportsList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.assessment,
              size: 60,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد تقارير بعد',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'قم بإنشاء تقرير جديد',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'إنشاء تقرير',
            icon: Icons.add,
            gradient: AppColors.gradientSuccess,
            onPressed: _showGenerateReportDialog,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  void _showGenerateReportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إنشاء تقرير جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.today),
                title: const Text('تقرير يومي'),
                onTap: () {
                  Navigator.pop(context);
                  // Generate daily report
                },
              ),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text('تقرير أسبوعي'),
                onTap: () {
                  Navigator.pop(context);
                  // Generate weekly report
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('تقرير شهري'),
                onTap: () {
                  Navigator.pop(context);
                  // Generate monthly report
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
