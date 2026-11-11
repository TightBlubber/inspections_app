import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/db.dart';
import '../widgets/neutral_button_colors.dart';

/// True when a task type description refers to a daily photo report.
bool isDailyPhotoReportType(String taskType) {
  final t = taskType.toLowerCase();
  return t.contains('daily') && t.contains('photo');
}

class _PhotoSlot {
  final TextEditingController notes = TextEditingController();
  String savedPath = '';
  String? signedUrl;
  String? pendingName;
  Uint8List? pendingBytes;

  String get displayName {
    if (pendingName != null) return pendingName!;
    return savedPath.split('/').last;
  }

  bool get hasPhoto => pendingBytes != null || savedPath.isNotEmpty;
}

class DailyPhotoReportPage extends StatefulWidget {
  final int taskId;

  const DailyPhotoReportPage({super.key, required this.taskId});

  @override
  State<DailyPhotoReportPage> createState() => _DailyPhotoReportPageState();
}

class _DailyPhotoReportPageState extends State<DailyPhotoReportPage> {
  static const _photoCount = 3;
  static const _imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];

  final List<_PhotoSlot> _slots = List.generate(
    _photoCount,
    (_) => _PhotoSlot(),
  );
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final s in _slots) {
      s.notes.dispose();
    }
    super.dispose();
  }

  String _fmt(dynamic v) => v == null ? '' : '$v';

  Future<void> _load() async {
    try {
      final report = await DbService.getDailyPhotoReport(widget.taskId);
      if (report != null) {
        for (var i = 0; i < _photoCount; i++) {
          final slot = _slots[i];
          slot.savedPath = _fmt(report['photo${i + 1}_path']);
          slot.notes.text = _fmt(report['photo${i + 1}_notes']);
          if (slot.savedPath.isNotEmpty) {
            slot.signedUrl = await DbService.getReportPhotoUrl(slot.savedPath);
          }
        }
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
    }
  }

  Future<void> _browse(_PhotoSlot slot) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: _imageExtensions,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        slot.pendingName = file.name;
        slot.pendingBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open file: $e')));
    }
  }

  String _contentType(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'bmp' => 'image/bmp',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{'task_id': widget.taskId};
      for (var i = 0; i < _photoCount; i++) {
        final slot = _slots[i];
        var path = slot.savedPath;
        final bytes = slot.pendingBytes;
        if (bytes != null) {
          final name = slot.pendingName!;
          final ext = name.contains('.') ? name.split('.').last : 'jpg';
          path = 'daily-photo-reports/${widget.taskId}/photo${i + 1}.$ext';
          await DbService.uploadReportPhoto(path, bytes, _contentType(name));
        }
        final notes = slot.notes.text.trim();
        data['photo${i + 1}_path'] = path.isEmpty ? null : path;
        data['photo${i + 1}_notes'] = notes.isEmpty ? null : notes;
      }
      await DbService.upsertDailyPhotoReport(data);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Photo Report')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: _buildForm(),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _bottomButton(
                        'Save',
                        _isSaving ? null : _save,
                        primary: true,
                      ),
                      const SizedBox(width: 8),
                      _bottomButton(
                        'Cancel',
                        _isSaving ? null : () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Report Number'),
              const SizedBox(height: 4),
              _readOnly('${widget.taskId}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < _photoCount; i++) ...[
          _buildPhoto(i, _slots[i]),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildPhoto(int index, _PhotoSlot slot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Photo ${index + 1}'),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: _readOnly(slot.displayName)),
            const SizedBox(width: 8),
            _bottomButton('Browse', () => _browse(slot)),
          ],
        ),
        const SizedBox(height: 8),
        _label('Notes'),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: slot.notes,
                minLines: 3,
                maxLines: 5,
                decoration: _decoration(),
              ),
            ),
            const SizedBox(width: 8),
            _preview(slot),
          ],
        ),
      ],
    );
  }

  Widget _preview(_PhotoSlot slot) {
    Widget child;
    if (slot.pendingBytes != null) {
      child = Image.memory(slot.pendingBytes!, fit: BoxFit.cover);
    } else if (slot.signedUrl != null) {
      child = Image.network(
        slot.signedUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
      );
    } else {
      child = const Icon(Icons.image_outlined);
    }
    return SizedBox(
      width: 100,
      height: 80,
      child: ClipRRect(borderRadius: BorderRadius.circular(4), child: child),
    );
  }

  Widget _label(String text) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.bold));

  InputDecoration _decoration() => const InputDecoration(
    border: OutlineInputBorder(),
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  );

  Widget _readOnly(String value) {
    return InputDecorator(
      decoration: _decoration().copyWith(
        filled: true,
        fillColor: readOnlyFieldFill(context),
      ),
      child: Text(value, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _bottomButton(
    String label,
    VoidCallback? onPressed, {
    bool primary = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primary
            ? const Color(0xFFED7422)
            : neutralButtonBg(context),
        foregroundColor: primary ? Colors.white : neutralButtonFg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
}
