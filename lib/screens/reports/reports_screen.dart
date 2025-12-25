import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../config/themes.dart';
import '../../config/routes.dart';
import '../../models/report_model.dart';
import '../../providers/evaluation_provider.dart';
import '../../providers/children_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';

class ReportsScreen extends StatefulWidget {
  final String? childId;

  const ReportsScreen({super.key, this.childId});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedType = 'all';
  bool _isLoading = true;
  String? _selectedChildId;

  @override
  void initState() {
    super.initState();
    _selectedChildId = widget.childId;
    _loadReports();
  }

  Future<void> _loadReports() async {
    if (_selectedChildId == null) {
      // If no child selected, get the first child
      final childrenProvider = context.read<ChildrenProvider>();
      final authProvider = context.read<AuthProvider>();

      if (authProvider.userId != null) {
        await childrenProvider.loadChildren(authProvider.userId!);
        if (childrenProvider.children.isNotEmpty) {
          _selectedChildId = childrenProvider.children.first.id;
        }
      }
    }

    if (_selectedChildId != null) {
      await context.read<EvaluationProvider>().loadReports(_selectedChildId!);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  List<ReportModel> get _filteredReports {
    final reports = context.watch<EvaluationProvider>().reports;
    if (_selectedType == 'all') return reports;
    return reports.where((r) => r.type == _selectedType).toList();
  }

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
              _buildChildSelector(),
              _buildFilters(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredReports.isEmpty
                        ? _buildEmptyState()
                        : _buildReportsList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: GradientFAB(
        icon: Icons.add,
        onPressed: _showGenerateReportDialog,
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
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_filteredReports.length} تقرير',
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildChildSelector() {
    return Consumer<ChildrenProvider>(
      builder: (context, provider, _) {
        if (provider.children.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedChildId,
                isExpanded: true,
                hint: const Text('اختر الطفل'),
                items: provider.children.map((child) {
                  return DropdownMenuItem(
                    value: child.id,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                          child: Text(
                            child.name[0],
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(child.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedChildId = value;
                    _isLoading = true;
                  });
                  _loadReports();
                },
              ),
            ),
          ),
        ).animate().fadeIn(delay: 50.ms);
      },
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
      padding: const EdgeInsets.all(20),
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

  Widget _buildEmptyState() {
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
            'قم بإنشاء تقرير جديد للطفل',
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

  Widget _buildReportsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredReports.length,
      itemBuilder: (context, index) {
        final report = _filteredReports[index];
        return _buildReportCard(report, index);
      },
    );
  }

  Widget _buildReportCard(ReportModel report, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToExport(report),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getTypeColor(report.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getTypeIcon(report.type),
                        color: _getTypeColor(report.type),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تقرير ${report.typeLabel}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            report.dateRangeString,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getLevelColor(report.metrics.overallLevel)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        report.metrics.overallLevel,
                        style: TextStyle(
                          color: _getLevelColor(report.metrics.overallLevel),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricItem(
                      'التسجيلات',
                      '${report.metrics.totalRecordings}',
                      Icons.mic,
                    ),
                    _buildMetricItem(
                      'الكلمات',
                      '${report.metrics.totalWords}',
                      Icons.text_fields,
                    ),
                    _buildMetricItem(
                      'الدقة',
                      '${report.metrics.averageAccuracy.toStringAsFixed(0)}%',
                      Icons.check_circle,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'تم الإنشاء: ${DateFormat('yyyy/MM/dd').format(report.generatedAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (report.isSent)
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 14, color: AppColors.primaryGreen),
                          const SizedBox(width: 4),
                          Text(
                            'تم الإرسال',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'daily':
        return AppColors.primaryBlue;
      case 'weekly':
        return AppColors.primaryPurple;
      case 'monthly':
        return AppColors.primaryOrange;
      default:
        return AppColors.primaryGreen;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'daily':
        return Icons.today;
      case 'weekly':
        return Icons.date_range;
      case 'monthly':
        return Icons.calendar_month;
      default:
        return Icons.assessment;
    }
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'ممتاز':
        return AppColors.primaryGreen;
      case 'جيد':
        return AppColors.primaryBlue;
      case 'متوسط':
        return AppColors.primaryOrange;
      default:
        return AppColors.error;
    }
  }

  void _navigateToExport(ReportModel report) {
    Navigator.pushNamed(
      context,
      Routes.exportReport,
      arguments: {
        'childId': _selectedChildId,
        'reportType': report.type,
      },
    );
  }

  void _showGenerateReportDialog() {
    if (_selectedChildId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار طفل أولاً')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_chart, color: AppColors.primaryGreen),
              ),
              const SizedBox(width: 12),
              const Text('إنشاء تقرير جديد'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildReportTypeOption(
                'تقرير يومي',
                'يعرض نشاط اليوم',
                Icons.today,
                AppColors.primaryBlue,
                'daily',
              ),
              const SizedBox(height: 8),
              _buildReportTypeOption(
                'تقرير أسبوعي',
                'يعرض نشاط الأسبوع',
                Icons.date_range,
                AppColors.primaryPurple,
                'weekly',
              ),
              const SizedBox(height: 8),
              _buildReportTypeOption(
                'تقرير شهري',
                'يعرض نشاط الشهر',
                Icons.calendar_month,
                AppColors.primaryOrange,
                'monthly',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportTypeOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String type,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _generateReport(type),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateReport(String type) async {
    Navigator.pop(context); // Close dialog

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final evaluationProvider = context.read<EvaluationProvider>();

      final report = await evaluationProvider.generateReport(
        childId: _selectedChildId!,
        type: type,
        generatedBy: authProvider.userId ?? 'system',
      );

      if (report != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء التقرير بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate to export screen
        Navigator.pushNamed(
          context,
          Routes.exportReport,
          arguments: {
            'childId': _selectedChildId,
            'reportType': type,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في إنشاء التقرير: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
