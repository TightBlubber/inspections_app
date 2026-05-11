import 'package:flutter/material.dart';
import '../services/db.dart';

class ProjectBillingPage extends StatefulWidget {
  final String projectId;
  const ProjectBillingPage({super.key, required this.projectId});

  @override
  State<ProjectBillingPage> createState() => _ProjectBillingPageState();
}

class _ProjectBillingPageState extends State<ProjectBillingPage> {
  // billing_code_id → rate lookup
  Map<String, String> _codeRateMap = {};
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
        final rate = c['rate'] as String? ?? '';
        if (id.isNotEmpty) map[id] = rate;
      }
      final oldRows = List<_BillingRow>.from(_rows);
      setState(() {
        _codeRateMap = map;
        _rows.clear();
        for (final b in billing) {
          final code = b['billing_code_id'] as String? ?? '';
          _rows.add(_BillingRow(
            id: b['id'] as int?,
            code: code,
            rate: map[code] ?? '',
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
      // auto-fill rate when text exactly matches a known code and rate is empty
      if (_codeRateMap.containsKey(text) && row.rateController.text.isEmpty) {
        row.rateController.text = _codeRateMap[text]!;
      }
      // auto-add a new row when typing into the last row
      if (i == _rows.length - 1 && text.isNotEmpty) {
        setState(() {
          _rows.add(_BillingRow());
          _attachRowListener(_rows.length - 1);
        });
      }
    });
  }

  void _onCodeSelected(int index, String code) {
    setState(() {
      _rows[index].codeController.text = code;
      _rows[index].rateController.text = _codeRateMap[code] ?? '';
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

    setState(() => _isSaving = true);

    final toSave = _rows
        .where((r) => r.codeController.text.trim().isNotEmpty)
        .toList();

    String? errorMsg;
    try {
      // 1. upsert billing codes into BillingCodes (creates new codes automatically)
      for (final row in toSave) {
        await DbService.upsertBillingCode({
          'billing_code_id': row.codeController.text.trim(),
          'rate': row.rateController.text.trim(),
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
                                flex: 3,
                                child: Text('Billing Code',
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
                                    flex: 3,
                                    child: RawAutocomplete<String>(
                                      textEditingController: row.codeController,
                                      focusNode: row.codeFocusNode,
                                      displayStringForOption: (o) => o,
                                      optionsBuilder: (textEditingValue) {
                                        final query = textEditingValue.text.toLowerCase();
                                        if (query.isEmpty) {
                                          return _codeRateMap.keys;
                                        }
                                        return _codeRateMap.keys.where((k) =>
                                            k.toLowerCase().contains(query));
                                      },
                                      onSelected: (code) =>
                                          _onCodeSelected(i, code),
                                      fieldViewBuilder: (context, controller,
                                          focusNode, onFieldSubmitted) {
                                        return TextField(
                                          controller: controller,
                                          focusNode: focusNode,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 10),
                                            hintText: 'Select or type new',
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
  final FocusNode codeFocusNode;
  final TextEditingController rateController;

  _BillingRow({this.id, String code = '', String rate = ''})
      : codeController = TextEditingController(text: code),
        codeFocusNode = FocusNode(),
        rateController = TextEditingController(text: rate);

  void dispose() {
    codeController.dispose();
    codeFocusNode.dispose();
    rateController.dispose();
  }
}
