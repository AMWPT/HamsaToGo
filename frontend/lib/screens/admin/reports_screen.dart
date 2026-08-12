import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:pdf/pdf.dart' hide TextDirection;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' hide TextDirection;

import '../../core/theme.dart';
import '../../models/order.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/hamsa_button.dart';
import '../../widgets/lang_toggle_button.dart';

/// Staff daily report: pick a day, pull every order placed that day, show a
/// summary (count + total) and each order's customer, items and total, then
/// export the whole thing to a shareable / saveable PDF.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime _date = DateTime.now();
  bool _loading = false;
  bool _exporting = false;
  bool _hasSearched = false;
  List<Order> _orders = [];

  double get _total =>
      _orders.fold(0.0, (sum, o) => sum + o.totalPrice);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: HamsaColors.greenAccent,
            surface: HamsaColors.bgSurface,
            onSurface: HamsaColors.cream,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: HamsaColors.bgSurface),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _retrieve() async {
    setState(() {
      _loading = true;
      _hasSearched = true;
    });
    try {
      // Local day boundaries → Firestore Timestamp bounds. created_at is stored
      // as a Timestamp (backend writes a UTC datetime), so a single-field range
      // query works with no composite index.
      final start = DateTime(_date.year, _date.month, _date.day);
      final end = start.add(const Duration(days: 1));
      final snap = await FirebaseFirestore.instance
          .collection('orders')
          .where('created_at',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('created_at', isLessThan: Timestamp.fromDate(end))
          .get();

      final orders = snap.docs.map((d) => Order.fromFirestore(d)).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      setState(() => _orders = orders);
    } catch (e) {
      setState(() => _orders = []);
      if (mounted) {
        final isAr = ref.read(localeProvider).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr
              ? 'تعذّر جلب التقرير. حاول مرة أخرى.'
              : 'Could not load the report. Please try again.'),
          backgroundColor: HamsaColors.error.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportPdf() async {
    if (_orders.isEmpty) return;
    setState(() => _exporting = true);
    try {
      final bytes = await _buildPdf();
      final dateStr = DateFormat('yyyy-MM-dd').format(_date);
      await Printing.sharePdf(bytes: bytes, filename: 'Hamsa-Report-$dateStr.pdf');
    } catch (e) {
      if (mounted) {
        final isAr = ref.read(localeProvider).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr
              ? 'تعذّر إنشاء ملف PDF.'
              : 'Could not generate the PDF.'),
          backgroundColor: HamsaColors.error.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<Uint8List> _buildPdf() async {
    // Noto Sans Arabic renders Arabic (with proper shaping), Latin letters,
    // and digits — unlike the Noor display font, which only has Arabic glyphs
    // and rendered everything else as tofu/symbols. Loaded via the printing
    // package's font helper (downloaded + cached on first use).
    final base = await PdfGoogleFonts.notoSansArabicRegular();
    final bold = await PdfGoogleFonts.notoSansArabicBold();
    final isAr = ref.read(localeProvider).languageCode == 'ar';
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(_date);

    final doc = pw.Document();
    final theme = pw.ThemeData.withFont(base: base, bold: bold);

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        textDirection: isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => [
          // Header
          pw.Text(isAr ? 'حمصة لتحميص القهوة' : 'Hamsa Coffee Roasters',
              style: pw.TextStyle(fontSize: 20, color: PdfColors.green900)),
          pw.Text(isAr ? 'تقرير المبيعات اليومي' : 'Daily Sales Report',
              style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(dateStr,
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800)),
          pw.Divider(color: PdfColors.green200),

          // Summary
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                  isAr ? 'عدد الطلبات: ${_orders.length}' : 'Orders: ${_orders.length}',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.Text(
                  isAr
                      ? 'الإجمالي: ${_total.toStringAsFixed(2)} ريال'
                      : 'Total: SAR ${_total.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 12),

          // Orders table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(38),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(4),
              3: const pw.FixedColumnWidth(70),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.green50),
                children: [
                  _cell(isAr ? '#' : '#', bold: true),
                  _cell(isAr ? 'العميل' : 'Customer', bold: true),
                  _cell(isAr ? 'الأصناف' : 'Items', bold: true),
                  _cell(isAr ? 'الإجمالي' : 'Total', bold: true),
                ],
              ),
              ..._orders.map((o) {
                final items = o.items
                    .map((it) =>
                        '${it.quantity}× ${it.name(isAr ? 'ar' : 'en')}')
                    .join('\n');
                return pw.TableRow(children: [
                  _cell('#${o.displayNumber}'),
                  _cell(o.customerName.isEmpty ? '-' : o.customerName),
                  _cell(items),
                  _cell(o.totalPrice.toStringAsFixed(2)),
                ]);
              }),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
              isAr
                  ? 'تم الإنشاء بواسطة تطبيق حمصة'
                  : 'Generated by Hamsa To Go',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _cell(String text, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final dateLabel = DateFormat('EEEE, d MMM yyyy').format(_date);

    return Scaffold(
      backgroundColor: HamsaColors.bgDeep,
      appBar: AppBar(
        backgroundColor: HamsaColors.bgDeep,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: HamsaColors.muted, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isAr ? 'التقرير اليومي' : 'Daily Report',
          style: HamsaText.heading(size: 18, color: HamsaColors.cream),
        ),
        actions: const [LangToggleButton(), SizedBox(width: 8)],
      ),
      body: Column(
        children: [
          // Date picker + retrieve
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: HamsaColors.inputBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: HamsaColors.border),
                      ),
                      child: Row(
                        textDirection:
                            isAr ? TextDirection.rtl : TextDirection.ltr,
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 18, color: HamsaColors.greenAccent),
                          const SizedBox(width: 10),
                          Text(dateLabel,
                              style: HamsaText.body(
                                  size: 14, color: HamsaColors.cream)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 120,
                  child: HamsaButton(
                    label: isAr ? 'عرض' : 'Retrieve',
                    onTap: _loading ? null : _retrieve,
                    isLoading: _loading,
                  ),
                ),
              ],
            ),
          ),

          // Summary + list
          Expanded(child: _body(isAr)),

          // Export button
          if (_orders.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: HamsaButton(
                  label: isAr ? 'تصدير PDF' : 'Export PDF',
                  onTap: _exporting ? null : _exportPdf,
                  isLoading: _exporting,
                  icon: Icons.picture_as_pdf_rounded,
                  style: HamsaButtonStyle.secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(bool isAr) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: HamsaColors.greenAccent),
      );
    }
    if (!_hasSearched) {
      return Center(
        child: Text(
          isAr
              ? 'اختر يوماً واضغط "عرض"'
              : 'Pick a day and tap "Retrieve"',
          style: HamsaText.body(color: HamsaColors.muted),
        ),
      );
    }
    if (_orders.isEmpty) {
      return Center(
        child: Text(
          isAr ? 'لا توجد طلبات في هذا اليوم' : 'No orders on this day',
          style: HamsaText.body(color: HamsaColors.muted),
        ),
      );
    }

    return Column(
      children: [
        // Summary card
        Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: HamsaColors.greenAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: HamsaColors.greenAccent.withValues(alpha: 0.3)),
          ),
          child: Row(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: isAr
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(isAr ? 'عدد الطلبات' : 'Orders',
                      style: HamsaText.body(
                          size: 12, color: HamsaColors.muted)),
                  const SizedBox(height: 2),
                  Text('${_orders.length}',
                      style: HamsaText.heading(
                          size: 24, color: HamsaColors.cream)),
                ],
              ),
              Column(
                crossAxisAlignment: isAr
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  Text(isAr ? 'الإجمالي' : 'Total',
                      style: HamsaText.body(
                          size: 12, color: HamsaColors.muted)),
                  const SizedBox(height: 2),
                  Text('SAR ${_total.toStringAsFixed(2)}',
                      style: HamsaText.price(size: 22)),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms),

        // Orders list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            itemCount: _orders.length,
            itemBuilder: (_, i) =>
                _OrderReportCard(order: _orders[i], isAr: isAr)
                    .animate(delay: Duration(milliseconds: i * 40))
                    .fadeIn(duration: 250.ms),
          ),
        ),
      ],
    );
  }
}

class _OrderReportCard extends StatelessWidget {
  final Order order;
  final bool isAr;
  const _OrderReportCard({required this.order, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final locale = isAr ? 'ar' : 'en';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HamsaColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HamsaColors.border),
      ),
      child: Column(
        crossAxisAlignment:
            isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Header: order # + customer + total
          Row(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: isAr
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName.isEmpty
                          ? (isAr ? 'بدون اسم' : 'No name')
                          : order.customerName,
                      style: HamsaText.body(
                        size: 14,
                        weight: FontWeight.w600,
                        color: HamsaColors.cream,
                      ),
                      textDirection:
                          isAr ? TextDirection.rtl : TextDirection.ltr,
                    ),
                    Text('#${order.displayNumber}',
                        style: HamsaText.body(
                            size: 11, color: HamsaColors.muted)),
                  ],
                ),
              ),
              Text('SAR ${order.totalPrice.toStringAsFixed(2)}',
                  style: HamsaText.price(size: 16)),
            ],
          ),
          const Divider(color: HamsaColors.border, height: 20),
          // Items
          ...order.items.map(
            (it) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${it.quantity}× ${it.name(locale)}',
                style: HamsaText.body(size: 13, color: HamsaColors.offWhite),
                textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
