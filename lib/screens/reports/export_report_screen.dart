import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../config/themes.dart';
import '../../models/report_model.dart';
import '../../models/child_model.dart';
import '../../providers/evaluation_provider.dart';
import '../../providers/children_provider.dart';

class ExportReportScreen extends StatefulWidget {
  final String childId;
  final String reportType;

  const ExportReportScreen({
    super.key,
    required this.childId,
    required this.reportType,
  });

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  ReportModel? _report;
  ChildModel? _child;
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final childrenProvider = context.read<ChildrenProvider>();
      final evaluationProvider = context.read<EvaluationProvider>();

      _child = childrenProvider.getChild(widget.childId);

      // Check if there's an existing report or generate a new one
      await evaluationProvider.loadReports(widget.childId);
      final existingReports = evaluationProvider.reports
          .where((r) => r.type == widget.reportType)
          .toList();

      if (existingReports.isNotEmpty) {
        _report = existingReports.first;
      } else {
        // Generate a new report
        _report = await evaluationProvider.generateReport(
          childId: widget.childId,
          type: widget.reportType,
          generatedBy: 'system',
        );
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في تحميل التقرير: $e')),
        );
      }
    }
  }

  Future<void> _generateAndPrintPdf() async {
    if (_report == null || _child == null) return;

    setState(() => _isGenerating = true);

    try {
      final pdf = await _buildPdf();

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'تقرير_${_child!.name}_${_report!.typeLabel}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في إنشاء PDF: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _sharePdf() async {
    if (_report == null || _child == null) return;

    setState(() => _isGenerating = true);

    try {
      final pdf = await _buildPdf();

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'تقرير_${_child!.name}_${_report!.typeLabel}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في مشاركة PDF: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<pw.Document> _buildPdf() async {
    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFontBold,
        ),
        textDirection: pw.TextDirection.rtl,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildPdfHeader(),
          pw.SizedBox(height: 20),
          _buildPdfChildInfo(),
          pw.SizedBox(height: 20),
          _buildPdfMetrics(),
          pw.SizedBox(height: 20),
          _buildPdfSummary(),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildPdfHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'تقرير تقدم الطفل',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'تقرير ${_report!.typeLabel}',
            style: const pw.TextStyle(fontSize: 16, color: PdfColors.blue700),
          ),
          pw.Text(
            _report!.dateRangeString,
            style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfChildInfo() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('اسم الطفل: ${_child!.name}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('العمر: ${_child!.age} سنوات'),
              pw.Text('المستوى: ${_child!.level}'),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('تاريخ التقرير:'),
              pw.Text(DateFormat('yyyy/MM/dd').format(_report!.generatedAt)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfMetrics() {
    final metrics = _report!.metrics;

    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ملخص الأداء',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('المقياس', isHeader: true),
                  _buildTableCell('القيمة', isHeader: true),
                ],
              ),
              pw.TableRow(children: [
                _buildTableCell('عدد التسجيلات'),
                _buildTableCell('${metrics.totalRecordings}'),
              ]),
              pw.TableRow(children: [
                _buildTableCell('عدد الكلمات'),
                _buildTableCell('${metrics.totalWords}'),
              ]),
              pw.TableRow(children: [
                _buildTableCell('الكلمات المكتملة'),
                _buildTableCell('${metrics.wordsCompleted}'),
              ]),
              pw.TableRow(children: [
                _buildTableCell('متوسط الدقة'),
                _buildTableCell('${metrics.averageAccuracy.toStringAsFixed(1)}%'),
              ]),
              pw.TableRow(children: [
                _buildTableCell('متوسط التشابه'),
                _buildTableCell('${metrics.averageSimilarity.toStringAsFixed(1)}%'),
              ]),
              pw.TableRow(children: [
                _buildTableCell('وقت التمرين'),
                _buildTableCell(metrics.formattedPracticeTime),
              ]),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.green50),
                children: [
                  _buildTableCell('المستوى العام', isHeader: true),
                  _buildTableCell(metrics.overallLevel, isHeader: true),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildPdfSummary() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'التوصيات',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Text('• استمر في التمرين اليومي على الكلمات'),
          pw.Text('• ركز على الكلمات التي تحتاج تحسين'),
          pw.Text('• استخدم التسجيلات للمقارنة ومتابعة التقدم'),
          if (_report!.notes != null) ...[
            pw.SizedBox(height: 10),
            pw.Text('ملاحظات: ${_report!.notes}'),
          ],
        ],
      ),
    );
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
              _buildAppBar(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _report == null
                        ? _buildEmptyState()
                        : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'تصدير التقرير',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'لا يوجد تقرير',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReportHeader(),
          const SizedBox(height: 20),
          _buildChildInfoCard(),
          const SizedBox(height: 20),
          _buildMetricsCard(),
          const SizedBox(height: 20),
          _buildActionButtons(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildReportHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.gradientPrimary,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.assessment, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          const Text(
            'تقرير تقدم الطفل',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'تقرير ${_report!.typeLabel}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _report!.dateRangeString,
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  Widget _buildChildInfoCard() {
    if (_child == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
            child: Text(
              _child!.name[0],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _child!.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'العمر: ${_child!.age} سنوات • المستوى: ${_child!.level}',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 100));
  }

  Widget _buildMetricsCard() {
    final metrics = _report!.metrics;

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: AppColors.primaryPurple),
              const SizedBox(width: 8),
              const Text(
                'ملخص الأداء',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'التسجيلات',
                  '${metrics.totalRecordings}',
                  Icons.mic,
                  AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'الكلمات',
                  '${metrics.totalWords}',
                  Icons.text_fields,
                  AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'الدقة',
                  '${metrics.averageAccuracy.toStringAsFixed(0)}%',
                  Icons.check_circle,
                  AppColors.primaryOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'وقت التمرين',
                  metrics.formattedPracticeTime,
                  Icons.timer,
                  AppColors.primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'المستوى العام: ${metrics.overallLevel}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 200));
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isGenerating ? null : _generateAndPrintPdf,
            icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.print),
            label: Text(_isGenerating ? 'جاري الإنشاء...' : 'طباعة التقرير'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isGenerating ? null : _sharePdf,
            icon: const Icon(Icons.share),
            label: const Text('مشاركة كـ PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryPurple,
              side: const BorderSide(color: AppColors.primaryPurple),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: const Duration(milliseconds: 300));
  }
}
