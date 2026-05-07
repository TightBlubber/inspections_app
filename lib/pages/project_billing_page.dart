import 'package:flutter/material.dart';
import '../services/db.dart';

class ProjectBillingPage extends StatefulWidget {
  final String projectId;
  const ProjectBillingPage({super.key, required this.projectId});

  @override
  State<ProjectBillingPage> createState() => _ProjectBillingPageState();
}

class _ProjectBillingPageState extends State<ProjectBillingPage> {
  // billing_code_id → description lookup
  Map<String, String> _codeDescMap = {};
  final List<_BillingRow> _rows = [];
  final List<int> _deletedIds = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // add one empty row immediately so fields are visible while loading
    _rows.add(_BillingRow());
    _attachRowListener(0);
    _load();
  }

  Future<void> _load() async {
    try {
      final codes = await DbService.getBillingCodes();
      final billing = await DbService.getProjectBilling(widget.projectId);
      final map = <String, String>{};
      for (final c in codes) {
        final id = c['billing_code_id'] as String? ?? '';
        final desc = c['description'] as String? ?? '';
        if (id.isNotEmpty) map[id] = desc;
      }
      setState(() {
        _codeDescMap = map;
        // clear the placeholder row before populating from DB
        for (final row in _rows) {
          row.dispose();
        }
        _rows.clear();
        for (final b in billing) {
          final code = b['billing_code_id'] as String? ?? '';
          _rows.add(_BillingRow(
            id: b['id'] as int?,
            code: code,
            desc: map[code] ?? '',
          ));
        }
        // always have at least one empty row
        if (_rows.isEmpty) _rows.add(_BillingRow());
        _isLoading = false;
      });
      _attachListeners();
    } catch (e) {
      setState(() {
        if (_rows.isEmpty) _rows.add(_BillingRow());
        _isLoading = false;
      });
      _attachListeners();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    }
  }

  void _attachListeners() {
    for (var i = 0; i < _rows.length; i++) {
      _attachRowListener(i);
    }
  }

  void _attachRowListener(int index) {
    final row = _rows[index];
    row.codeController.addListener(() => _onCodeChanged(row));
  }

  void _onCodeChanged(_BillingRow row) {
    final index = _rows.indexOf(row);
    if (index < 0) return;
    final typed = row.codeController.text;

    // auto-fill description from lookup
    if (_codeDescMap.containsKey(typed)) {
      final desc = _codeDescMap[typed]!;
      if (row.descController.text != desc) {
        row.descController.text = desc;
        row.descController.selection = TextSelection.collapsed(
          offset: desc.length,
        );
      }
    }

    // remove blank rows that aren't the trailing empty row
    if (typed.isEmpty && index != _rows.length - 1) {
      final id = row.id;
      if (id != null) _deletedIds.add(id);
      setState(() => _rows.removeAt(index));
      // dispose after the listener callback returns
      WidgetsBinding.instance.addPostFrameCallback((_) => row.dispose());
      return;
    }

    // auto-add a new row when typing into the last row
    if (index == _rows.length - 1 && typed.isNotEmpty) {
      setState(() {
        _rows.add(_BillingRow());
        _attachRowListener(_rows.length - 1);
      });
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    // dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() => _isSaving = true);

    final toSave = _rows
        .where((r) => r.codeController.text.trim().isNotEmpty)
        .toList();

    String? errorMsg;
    try {
      // 1. upsert billing codes into BillingCodes (satisfies FK)
      for (final row in toSave) {
        await DbService.upsertBillingCode({
          'billing_code_id': row.codeController.text.trim(),
          'description': row.descController.text.trim(),
        });
      }

      // 2. delete ALL rows for this project, then re-insert current state
      await DbService.deleteProjectBillingForProject(widget.projectId);

      // 3. re-insert all kept rows
      for (final row in toSave) {
        await DbService.insertProjectBilling({
          'project_id': widget.projectId,
          'billing_code_id': row.codeController.text.trim(),
        });
      }
    } catch (e, st) {
      debugPrint('=== SAVE ERROR: $e\n$st ===');
      errorMsg = e.toString();
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (errorMsg != null) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Save Failed'),
          content: SingleChildScrollView(child: Text(errorMsg!)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _removeRow(int index) {
    setState(() {
      final id = _rows[index].id;
      if (id != null) _deletedIds.add(id);
      _rows[index].dispose();
      _rows.removeAt(index);
      // always keep at least one empty row
      if (_rows.isEmpty) {
        _rows.add(_BillingRow());
        _attachRowListener(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (!_isSaving) _save();
        },
        backgroundColor: const Color(0xFFED7422),
        foregroundColor: Colors.white,
        label: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Text('Save & Close'),
        icon: _isSaving ? null : const Icon(Icons.save),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final content = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // header
                          Row(
                            children: const [
                              Expanded(
                                flex: 2,
                                child: Text('Billing Code #',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: Text('Description',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              SizedBox(width: 40),
                            ],
                          ),
                          const Divider(),
                          // rows
                          ..._rows.asMap().entries.map((entry) {
                            final i = entry.key;
                            final row = entry.value;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: row.codeController,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        hintText: 'Code #',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: row.descController,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        hintText: 'Description',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () => _removeRow(i),
                                    tooltip: 'Remove',
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      );

                      if (constraints.maxWidth < 600) return content;
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: content,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 80), // space for FAB
              ],
            ),
    );
  }
}

class _BillingRow {
  int? id;
  final TextEditingController codeController;
  final TextEditingController descController;

  _BillingRow({this.id, String code = '', String desc = ''})
      : codeController = TextEditingController(text: code),
        descController = TextEditingController(text: desc);

  void dispose() {
    codeController.dispose();
    descController.dispose();
  }
}
