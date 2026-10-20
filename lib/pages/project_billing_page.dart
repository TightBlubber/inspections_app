import 'package:flutter/material.dart';
import '../services/db.dart';
import '../widgets/confirm_delete_dialog.dart';

class ProjectBillingPage extends StatefulWidget {
  final String projectId;
  final int taskId;
  const ProjectBillingPage({
    super.key,
    required this.projectId,
    required this.taskId,
  });

  @override
  State<ProjectBillingPage> createState() => _ProjectBillingPageState();
}

class _ProjectBillingPageState extends State<ProjectBillingPage> {
  // billing_code_id → description
  Map<String, String> _codeDescMap = {};
  // description → billing_code_id
  Map<String, String> _descToCodeMap = {};
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
      final billing = await DbService.getTaskBilling(widget.taskId);
      final map = <String, String>{}; // currently 
      final descMap = <String, String>{};
      final descToCode = <String, String>{};
      for (final c in codes) {
        final id = c['billing_code_id'] as String? ?? '';
        final desc = c['description'] as String? ?? '';
        if (id.isNotEmpty) {
          descMap[id] = desc.isNotEmpty ? desc : id;
          descToCode[desc.isNotEmpty ? desc : id] = id;
        }
      }
      final oldRows = List<_BillingRow>.from(_rows);
      setState(() {
        _codeDescMap = descMap;
        _descToCodeMap = descToCode;
        _rows.clear();
        for (final b in billing) {
          final code = b['billing_code_id'] as String? ?? '';
          final desc = descMap[code] ?? code;
          _rows.add(_BillingRow(
            id: b['id'] as int?,
            resolvedCodeId: code,
            code: desc,
            rate: b['rate'] != null ? b['rate'].toString() : '',
          ));
        }
        // always have a trailing empty row
        _rows.add(_BillingRow());
        _isLoading = false;
      });
      // dispose old rows after the frame so RawAutocomplete doesn't get a null controller
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final row in oldRows) {row.dispose();}
      });
      for (var i = 0; i < _rows.length; i++) {
        _attachRowListener(i);
      }
    } catch (e) {
      setState(() {
        if (_rows.isEmpty) _rows.add(_BillingRow());
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    }
  }

  void _attachRowListener(int index) {
    final row = _rows[index];
    row.codeController.addListener(() {
      final i = _rows.indexOf(row);
      if (i < 0) return;
      final text = row.codeController.text;
      // auto-add a new row when typing into the last row
      if (i == _rows.length - 1 && text.isNotEmpty) {
        setState(() {
          _rows.add(_BillingRow());
          _attachRowListener(_rows.length - 1);
        });
      }
    });
  }

  void _onCodeSelected(int index, String description) {
    final codeId = _descToCodeMap[description] ?? description;
    setState(() {
      _rows[index].codeController.text = description;
      _rows[index].resolvedCodeId = codeId;
      // add a new empty row if we just filled the last row
      if (index == _rows.length - 1) {
        _rows.add(_BillingRow());
        _attachRowListener(_rows.length - 1);
      }
    });
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

    final toSave = _rows
        .where((r) => r.codeController.text.trim().isNotEmpty)
        .toList();

    final blankRateRows = toSave
        .where((r) => r.rateController.text.trim().isEmpty)
        .toList();

    if (blankRateRows.isNotEmpty) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Warning'),
          content: const SingleChildScrollView(
            child: Text('One or more billing entries are missing a rate. Please enter a rate before saving.'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    String? errorMsg;
    try {
      // 1. upsert billing codes into BillingCodes (creates new codes automatically)
      for (final row in toSave) {
        final codeId = row.resolvedCodeId ?? row.codeController.text.trim();
        await DbService.upsertBillingCode({
          'billing_code_id': codeId,
        });
      }

      // 2. delete ALL rows for this task, then re-insert current state
      await DbService.deleteTaskBilling(widget.taskId);

      // 3. re-insert all kept rows
      for (final row in toSave) {
        final codeId = row.resolvedCodeId ?? row.codeController.text.trim();
        await DbService.insertProjectBilling({
          'project_id': widget.projectId,
          'task_id': widget.taskId,
          'billing_code_id': codeId,
          'rate': row.rateController.text.trim(),
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

  Future<void> _removeRow(int index) async {
    if (_rows[index].id != null) {
      final confirmed =
          await confirmDelete(context, itemName: 'this billing row');
      if (!confirmed || !mounted) return;
    }
    setState(() {
      final id = _rows[index].id;
      if (id != null) _deletedIds.add(id);
      _rows[index].dispose();
      _rows.removeAt(index);
      // always keep at least one empty row
      if (_rows.isEmpty) {
        _rows.add(_BillingRow());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
      ),
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
                                flex: 5,
                                child: Text('Description',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Text('Rate',
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
                                    flex: 5,
                                    child: RawAutocomplete<String>(
                                      textEditingController: row.codeController,
                                      focusNode: row.codeFocusNode,
                                      displayStringForOption: (o) => o,
                                      optionsBuilder: (textEditingValue) {
                                        final query = textEditingValue.text.toLowerCase();
                                        // Show the full list when empty or when
                                        // the text is an already-selected option.
                                        if (query.isEmpty ||
                                            _descToCodeMap.keys.any((k) =>
                                                k.toLowerCase() == query)) {
                                          return _descToCodeMap.keys;
                                        }
                                        return _descToCodeMap.keys.where((k) =>
                                            k.toLowerCase().contains(query));
                                      },
                                      onSelected: (desc) =>
                                          _onCodeSelected(i, desc),
                                      fieldViewBuilder: (context, controller,
                                          focusNode, onFieldSubmitted) {
                                        return TextField(
                                          controller: controller,
                                          focusNode: focusNode,
                                          decoration: InputDecoration(
                                            border: const OutlineInputBorder(),
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 10),
                                            hintText: 'Select or type new',
                                            suffixIcon: IconButton(
                                              icon: const Icon(
                                                  Icons.arrow_drop_down),
                                              tooltip: 'Show options',
                                              onPressed: () {
                                                focusNode.unfocus();
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback((_) =>
                                                        focusNode
                                                            .requestFocus());
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                      optionsViewBuilder:
                                          (context, onSelected, options) {
                                        return Align(
                                          alignment: Alignment.topLeft,
                                          child: Material(
                                            elevation: 4,
                                            child: ConstrainedBox(
                                              constraints:
                                                  const BoxConstraints(
                                                      maxHeight: 200),
                                              child: ListView.builder(
                                                padding: EdgeInsets.zero,
                                                shrinkWrap: true,
                                                itemCount: options.length,
                                                itemBuilder: (context, idx) {
                                                  final option =
                                                      options.elementAt(idx);
                                                  return ListTile(
                                                    title: Text(option),
                                                    dense: true,
                                                    onTap: () =>
                                                        onSelected(option),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: row.rateController,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        prefixText: '\$ ',
                                        hintText: 'Rate',
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
                          constraints: const BoxConstraints(maxWidth: 1000),
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
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save & Close'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _BillingRow {
  int? id;
  String? resolvedCodeId; // the actual billing_code_id stored in DB
  final TextEditingController codeController; // displays description
  final FocusNode codeFocusNode;
  final TextEditingController rateController;

  _BillingRow({this.id, this.resolvedCodeId, String code = '', String rate = ''})
      : codeController = TextEditingController(text: code),
        codeFocusNode = FocusNode(),
        rateController = TextEditingController(text: rate);

  void dispose() {
    codeController.dispose();
    codeFocusNode.dispose();
    rateController.dispose();
  }
}
