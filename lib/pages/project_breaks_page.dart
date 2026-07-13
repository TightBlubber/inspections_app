import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/db.dart';

class ProjectBreaksPage extends StatefulWidget {
  final String projectId;

  const ProjectBreaksPage({super.key, this.projectId = ''});

  @override
  State<ProjectBreaksPage> createState() => _ProjectBreaksPageState();
}

class _ProjectBreaksPageState extends State<ProjectBreaksPage> {
  final List<TextEditingController> _cylinderControllers =
      List.generate(10, (_) => TextEditingController());
  final TextEditingController _defaultDiameter = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  static const List<String> _cylinderLabels = [
    'First Cylinder',
    'Second Cylinder',
    'Third Cylinder',
    'Fourth Cylinder',
    'Fifth Cylinder',
    'Sixth Cylinder',
    'Seventh Cylinder',
    'Eighth Cylinder',
    'Ninth Cylinder',
    'Tenth Cylinder',
  ];

  static const List<String> _cylinderColumns = [
    'cylinder_1', 'cylinder_2', 'cylinder_3', 'cylinder_4', 'cylinder_5',
    'cylinder_6', 'cylinder_7', 'cylinder_8', 'cylinder_9', 'cylinder_10',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final row = await DbService.getCylinderBreaks(widget.projectId);
      if (row != null) {
        for (var i = 0; i < 10; i++) {
          final val = row[_cylinderColumns[i]];
          _cylinderControllers[i].text = val != null ? val.toString() : '';
        }
        final diam = row['default_diameter'];
        _defaultDiameter.text = diam != null ? diam.toString() : '';
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (widget.projectId.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{'project_id': widget.projectId};
      for (var i = 0; i < 10; i++) {
        final text = _cylinderControllers[i].text.trim();
        data[_cylinderColumns[i]] = text.isEmpty ? null : int.tryParse(text);
      }
      final diam = _defaultDiameter.text.trim();
      data['default_diameter'] = diam.isEmpty ? null : diam;
      await DbService.upsertCylinderBreaks(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    for (final c in _cylinderControllers) {
      c.dispose();
    }
    _defaultDiameter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _save();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Breaks'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: LayoutBuilder(builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 600;
                        final content = _buildContent();
                        if (!isWide) return content;
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 500),
                            child: content,
                          ),
                        );
                      }),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () async {
                                  await _save();
                                  if (context.mounted) Navigator.pop(context);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save & Close'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _readOnlyRow('Project ID', widget.projectId),
        const SizedBox(height: 12),
        const Text(
          'Cylinder Break Days - enter 999 for HOLD.',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        ...List.generate(
            10, (i) => _labeledIntField(_cylinderLabels[i], _cylinderControllers[i])),
        const Divider(height: 20),
        _labeledTextField('Default Diameter', _defaultDiameter),
      ],
    );
  }

  Widget _readOnlyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(value, style: const TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labeledIntField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labeledTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
