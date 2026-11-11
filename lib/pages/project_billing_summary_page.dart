import 'package:flutter/material.dart';
import '../services/db.dart';
import '../services/rate_format.dart';
import '../widgets/confirm_delete_dialog.dart';

/// Editable view of every task's billing for one project, with totals.
class ProjectBillingSummaryPage extends StatefulWidget {
  final String projectId;
  const ProjectBillingSummaryPage({super.key, required this.projectId});

  @override
  State<ProjectBillingSummaryPage> createState() =>
      _ProjectBillingSummaryPageState();
}

class _BillingEntry {
  int? id;
  final int? taskId;
  String? resolvedCodeId;
  final TextEditingController codeController;
  final FocusNode codeFocusNode = FocusNode();
  final TextEditingController rateController;

  _BillingEntry({
    this.id,
    this.taskId,
    this.resolvedCodeId,
    String code = '',
    String rate = '',
  })  : codeController = TextEditingController(text: code),
        rateController = TextEditingController(text: rate);

  num get rate => num.tryParse(rateController.text.trim()) ?? 0;
  bool get hasCode => codeController.text.trim().isNotEmpty;

  void dispose() {
    codeController.dispose();
    codeFocusNode.dispose();
    rateController.dispose();
  }
}

class _TaskGroup {
  final int? taskId;
  final String label;
  final List<_BillingEntry> entries = [];
  _TaskGroup(this.taskId, this.label);
}

class _ProjectBillingSummaryPageState extends State<ProjectBillingSummaryPage> {
  final List<_TaskGroup> _groups = [];
  final List<int> _deletedIds = [];
  Map<String, String> _descToCode = {};
  bool _isLoading = true;
  bool _isSaving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final g in _groups) {
      for (final e in g.entries) {
        e.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final codes = await DbService.getBillingCodes();
      final tasks = await DbService.getTasks(widget.projectId);
      final billing = await DbService.getProjectBilling(widget.projectId);

      final descToCode = <String, String>{};
      final codeToDesc = <String, String>{};
      for (final c in codes) {
        final id = c['billing_code_id'] as String? ?? '';
        if (id.isEmpty) continue;
        final desc = c['description'] as String? ?? '';
        final shown = desc.isNotEmpty ? desc : id;
        codeToDesc[id] = shown;
        descToCode[shown] = id;
      }

      num seqOf(Map<String, dynamic> t) =>
          num.tryParse(t['sequence']?.toString() ?? '') ?? double.maxFinite;
      final sortedTasks = List<Map<String, dynamic>>.from(tasks)
        ..sort((a, b) => seqOf(a).compareTo(seqOf(b)));

      final groups = <int?, _TaskGroup>{};
      for (final t in sortedTasks) {
        final seq = t['sequence']?.toString() ?? '';
        final type = t['task_type'] as String? ?? '';
        final label = [seq, type].where((s) => s.isNotEmpty).join(' – ');
        final id = t['id'] as int;
        groups[id] = _TaskGroup(id, label.isEmpty ? 'Task $id' : label);
      }

      final loaded = <_BillingEntry>[];
      for (final b in billing) {
        final taskId = b['task_id'] as int?;
        final group = groups.putIfAbsent(
            taskId,
            () => _TaskGroup(
                taskId, taskId == null ? 'Project' : 'Task $taskId'));
        final code = b['billing_code_id'] as String? ?? '';
        final entry = _BillingEntry(
          id: b['id'] as int?,
          taskId: taskId,
          resolvedCodeId: code,
          code: codeToDesc[code] ?? code,
          rate: formatRate(b['rate']?.toString() ?? ''),
        );
        group.entries.add(entry);
        loaded.add(entry);
      }

      if (!mounted) return;
      final old = [for (final g in _groups) ...g.entries];
      for (final e in loaded) {
        _listen(e);
      }
      setState(() {
        _descToCode = descToCode;
        _groups
          ..clear()
          ..addAll(groups.values);
        _deletedIds.clear();
        _dirty = false;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final e in old) {
          e.dispose();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load: $e')),
      );
    }
  }

  void _listen(_BillingEntry e) {
    e.rateController.addListener(_markChanged);
    e.codeController.addListener(_markChanged);
  }

  void _markChanged() {
    if (!mounted) return;
    setState(() => _dirty = true);
  }

  void _addEntry(_TaskGroup g) {
    final e = _BillingEntry(taskId: g.taskId);
    _listen(e);
    setState(() {
      g.entries.add(e);
    });
  }

  Future<void> _removeEntry(_TaskGroup g, _BillingEntry e) async {
    if (e.id != null) {
      final confirmed =
          await confirmDelete(context, itemName: 'this billing row');
      if (!confirmed || !mounted) return;
    }
    setState(() {
      if (e.id != null) _deletedIds.add(e.id!);
      g.entries.remove(e);
      _dirty = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => e.dispose());
  }

  String _codeIdFor(_BillingEntry e) {
    final text = e.codeController.text.trim();
    final byDesc = _descToCode[text];
    if (byDesc != null) return byDesc;
    return text;
  }

  Future<void> _showMessage(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<bool> _save() async {
    FocusScope.of(context).unfocus();

    final all = [for (final g in _groups) ...g.entries];
    final toSave = all.where((e) => e.hasCode).toList();
    if (toSave.any((e) => e.rateController.text.trim().isEmpty)) {
      await _showMessage('Warning',
          'One or more billing entries are missing a rate. Please enter a rate before saving.');
      return false;
    }
    if (toSave
        .any((e) => num.tryParse(e.rateController.text.trim()) == null)) {
      await _showMessage('Warning',
          'One or more billing entries have an invalid rate. Please enter a number.');
      return false;
    }

    setState(() => _isSaving = true);
    String? error;
    try {
      for (final e in toSave) {
        await DbService.upsertBillingCode({'billing_code_id': _codeIdFor(e)});
      }
      for (final id in _deletedIds) {
        await DbService.deleteProjectBilling(id);
      }
      for (final e in all) {
        if (!e.hasCode) {
          // Saved rows whose code was cleared are removed.
          if (e.id != null) await DbService.deleteProjectBilling(e.id!);
          continue;
        }
        final data = {
          'billing_code_id': _codeIdFor(e),
          'rate': formatRate(e.rateController.text),
        };
        if (e.id != null) {
          await DbService.updateProjectBilling(e.id!, data);
        } else {
          await DbService.insertProjectBilling({
            'project_id': widget.projectId,
            'task_id': e.taskId,
            ...data,
          });
        }
      }
    } catch (e, st) {
      debugPrint('=== SAVE ERROR: $e\n$st ===');
      error = e.toString();
    }

    if (!mounted) return false;
    setState(() => _isSaving = false);
    if (error != null) {
      await _showMessage('Save Failed', error);
      return false;
    }
    await _load();
    return true;
  }

  Future<void> _close() async {
    if (_dirty) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unsaved changes'),
          content: const Text('Save your billing changes before closing?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, 'cancel'),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, 'discard'),
                child: const Text('Discard')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, 'save'),
                child: const Text('Save')),
          ],
        ),
      );
      if (!mounted || choice == null || choice == 'cancel') return;
      if (choice == 'save' && !await _save()) return;
    }
    if (!mounted) return;
    setState(() => _dirty = false);
    Navigator.pop(context);
  }

  String _money(num v) => '\$ ${v.toStringAsFixed(2)}';

  num _groupTotal(_TaskGroup g) =>
      g.entries.where((e) => e.hasCode).fold<num>(0, (s, e) => s + e.rate);

  Widget _codeField(_BillingEntry e) {
    return RawAutocomplete<String>(
      textEditingController: e.codeController,
      focusNode: e.codeFocusNode,
      displayStringForOption: (o) => o,
      optionsBuilder: (value) {
        final q = value.text.toLowerCase();
        if (q.isEmpty || _descToCode.keys.any((k) => k.toLowerCase() == q)) {
          return _descToCode.keys;
        }
        return _descToCode.keys.where((k) => k.toLowerCase().contains(q));
      },
      onSelected: (desc) {
        e.resolvedCodeId = _descToCode[desc] ?? desc;
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            hintText: 'Select or type new',
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_drop_down),
              tooltip: 'Show options',
              onPressed: () {
                focusNode.unfocus();
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => focusNode.requestFocus());
              },
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400, maxWidth: 400),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final option = options.elementAt(i);
                  return ListTile(
                    title: Text(option),
                    dense: true,
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _entryRow(_TaskGroup g, _BillingEntry e) {
    return Padding(
      key: ObjectKey(e),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 5, child: _codeField(e)),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Focus(
              onFocusChange: (has) {
                if (!has) applyRateFormat(e.rateController);
              },
              child: TextField(
                controller: e.rateController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  prefixText: '\$ ',
                  hintText: 'Rate',
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Remove',
            onPressed: () => _removeEntry(g, e),
          ),
        ],
      ),
    );
  }

  Widget _groupCard(_TaskGroup g) {
    return Card(
      key: ObjectKey(g),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(g.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Text(_money(_groupTotal(g)),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            for (final e in g.entries) _entryRow(g, e),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _addEntry(g),
                icon: const Icon(Icons.add),
                label: const Text('Add billing'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalsPanel() {
    final byCode = <String, num>{};
    final countByCode = <String, int>{};
    num grand = 0;
    int count = 0;
    for (final g in _groups) {
      for (final e in g.entries) {
        if (!e.hasCode) continue;
        final text = e.codeController.text.trim();
        grand += e.rate;
        count++;
        byCode[text] = (byCode[text] ?? 0) + e.rate;
        countByCode[text] = (countByCode[text] ?? 0) + 1;
      }
    }
    final billed =
        _groups.where((g) => g.entries.any((e) => e.hasCode)).toList();
    final taskCount = _groups.where((g) => g.taskId != null).length;
    final codes = byCode.keys.toList()..sort();
    const bold = TextStyle(fontWeight: FontWeight.bold);

    Widget line(String label, String value, {bool isBold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(child: Text(label, style: isBold ? bold : null)),
              Text(value, style: isBold ? bold : null),
            ],
          ),
        );

    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Project Totals',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            line('Project', widget.projectId),
            line('Tasks billed',
                '${billed.where((g) => g.taskId != null).length} of $taskCount'),
            line('Billing entries', '$count'),
            line('Average rate',
                count == 0 ? _money(0) : _money(grand / count)),
            const Divider(),
            line('Grand total', _money(grand), isBold: true),
            const SizedBox(height: 16),
            const Text('By Task', style: bold),
            const Divider(),
            if (billed.isEmpty) const Text('—'),
            for (final g in billed) line(g.label, _money(_groupTotal(g))),
            const SizedBox(height: 16),
            const Text('By Billing Code', style: bold),
            const Divider(),
            if (codes.isEmpty) const Text('—'),
            for (final c in codes)
              line('$c (×${countByCode[c]})', _money(byCode[c]!)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Billing — ${widget.projectId}')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(builder: (context, constraints) {
                      if (constraints.maxWidth < 800) {
                        return ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            SizedBox(height: 320, child: _totalsPanel()),
                            const SizedBox(height: 12),
                            for (final g in _groups) _groupCard(g),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _groups.isEmpty
                                ? const Center(
                                    child: Text('No tasks for this project.'))
                                : ListView(
                                    padding: const EdgeInsets.all(16),
                                    children: [
                                      for (final g in _groups) _groupCard(g)
                                    ],
                                  ),
                          ),
                          SizedBox(
                            width: 340,
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(0, 16, 16, 16),
                              child: _totalsPanel(),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _isSaving || !_dirty ? null : _save,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _close,
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
