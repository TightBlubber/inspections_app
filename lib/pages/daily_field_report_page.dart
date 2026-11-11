import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/db.dart';
import '../widgets/neutral_button_colors.dart';

/// True when a task type description refers to a daily field report.
bool isDailyFieldReportType(String taskType) {
  final t = taskType.toLowerCase();
  return t.contains('daily') && t.contains('field');
}

class DailyFieldReportPage extends StatefulWidget {
  final int taskId;

  const DailyFieldReportPage({super.key, required this.taskId});

  @override
  State<DailyFieldReportPage> createState() => _DailyFieldReportPageState();
}

class _Section {
  final String key;
  final String label;
  final List<(String, String)> options; // (column suffix, label)
  final bool hasDescribe;

  const _Section(this.key, this.label, this.options, {this.hasDescribe = true});
}

class _DailyFieldReportPageState extends State<DailyFieldReportPage> {
  static const _sections = [
    _Section('soils', 'Soils', [
      ('foundation', 'Foundation'),
      ('controlled', 'Controlled'),
      ('other', 'Other'),
    ]),
    _Section('asphalt', 'Asphalt', [
      ('batch_plant', 'Batch Plant'),
      ('placement', 'Placement'),
      ('other', 'Other'),
    ]),
    _Section('concrete', 'Concrete', [
      ('batch_plant', 'Batch Plant'),
      ('placement', 'Placement'),
      ('pickup', 'PickUp'),
      ('other', 'Other'),
    ]),
    _Section('other', 'Other', [], hasDescribe: true),
  ];

  final _weather = TextEditingController();
  final _lowTemp = TextEditingController();
  final _highTemp = TextEditingController();
  final _notes = TextEditingController();

  // Keyed by column name, e.g. "soils", "soils_foundation", "soils_describe".
  final Map<String, bool> _checks = {};
  final Map<String, TextEditingController> _describe = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    for (final s in _sections) {
      _checks[s.key] = false;
      for (final o in s.options) {
        _checks['${s.key}_${o.$1}'] = false;
      }
      if (s.hasDescribe) {
        _describe['${s.key}_describe'] = TextEditingController();
      }
    }
    _load();
  }

  @override
  void dispose() {
    _weather.dispose();
    _lowTemp.dispose();
    _highTemp.dispose();
    _notes.dispose();
    for (final c in _describe.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmt(dynamic v) => v == null ? '' : '$v';

  Future<void> _load() async {
    try {
      final report = await DbService.getDailyFieldReport(widget.taskId);
      if (!mounted) return;
      setState(() {
        if (report != null) {
          _weather.text = _fmt(report['weather']);
          _lowTemp.text = _fmt(report['low_temp']);
          _highTemp.text = _fmt(report['high_temp']);
          _notes.text = _fmt(report['notes']);
          for (final k in _checks.keys.toList()) {
            _checks[k] = report[k] == true;
          }
          for (final e in _describe.entries) {
            e.value.text = _fmt(report[e.key]);
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
    }
  }

  String? _textOrNull(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _save() async {
    try {
      await DbService.upsertDailyFieldReport({
        'task_id': widget.taskId,
        'weather': _textOrNull(_weather),
        'low_temp': num.tryParse(_lowTemp.text.trim()),
        'high_temp': num.tryParse(_highTemp.text.trim()),
        'notes': _textOrNull(_notes),
        ..._checks,
        for (final e in _describe.entries) e.key: _textOrNull(e.value),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Field Report')),
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
                      _bottomButton('Save', _save, primary: true),
                      const SizedBox(width: 8),
                      _bottomButton('Cancel', () => Navigator.pop(context)),
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
        _row([
          _box('Report Number', _readOnly('${widget.taskId}')),
          _box('Low Temperature', _numberField(_lowTemp)),
          _box('High Temperature', _numberField(_highTemp)),
        ]),
        _label('Weather'),
        const SizedBox(height: 4),
        TextField(
          controller: _weather,
          minLines: 2,
          maxLines: 3,
          decoration: _decoration(),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [for (final s in _sections) _buildSection(s)],
        ),
        const SizedBox(height: 16),
        _label('Notes'),
        const SizedBox(height: 4),
        TextField(
          controller: _notes,
          minLines: 4,
          maxLines: 8,
          decoration: _decoration(),
        ),
      ],
    );
  }

  Widget _buildSection(_Section s) {
    return SizedBox(
      width: 240,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _check(s.key, s.label, bold: true),
              for (final o in s.options)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _check('${s.key}_${o.$1}', o.$2),
                ),
              if (s.hasDescribe)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  child: TextField(
                    controller: _describe['${s.key}_describe'],
                    decoration: _decoration().copyWith(labelText: 'Describe'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _check(String key, String label, {bool bold = false}) {
    return CheckboxListTile(
      value: _checks[key] ?? false,
      onChanged: (v) => setState(() => _checks[key] = v ?? false),
      title: Text(
        label,
        style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
      ),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _row(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.bold));

  Widget _box(String label, Widget child) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_label(label), const SizedBox(height: 4), child],
        ),
      ),
    );
  }

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

  Widget _numberField(TextEditingController controller) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))],
      decoration: _decoration(),
    );
  }

  Widget _bottomButton(
    String label,
    VoidCallback onPressed, {
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
