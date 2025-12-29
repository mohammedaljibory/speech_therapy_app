import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../config/themes.dart';
import '../../config/routes.dart';
import '../../config/constants.dart';
import '../../models/child_model.dart';
import '../../providers/children_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/categories_provider.dart';
import '../../widgets/common/custom_button.dart';

class RecordingsListScreen extends StatefulWidget {
  final String? childId;

  const RecordingsListScreen({super.key, this.childId});

  @override
  State<RecordingsListScreen> createState() => _RecordingsListScreenState();
}

class _RecordingsListScreenState extends State<RecordingsListScreen> {
  List<Map<String, dynamic>> _recordings = [];
  List<ChildModel> _children = [];
  String? _selectedChildId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedChildId = widget.childId;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final childrenProvider = context.read<ChildrenProvider>();

      // Load children
      await childrenProvider.loadChildren(authProvider.userId!);
      _children = childrenProvider.children;

      // If no child selected and we have children, select first
      if (_selectedChildId == null && _children.isNotEmpty) {
        _selectedChildId = _children.first.id;
      }

      // Load recordings for selected child
      if (_selectedChildId != null) {
        await _loadRecordings();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في تحميل البيانات: $e')),
        );
      }
    }
  }

  Future<void> _loadRecordings() async {
    if (_selectedChildId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.recordingsCollection)
          .where('childId', isEqualTo: _selectedChildId)
          .orderBy('recordedAt', descending: true)
          .limit(50)
          .get();

      _recordings = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error loading recordings: $e');
      _recordings = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F7FF), Color(0xFFFFFBF5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildChildSelector(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _recordings.isEmpty
                        ? _buildEmptyState()
                        : _buildRecordingsList(),
              ),
            ],
          ),
        ),
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
          const Icon(Icons.mic, color: AppColors.primaryBlue),
          const SizedBox(width: 8),
          Text(
            'التسجيلات',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_recordings.length} تسجيل',
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildChildSelector() {
    if (_children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            icon: const Icon(Icons.keyboard_arrow_down),
            hint: const Text('اختر طفل'),
            items: _children.map((child) {
              return DropdownMenuItem<String>(
                value: child.id,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                      child: Text(
                        child.name.isNotEmpty ? child.name[0] : '?',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(child.name),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) async {
              setState(() {
                _selectedChildId = value;
                _isLoading = true;
              });
              await _loadRecordings();
              setState(() => _isLoading = false);
            },
          ),
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
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.mic_none,
              size: 50,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد تسجيلات',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ جلسة تدريب لإنشاء تسجيلات',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'بدء التدريب',
            icon: Icons.play_arrow,
            onPressed: () => context.navigateTo(Routes.categories),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildRecordingsList() {
    final categoriesProvider = context.read<CategoriesProvider>();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _recordings.length,
        itemBuilder: (context, index) {
          final recording = _recordings[index];
          final wordId = recording['wordId'] as String?;
          final word = wordId != null ? categoriesProvider.getWordById(wordId) : null;
          final score = (recording['score'] as num?)?.toDouble() ?? 0;
          final recordedAt = recording['recordedAt'] as Timestamp?;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getScoreColor(score).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '${score.toInt()}%',
                    style: TextStyle(
                      color: _getScoreColor(score),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                word?.text ?? 'كلمة غير معروفة',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recording['transcription'] != null)
                    Text(
                      'النص: ${recording['transcription']}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  if (recordedAt != null)
                    Text(
                      DateFormat('yyyy/MM/dd - HH:mm').format(recordedAt.toDate()),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.compare_arrows, color: AppColors.primaryOrange),
                onPressed: word != null
                    ? () {
                        context.navigateTo(Routes.comparison, arguments: {
                          'childId': _selectedChildId,
                          'wordId': word.id,
                        });
                      }
                    : null,
                tooltip: 'مقارنة',
              ),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: index * 50));
        },
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
