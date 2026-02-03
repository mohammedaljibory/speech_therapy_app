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

      _child = await childrenProvider.getChild(widget.childId);

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
          // Logo
          pw.Container(
            width: 80,
            height: 80,
            decoration: pw.BoxDecoration(
              gradient: const pw.LinearGradient(
                colors: [PdfColors.blue400, PdfColors.purple400],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Center(
              child: pw.Stack(
                alignment: pw.Alignment.center,
                children: [
                  pw.Container(
                    width: 50,
                    height: 50,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(25),
                    ),
                  ),
                  pw.Text(
                    'ن',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            'نظام تحسين النطق',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.Text(
            'لأطفال التوحد',
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.blue700,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue100,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text(
              'تقرير تقدم الطفل - ${_report!.typeLabel}',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
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

          // Basic Statistics Table
          pw.Text(
            'الإحصائيات الأساسية',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700),
          ),
          pw.SizedBox(height: 5),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                children: [
                  _buildTableCell('المقياس', isHeader: true),
                  _buildTableCell('القيمة', isHeader: true),
                ],
              ),
              pw.TableRow(children: [
                _buildTableCell('عدد الجلسات'),
                _buildTableCell('${metrics.totalSessions}'),
              ]),
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
                _buildTableCell('وقت التمرين'),
                _buildTableCell(metrics.formattedPracticeTime),
              ]),
            ],
          ),

          pw.SizedBox(height: 15),

          // Detailed Metrics Table
          pw.Text(
            'مقاييس التقييم التفصيلية',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.purple700),
          ),
          pw.SizedBox(height: 5),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.purple50),
                children: [
                  _buildTableCell('المقياس', isHeader: true),
                  _buildTableCell('القيمة', isHeader: true),
                  _buildTableCell('الوصف', isHeader: true),
                ],
              ),
              pw.TableRow(children: [
                _buildTableCell('الدقة (Accuracy)'),
                _buildTableCell('${metrics.averageAccuracy.toStringAsFixed(1)}%'),
                _buildTableCell(_getAccuracyDescription(metrics.averageAccuracy)),
              ]),
              pw.TableRow(children: [
                _buildTableCell('التشابه (Similarity)'),
                _buildTableCell('${metrics.averageSimilarity.toStringAsFixed(1)}%'),
                _buildTableCell(_getSimilarityDescription(metrics.averageSimilarity)),
              ]),
              pw.TableRow(children: [
                _buildTableCell('معدل خطأ الكلمات (WER)'),
                _buildTableCell('${metrics.averageWer.toStringAsFixed(1)}%'),
                _buildTableCell(_getWerDescription(metrics.averageWer)),
              ]),
              pw.TableRow(children: [
                _buildTableCell('معدل خطأ الأحرف (CER)'),
                _buildTableCell('${metrics.averageCer.toStringAsFixed(1)}%'),
                _buildTableCell(_getCerDescription(metrics.averageCer)),
              ]),
              pw.TableRow(children: [
                _buildTableCell('تقييم جودة النطق (MOS)'),
                _buildTableCell('${metrics.averageMos.toStringAsFixed(1)}/5'),
                _buildTableCell(_getMosDescription(metrics.averageMos)),
              ]),
            ],
          ),

          pw.SizedBox(height: 15),

          // Overall Level
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.green200),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'المستوى العام: ',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  metrics.overallLevel,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAccuracyDescription(double value) {
    if (value >= 90) return 'ممتاز';
    if (value >= 70) return 'جيد';
    if (value >= 50) return 'متوسط';
    return 'يحتاج تحسين';
  }

  String _getSimilarityDescription(double value) {
    if (value >= 90) return 'تطابق عالي';
    if (value >= 70) return 'تشابه جيد';
    if (value >= 50) return 'تشابه متوسط';
    return 'يحتاج تحسين';
  }

  String _getWerDescription(double value) {
    if (value <= 10) return 'ممتاز';
    if (value <= 25) return 'جيد';
    if (value <= 50) return 'متوسط';
    return 'يحتاج تحسين';
  }

  String _getCerDescription(double value) {
    if (value <= 10) return 'ممتاز';
    if (value <= 25) return 'جيد';
    if (value <= 50) return 'متوسط';
    return 'يحتاج تحسين';
  }

  String _getMosDescription(double value) {
    if (value >= 4) return 'جودة عالية';
    if (value >= 3) return 'جودة جيدة';
    if (value >= 2) return 'جودة متوسطة';
    return 'يحتاج تحسين';
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
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Metrics Explanation
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'شرح المقاييس',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
              ),
              pw.SizedBox(height: 8),
              pw.Text('• الدقة (Accuracy): نسبة الكلمات المنطوقة بشكل صحيح', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('• التشابه (Similarity): مدى تشابه النطق مع النطق المرجعي', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('• WER (معدل خطأ الكلمات): نسبة الكلمات الخاطئة - كلما قل كان أفضل', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('• CER (معدل خطأ الأحرف): نسبة الأحرف الخاطئة - كلما قل كان أفضل', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('• MOS (تقييم جودة النطق): تقييم من 1-5 لجودة النطق الإجمالية', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        pw.SizedBox(height: 15),

        // Recommendations
        pw.Container(
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
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
              ),
              pw.SizedBox(height: 8),
              pw.Text('• استمر في التمرين اليومي على الكلمات'),
              pw.Text('• ركز على الكلمات التي تحتاج تحسين'),
              pw.Text('• استخدم التسجيلات للمقارنة ومتابعة التقدم'),
              pw.Text('• راقب معدلات الخطأ (WER, CER) للتحسن المستمر'),
              if (_report!.notes != null) ...[
                pw.SizedBox(height: 10),
                pw.Text('ملاحظات: ${_report!.notes}'),
              ],
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // Footer
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'نظام تحسين النطق لأطفال التوحد',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.Text(
                'تاريخ الإنشاء: ${DateFormat('yyyy/MM/dd HH:mm').format(_report!.generatedAt)}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
      ],
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
          // Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.primaryPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'ن',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'نظام تحسين النطق',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'لأطفال التوحد',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.assessment, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'تقرير تقدم الطفل - ${_report!.typeLabel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
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
          // Section Header - Basic Stats
          Row(
            children: [
              const Icon(Icons.analytics, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              const Text(
                'الإحصائيات الأساسية',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'الجلسات',
                  '${metrics.totalSessions}',
                  Icons.calendar_today,
                  AppColors.primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'التسجيلات',
                  '${metrics.totalRecordings}',
                  Icons.mic,
                  AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'الكلمات',
                  '${metrics.totalWords}',
                  Icons.text_fields,
                  AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'المكتملة',
                  '${metrics.wordsCompleted}',
                  Icons.check_circle,
                  AppColors.primaryOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetricTile(
            'وقت التمرين',
            metrics.formattedPracticeTime,
            Icons.timer,
            Colors.teal,
          ),

          const SizedBox(height: 24),

          // Section Header - Detailed Metrics
          Row(
            children: [
              const Icon(Icons.insights, color: AppColors.primaryPurple),
              const SizedBox(width: 8),
              const Text(
                'مقاييس التقييم التفصيلية',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Accuracy & Similarity
          Row(
            children: [
              Expanded(
                child: _buildDetailedMetricTile(
                  'الدقة',
                  'Accuracy',
                  '${metrics.averageAccuracy.toStringAsFixed(1)}%',
                  Icons.gps_fixed,
                  AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailedMetricTile(
                  'التشابه',
                  'Similarity',
                  '${metrics.averageSimilarity.toStringAsFixed(1)}%',
                  Icons.compare_arrows,
                  AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // WER & CER
          Row(
            children: [
              Expanded(
                child: _buildDetailedMetricTile(
                  'خطأ الكلمات',
                  'WER',
                  '${metrics.averageWer.toStringAsFixed(1)}%',
                  Icons.text_snippet,
                  Colors.orange.shade700,
                  isErrorMetric: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailedMetricTile(
                  'خطأ الأحرف',
                  'CER',
                  '${metrics.averageCer.toStringAsFixed(1)}%',
                  Icons.abc,
                  Colors.red.shade400,
                  isErrorMetric: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // MOS Score
          _buildDetailedMetricTile(
            'جودة النطق',
            'MOS Score',
            '${metrics.averageMos.toStringAsFixed(1)} / 5',
            Icons.star,
            Colors.amber.shade700,
          ),

          const SizedBox(height: 20),

          // Overall Level
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryGreen.withOpacity(0.1),
                  AppColors.primaryBlue.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryGreen.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, color: AppColors.primaryGreen, size: 28),
                const SizedBox(width: 12),
                Column(
                  children: [
                    const Text(
                      'المستوى العام',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      metrics.overallLevel,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 200));
  }

  Widget _buildDetailedMetricTile(
    String label,
    String englishLabel,
    String value,
    IconData icon,
    Color color, {
    bool isErrorMetric = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            englishLabel,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
          if (isErrorMetric)
            Text(
              'كلما قل كان أفضل',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade400,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
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
