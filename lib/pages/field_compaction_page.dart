import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/db.dart';
import '../widgets/neutral_button_colors.dart';

/// True when a task type description refers to a field compaction test.
bool isFieldCompactionType(String taskType) {
  final t = taskType.toLowerCase();
  return t.contains('field') && t.contains('compaction');
}

enum _Kind { text, integer, decimal }

class _Col {
  final String key;
  final String label;
  final _Kind kind;
  final double width;

  const _Col(this.key, this.label, this.kind, this.width);
}

class _DetailRow {
  final Map<String, TextEditingController> controllers;
  String soilNumber;
  String materialType;
  final Map<String, bool> flags;

  _DetailRow(this.controllers, this.soilNumber, this.materialType, this.flags);

  bool get isBlank =>
      soilNumber.isEmpty &&
      materialType.isEmpty &&
      !flags.values.any((v) => v) &&
      controllers.values.every((c) => c.text.trim().isEmpty);
}

class FieldCompactionPage extends StatefulWidget {
  final int taskId;

  const FieldCompactionPage({super.key, required this.taskId});

  @override
  State<FieldCompactionPage> createState() => _FieldCompactionPageState();
}

class _FieldCompactionPageState extends State<FieldCompactionPage> {
  static const _materialTypes = [
    '',
    'Fill Material',
    'Backfill',
    'Base Course',
    'Subbase',
    'Soil Cement',
    'Other',
  ];
  static const _flagKeys = ['a', 'b', 'c', 'd', 'e'];

  static const _testNumber = _Col(
    'test_number',
    'Test Number',
    _Kind.integer,
    70,
  );
  static const _afterSoil = [
    _Col('test_depth', 'Test Depth', _Kind.text, 80),
    _Col('elevation', 'Elevation', _Kind.text, 90),
    _Col('moisture_content', 'Moisture Content', _Kind.decimal, 90),
    _Col('wet_density', 'Wet Density', _Kind.decimal, 90),
  ];
  static const _location = _Col('location', 'Location', _Kind.text, 200);
  static const _soilWidth = 90.0;
  static const _materialWidth = 180.0;
  static const _flagWidth = 40.0;

  static List<_Col> get _detailCols => [_testNumber, ..._afterSoil, _location];

  final _gaugeType = TextEditingController();
  final _gaugeModel = TextEditingController();
  final _compactionReq = TextEditingController();
  final _moistureReq = TextEditingController();
  final _generalLocation = TextEditingController();
  final _comments = TextEditingController();
  final List<_DetailRow> _rows = [];

  List<String> _soilNumbers = [''];
  Map<String, String> _soilDensities = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _gaugeType,
      _gaugeModel,
      _compactionReq,
      _moistureReq,
      _generalLocation,
      _comments,
    ]) {
      c.dispose();
    }
    for (final r in _rows) {
      for (final c in r.controllers.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  String _fmt(dynamic v) => v == null ? '' : '$v';

  // A trailing blank row is kept so more tests can always be entered.
  _DetailRow _makeRow([Map<String, dynamic>? v]) {
    final row = _DetailRow(
      {
        for (final c in _detailCols)
          c.key: TextEditingController(text: v == null ? '' : _fmt(v[c.key])),
      },
      v == null ? '' : _fmt(v['soil_number']),
      v == null ? '' : _fmt(v['material_type']),
      {for (final k in _flagKeys) k: v?[k] == true},
    );
    for (final c in row.controllers.values) {
      c.addListener(() => _growIfNeeded(row));
    }
    return row;
  }

  void _growIfNeeded(_DetailRow row) {
    if (_rows.isNotEmpty && identical(_rows.last, row) && !row.isBlank) {
      setState(() => _rows.add(_makeRow()));
    }
  }

  Future<void> _load() async {
    try {
      final task = await DbService.getTask(widget.taskId);
      final projectId = _fmt(task?['project_id']);
      final proctors = projectId.isEmpty
          ? <Map<String, dynamic>>[]
          : await DbService.getProctors(projectId);
      final report = await DbService.getFieldCompaction(widget.taskId);
      final details = await DbService.getFieldCompactionDetails(widget.taskId);
      if (!mounted) return;

      final soils =
          proctors
              .map((p) => _fmt(p['soil_no']))
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList()
            ..sort((a, b) {
              final na = int.tryParse(a);
              final nb = int.tryParse(b);
              return na != null && nb != null
                  ? na.compareTo(nb)
                  : a.compareTo(b);
            });

      setState(() {
        _soilNumbers = ['', ...soils];
        _soilDensities = {
          for (final p in proctors)
            if (_fmt(p['soil_no']).isNotEmpty)
              _fmt(p['soil_no']): _fmt(p['max_dry_density']),
        };
        if (report != null) {
          _gaugeType.text = _fmt(report['gauge_type']);
          _gaugeModel.text = _fmt(report['gauge_model']);
          _compactionReq.text = _fmt(report['compaction_requirements']);
          _moistureReq.text = _fmt(report['moisture_requirements']);
          _generalLocation.text = _fmt(report['general_location']);
          _comments.text = _fmt(report['comments']);
        }
        for (final d in details) {
          _rows.add(_makeRow(d));
        }
        _rows.add(_makeRow());
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_rows.isEmpty) _rows.add(_makeRow());
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
    }
  }

  dynamic _value(_Kind kind, String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    switch (kind) {
      case _Kind.text:
        return t;
      case _Kind.integer:
        return int.tryParse(t);
      case _Kind.decimal:
        return num.tryParse(t);
    }
  }

  Future<void> _save() async {
    try {
      String? textOrNull(TextEditingController c) =>
          c.text.trim().isEmpty ? null : c.text.trim();

      await DbService.upsertFieldCompaction({
        'task_id': widget.taskId,
        'gauge_type': textOrNull(_gaugeType),
        'gauge_model': textOrNull(_gaugeModel),
        'compaction_requirements': textOrNull(_compactionReq),
        'moisture_requirements': textOrNull(_moistureReq),
        'general_location': textOrNull(_generalLocation),
        'comments': textOrNull(_comments),
      });

      final details = <Map<String, dynamic>>[];
      for (final row in _rows) {
        if (row.isBlank) continue;
        details.add({
          'task_id': widget.taskId,
          'sequence': details.length + 1,
          for (final c in _detailCols)
            c.key: _value(c.kind, row.controllers[c.key]!.text),
          'soil_number': int.tryParse(row.soilNumber),
          'material_type': row.materialType.isEmpty ? null : row.materialType,
          ...row.flags,
        });
      }
      await DbService.replaceFieldCompactionDetails(widget.taskId, details);
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
      appBar: AppBar(title: const Text('Field Compaction Test')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _box('Task ID', _readOnly('${widget.taskId}'), 2),
            _box('Gauge Type', _textField(_gaugeType), 3),
            _box('Gauge Model', _textField(_gaugeModel), 3),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _box('Compaction Requirements', _textField(_compactionReq), 4),
            _box('Moisture Requirements', _textField(_moistureReq), 4),
          ],
        ),
        const SizedBox(height: 12),
        _label('General Location'),
        const SizedBox(height: 4),
        TextField(controller: _generalLocation, decoration: _decoration()),
        const SizedBox(height: 12),
        _label('Comments'),
        const SizedBox(height: 4),
        TextField(
          controller: _comments,
          minLines: 3,
          maxLines: 6,
          decoration: _decoration(),
        ),
        const SizedBox(height: 16),
        _label('Field Compaction Detail'),
        const SizedBox(height: 8),
        _buildDetailGrid(),
      ],
    );
  }

  Widget _buildDetailGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _cell(_testNumber.width, _headerText(_testNumber.label)),
              _cell(_soilWidth, _headerText('Soil Number')),
              for (final c in _afterSoil) _cell(c.width, _headerText(c.label)),
              _cell(_materialWidth, _headerText('Material Type')),
              for (final k in _flagKeys)
                _cell(_flagWidth, _headerText(k.toUpperCase())),
              _cell(_location.width, _headerText(_location.label)),
            ],
          ),
          const SizedBox(height: 6),
          for (final row in _rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  _cell(
                    _testNumber.width,
                    _numberOrText(
                      row.controllers[_testNumber.key]!,
                      _testNumber,
                    ),
                  ),
                  _cell(
                    _soilWidth,
                    _dropdown(
                      _soilNumbers,
                      row.soilNumber,
                      (v) => _onRowChanged(row, () => row.soilNumber = v ?? ''),
                      details: _soilDensities,
                    ),
                  ),
                  for (final c in _afterSoil)
                    _cell(c.width, _numberOrText(row.controllers[c.key]!, c)),
                  _cell(
                    _materialWidth,
                    _dropdown(
                      _materialTypes,
                      row.materialType,
                      (v) =>
                          _onRowChanged(row, () => row.materialType = v ?? ''),
                    ),
                  ),
                  for (final k in _flagKeys)
                    SizedBox(
                      width: _flagWidth,
                      child: Checkbox(
                        value: row.flags[k],
                        onChanged: (v) =>
                            _onRowChanged(row, () => row.flags[k] = v ?? false),
                      ),
                    ),
                  _cell(
                    _location.width,
                    _numberOrText(row.controllers[_location.key]!, _location),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _onRowChanged(_DetailRow row, VoidCallback change) {
    setState(change);
    _growIfNeeded(row);
  }

  Widget _dropdown(
    List<String> options,
    String value,
    ValueChanged<String?> onChanged, {
    Map<String, String>? details,
  }) {
    final items = [...options, if (!options.contains(value)) value];
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: _decoration(),
      items: items
          .map(
            (o) => DropdownMenuItem(
              value: o,
              child: details == null
                  ? Text(o)
                  : Row(
                      children: [
                        SizedBox(width: 40, child: Text(o)),
                        Text(details[o] ?? ''),
                      ],
                    ),
            ),
          )
          .toList(),
      selectedItemBuilder: details == null
          ? null
          : (_) => items.map((o) => Text(o)).toList(),
      onChanged: onChanged,
    );
  }

  Widget _cell(double width, Widget child) => SizedBox(
    width: width,
    child: Padding(padding: const EdgeInsets.only(right: 8), child: child),
  );

  Widget _headerText(String text) => Text(
    text,
    textAlign: TextAlign.center,
    style: const TextStyle(fontWeight: FontWeight.bold),
  );

  Widget _label(String text) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.bold));

  Widget _box(String label, Widget child, int flex) {
    return Expanded(
      flex: flex,
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

  Widget _textField(TextEditingController controller) =>
      TextField(controller: controller, decoration: _decoration());

  Widget _numberOrText(TextEditingController controller, _Col col) {
    if (col.kind == _Kind.text) return _textField(controller);
    final decimal = col.kind == _Kind.decimal;
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimal ? RegExp(r'[0-9.\-]') : RegExp(r'[0-9\-]'),
        ),
      ],
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
