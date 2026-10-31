import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_editor/widgets/pdf_canvas.dart';
import 'package:pdf_editor/widgets/editor_toolbar.dart';
import 'package:pdf_editor/services/pdf_export_service.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF‑Редактор'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final bytes = await PdfExportService.exportCurrentCanvas();
              // Save via FilePicker / Share – simplified
              // ignore: avoid_print
              print('PDF exported – ${bytes.length} bytes');
            },
          ),
        ],
      ),
      body: const Row(
        children: [
          Expanded(child: PdfCanvas()),
          SizedBox(width: 300, child: EditorToolbar()),
        ],
      ),
    );
  }
}
