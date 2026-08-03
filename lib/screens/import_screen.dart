import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../theme/app_colors.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _pasteController = TextEditingController();
  final _pdfPasswordController = TextEditingController();
  bool _importing = false;
  String? _resultMessage;
  bool _resultSuccess = false;
  bool _resultWarning = false;

  String? _pdfFilePath;
  String? _pdfFileName;
  String? _pdfProgress;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _pasteController.dispose();
    _pdfPasswordController.dispose();
    super.dispose();
  }

  Future<void> _importCsv() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );
    if (picked == null || picked.files.single.path == null) return;

    final content = await File(picked.files.single.path!).readAsString();
    if (!mounted) return;

    setState(() => _importing = true);
    final result = await context.read<TransactionProvider>().importCsv(content);
    if (!mounted) return;

    _showResult(
      success: result.inserted > 0,
      message: result.inserted > 0
          ? '${result.inserted} new transaction${result.inserted == 1 ? '' : 's'} imported '
              '(${result.parsed} parsed from file)'
          : result.hasErrors
              ? result.errors.first
              : 'No new transactions found in file.',
    );
  }

  Future<void> _importPasted() async {
    final text = _pasteController.text.trim();
    if (text.isEmpty) {
      _showResult(success: false, message: 'Please paste your M-Pesa SMS messages above.');
      return;
    }

    setState(() => _importing = true);
    final result =
        await context.read<TransactionProvider>().importPastedSms(text);
    if (!mounted) return;

    if (result.inserted > 0) _pasteController.clear();

    _showResult(
      success: result.inserted > 0,
      message: result.inserted > 0
          ? '${result.inserted} new transaction${result.inserted == 1 ? '' : 's'} imported '
              '(${result.parsed} parsed)'
          : result.hasErrors
              ? result.errors.first
              : 'No M-Pesa transactions found in pasted text.',
    );
  }

  Future<void> _pickPdf() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (picked == null || picked.files.single.path == null) return;
    setState(() {
      _pdfFilePath = picked.files.single.path;
      _pdfFileName = picked.files.single.name;
    });
  }

  Future<void> _importPdf() async {
    final path = _pdfFilePath;
    if (path == null) {
      _showResult(success: false, message: 'Please choose a PDF file first.');
      return;
    }

    setState(() {
      _importing = true;
      _pdfProgress = null;
    });

    final result = await context.read<TransactionProvider>().importPdf(
          path,
          _pdfPasswordController.text.trim(),
          onProgress: (page, total) {
            if (!mounted) return;
            setState(() => _pdfProgress = 'Reading page $page of $total');
          },
        );
    if (!mounted) return;

    setState(() => _pdfProgress = null);

    if (result.isPasswordError) {
      _showResult(success: false, message: result.errors.first);
      return;
    }

    if (result.inserted > 0) {
      setState(() {
        _pdfFilePath = null;
        _pdfFileName = null;
      });
      _pdfPasswordController.clear();
    }

    _showResult(
      success: result.inserted > 0,
      warning: result.inserted > 0 && result.hasWarnings,
      message: result.inserted > 0
          ? '${result.inserted} new transaction${result.inserted == 1 ? '' : 's'} imported '
              '(${result.parsed} parsed from statement)'
              '${result.hasWarnings ? '\n\n${result.warnings.first}' : ''}'
          : result.hasErrors
              ? result.errors.first
              : 'No new transactions found in this statement.',
    );
  }

  void _showResult({
    required bool success,
    required String message,
    bool warning = false,
  }) {
    setState(() {
      _importing = false;
      _resultSuccess = success;
      _resultWarning = warning;
      _resultMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        title: const Text(
          'Import Transactions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: colors.accentGreen,
          unselectedLabelColor: colors.textMuted,
          indicatorColor: colors.accentGreen,
          dividerColor: colors.border,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal, fontSize: 14),
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          tabs: const [
            Tab(text: 'PDF Statement'),
            Tab(text: 'Paste SMS'),
            Tab(text: 'CSV File'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _PdfTab(
                  passwordController: _pdfPasswordController,
                  fileName: _pdfFileName,
                  onPickFile: _importing ? null : _pickPdf,
                  onImport: _importing ? null : _importPdf,
                ),
                _PasteTab(
                  controller: _pasteController,
                  onImport: _importing ? null : _importPasted,
                ),
                _CsvTab(onImport: _importing ? null : _importCsv),
              ],
            ),
          ),
          if (_importing)
            Column(
              children: [
                LinearProgressIndicator(
                  color: colors.accentGreen,
                  backgroundColor: Colors.transparent,
                ),
                if (_pdfProgress != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Text(
                      _pdfProgress!,
                      style: TextStyle(
                          color: colors.textTertiary, fontSize: 12),
                    ),
                  ),
              ],
            ),
          if (_resultMessage != null)
            _ResultBanner(
              message: _resultMessage!,
              success: _resultSuccess,
              warning: _resultWarning,
              onDismiss: () => setState(() => _resultMessage = null),
            ),
        ],
      ),
    );
  }
}

class _PasteTab extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onImport;

  const _PasteTab({required this.controller, required this.onImport});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _InfoCard(
            icon: Icons.content_paste_outlined,
            title: 'Paste your M-Pesa SMS messages',
            body: 'Copy your M-Pesa notification messages and paste them below. '
                'You can paste one or many messages at once — each will be '
                'parsed and added to your activity.',
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: TextField(
              controller: controller,
              maxLines: 12,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                hintText:
                    'RHL92ABC12 Confirmed. Ksh500.00 sent to JANE DOE 0722000000 on 1/5/26 at 2:30 PM...',
                hintStyle: TextStyle(color: colors.textFaint, fontSize: 12),
                contentPadding: const EdgeInsets.all(14),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onImport,
            style: FilledButton.styleFrom(
              backgroundColor: colors.brandGreen,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.upload_outlined, color: Colors.white),
            label: const Text('Import Messages',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _CsvTab extends StatelessWidget {
  final VoidCallback? onImport;

  const _CsvTab({required this.onImport});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _InfoCard(
            icon: Icons.table_chart_outlined,
            title: 'Import M-Pesa CSV Statement',
            body: 'Export your statement from the M-Pesa app:\n'
                '1. Open M-Pesa → Statements\n'
                '2. Select a date range and export as CSV\n'
                '3. Tap the button below to pick the file',
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.brandGreen.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.upload_file_outlined,
                    color: colors.accentGreen, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Tap to pick your CSV file',
                  style: TextStyle(color: colors.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  '.csv or .txt',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onImport,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.brandGreen,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Choose File',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfTab extends StatelessWidget {
  final TextEditingController passwordController;
  final String? fileName;
  final VoidCallback? onPickFile;
  final VoidCallback? onImport;

  const _PdfTab({
    required this.passwordController,
    required this.fileName,
    required this.onPickFile,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _InfoCard(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Import M-Pesa Statement PDF',
            body: 'Request a statement from the M-Pesa app (Statements → '
                'Full Statement) and set a PIN when prompted — that PDF, '
                'and its PIN, go below.',
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.brandGreen.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  fileName == null
                      ? Icons.upload_file_outlined
                      : Icons.description_outlined,
                  color: colors.accentGreen,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  fileName ?? 'Tap to pick your statement PDF',
                  style: TextStyle(color: colors.textSecondary, fontSize: 15),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (fileName == null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '.pdf',
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: onPickFile,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.accentGreen,
                    side: BorderSide(color: colors.accentGreen),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    fileName == null ? 'Choose File' : 'Change File',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: TextField(
              controller: passwordController,
              obscureText: true,
              keyboardType: TextInputType.number,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Statement PIN',
                hintStyle: TextStyle(color: colors.textFaint, fontSize: 13),
                prefixIcon: Icon(Icons.lock_outline,
                    color: colors.textMuted, size: 20),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: fileName == null ? null : onImport,
            style: FilledButton.styleFrom(
              backgroundColor: colors.brandGreen,
              disabledBackgroundColor: colors.greenTintBg,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.upload_outlined, color: Colors.white),
            label: const Text('Import Statement',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoCard(
      {required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.greenTintBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.brandGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.accentGreen, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 6),
                Text(body,
                    style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final String message;
  final bool success;
  final bool warning;
  final VoidCallback onDismiss;

  const _ResultBanner({
    required this.message,
    required this.success,
    this.warning = false,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color bg;
    final Color accent;
    final Color textColor;
    final IconData icon;
    if (warning) {
      bg = colors.warningBg;
      accent = colors.warningAccent;
      textColor = colors.textPrimary;
      icon = Icons.warning_amber_outlined;
    } else if (success) {
      bg = colors.successBg;
      accent = colors.successAccent;
      textColor = colors.textPrimary;
      icon = Icons.check_circle_outlined;
    } else {
      bg = colors.dangerBg;
      accent = colors.dangerAccent;
      textColor = colors.dangerText;
      icon = Icons.error_outline_outlined;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textColor, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close_outlined,
                color: colors.textMuted, size: 18),
          ),
        ],
      ),
    );
  }
}
