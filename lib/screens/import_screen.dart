import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _pasteController = TextEditingController();
  bool _importing = false;
  String? _resultMessage;
  bool _resultSuccess = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _pasteController.dispose();
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

  void _showResult({required bool success, required String message}) {
    setState(() {
      _importing = false;
      _resultSuccess = success;
      _resultMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Import Transactions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: const Color(0xFF4CD964),
          unselectedLabelColor: Colors.white38,
          indicatorColor: const Color(0xFF4CD964),
          tabs: const [
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
                _PasteTab(
                  controller: _pasteController,
                  onImport: _importing ? null : _importPasted,
                ),
                _CsvTab(onImport: _importing ? null : _importCsv),
              ],
            ),
          ),
          if (_importing)
            const LinearProgressIndicator(
              color: Color(0xFF4CD964),
              backgroundColor: Colors.transparent,
            ),
          if (_resultMessage != null)
            _ResultBanner(
              message: _resultMessage!,
              success: _resultSuccess,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _InfoCard(
            icon: Icons.content_paste_rounded,
            title: 'Paste your M-Pesa SMS messages',
            body: 'Copy your M-Pesa notification messages and paste them below. '
                'You can paste one or many messages at once — each will be '
                'parsed and added to your activity.',
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: TextField(
              controller: controller,
              maxLines: 12,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
              decoration: const InputDecoration(
                hintText:
                    'RHL92ABC12 Confirmed. Ksh500.00 sent to JANE DOE 0722000000 on 1/5/26 at 2:30 PM...',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                contentPadding: EdgeInsets.all(14),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onImport,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF25A244),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.upload_rounded),
            label: const Text('Import Messages',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _InfoCard(
            icon: Icons.table_chart_rounded,
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
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF25A244).withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.upload_file_rounded,
                    color: Color(0xFF4CD964), size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Tap to pick your CSV file',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 4),
                const Text(
                  '.csv or .txt',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onImport,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25A244),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Choose File',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2E1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF25A244).withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF4CD964), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 6),
                Text(body,
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 12, height: 1.5)),
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
  final VoidCallback onDismiss;

  const _ResultBanner({
    required this.message,
    required this.success,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: success ? const Color(0xFF1A4D2E) : const Color(0xFF4D1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            success
                ? Icons.check_circle_rounded
                : Icons.error_outline_rounded,
            color: success ? const Color(0xFF4CD964) : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: success ? Colors.white : Colors.red.shade300,
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close_rounded,
                color: Colors.white38, size: 18),
          ),
        ],
      ),
    );
  }
}
