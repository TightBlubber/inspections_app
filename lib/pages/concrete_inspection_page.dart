import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/db.dart';
import '../widgets/neutral_button_colors.dart';

/// True when a task type description refers to a field inspection of concrete.
bool isConcreteInspectionType(String taskType) {
  final t = taskType.toLowerCase();
  return t.contains('inspection') && t.contains('concrete');
}

enum _Kind { text, integer, decimal }

class _Field {
  final String key;
  final String label;
  final _Kind kind;
  final double width;

  const _Field(this.key, this.label, this.kind, [this.width = 150]);
}

class _DetailRow {
  final Map<String, TextEditingController> controllers;
  String resultsComply;

  _DetailRow(this.controllers, this.resultsComply);

  bool get isBlank =>
      resultsComply.isEmpty &&
      controllers.values.every((c) => c.text.trim().isEmpty);
}

class ConcreteInspectionPage extends StatefulWidget {
  final int taskId;

  const ConcreteInspectionPage({super.key, required this.taskId});

  @override
  State<ConcreteInspectionPage> createState() => _ConcreteInspectionPageState();
}

class _ConcreteInspectionPageState extends State<ConcreteInspectionPage> {
  static const _materials = ['Concrete', 'Grout', 'Mortar', 'Beam'];
  static const _complyOptions = ['', 'Yes', 'No'];

  static const _headerFields = [
    _Field('supplier_name', 'Supplier Name', _Kind.text, 200),
    _Field('mix_number', 'Mix Number', _Kind.text),
    _Field('design_strength', 'Design Strength', _Kind.decimal),
    _Field('cement_bags', 'Cement Bags', _Kind.decimal),
    _Field('water', 'Water', _Kind.decimal),
    _Field('fine_aggregate', 'Fine Aggregate', _Kind.decimal),
    _Field('coarse_aggregate', 'Coarse Aggregate', _Kind.decimal),
    _Field('size', 'Size', _Kind.text),
    _Field('admixture1', 'AdMixture1', _Kind.decimal),
    _Field('admixture2', 'AdMixture2', _Kind.decimal),
    _Field('admixture3', 'AdMixture3', _Kind.decimal),
    _Field('other', 'Other', _Kind.decimal),
    _Field('cubic_yards', 'Cubic Yards', _Kind.decimal),
    _Field('placed_by', 'Placed By', _Kind.text, 200),
  ];

  static const _detailFields = [
    _Field('set_number', 'Set Number', _Kind.integer, 80),
    _Field('number_cylinders', 'Number Cylinders', _Kind.integer, 100),
    _Field('ticket_number', 'Ticket Number', _Kind.text, 100),
    _Field('dispatch_time', 'Dispatch Time', _Kind.text, 100),
    _Field('time_made', 'Time Made', _Kind.text, 100),
    _Field('unload_time', 'Unload Time', _Kind.text, 100),
    _Field('cubic_yards', 'Cubic Yards', _Kind.decimal, 90),
    _Field('slump_inches', 'Slump Inches', _Kind.decimal, 90),
    _Field('air_content', 'Air Content', _Kind.decimal, 90),
    _Field('air_temp', 'Air Temp', _Kind.decimal, 90),
    _Field('concrete_temp', 'Concrete Temp', _Kind.decimal, 100),
    _Field('location', 'Location', _Kind.text, 180),
  ];
  static const _complyWidth = 90.0;

  final _generalLocation = TextEditingController();
  final _comments = TextEditingController();
  final _dateReceived = TextEditingController();
  final Map<String, TextEditingController> _header = {
    for (final f in _headerFields) f.key: TextEditingController(),
  };
  final List<_DetailRow> _rows = [];

  String _material = '';
  bool _madeByUs = false;
  bool _pickedByUs = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _generalLocation.dispose();
    _comments.dispose();
    _dateReceived.dispose();
    for (final c in _header.values) {
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

  // The database stores ISO dates; the UI shows MM/DD/YYYY like the rest of the app.
  String _isoToDisplay(dynamic v) {
    final d = DateTime.tryParse(_fmt(v));
    if (d == null) return _fmt(v);
    return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
  }

  String? _displayToIso(String text) {
    final m = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(text.trim());
    if (m == null) return null;
    return '${m.group(3)}-${m.group(1)!.padLeft(2, '0')}-${m.group(2)!.padLeft(2, '0')}';
  }

  // A trailing blank row is kept so more sets can always be entered.
  _DetailRow _makeRow([Map<String, dynamic>? values]) {
    final row = _DetailRow({
      for (final f in _detailFields)
        f.key: TextEditingController(
          text: values == null ? '' : _fmt(values[f.key]),
        ),
    }, values == null ? '' : _fmt(values['results_comply']));
    void grow() {
      if (_rows.isNotEmpty && identical(_rows.last, row) && !row.isBlank) {
        setState(() => _rows.add(_makeRow()));
      }
    }

    for (final c in row.controllers.values) {
      c.addListener(grow);
    }
    return row;
  }

  Future<void> _load() async {
    try {
      final inspection = await DbService.getConcreteInspection(widget.taskId);
      final details = await DbService.getConcreteInspectionDetails(
        widget.taskId,
      );
      if (!mounted) return;
      setState(() {
        if (inspection != null) {
          final saved = _fmt(inspection['material_tested']);
          _material = saved;
          _generalLocation.text = _fmt(inspection['general_location']);
          _comments.text = _fmt(inspection['comments']);
          _dateReceived.text = _isoToDisplay(inspection['date_received']);
          _madeByUs = inspection['cylinders_made_by_us'] == true;
          _pickedByUs = inspection['cylinders_picked_by_us'] == true;
          for (final f in _headerFields) {
            _header[f.key]!.text = _fmt(inspection[f.key]);
          }
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

  dynamic _value(_Field f, String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    switch (f.kind) {
      case _Kind.text:
        return t;
      case _Kind.integer:
        return int.tryParse(t);
      case _Kind.decimal:
        return num.tryParse(t);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _dateReceived.text =
          '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  Future<void> _save() async {
    try {
      final dateText = _dateReceived.text.trim();
      final dateIso = _displayToIso(dateText);
      if (dateText.isNotEmpty && dateIso == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Date Received must be MM/DD/YYYY.')),
        );
        return;
      }
      String? textOrNull(TextEditingController c) =>
          c.text.trim().isEmpty ? null : c.text.trim();

      await DbService.upsertConcreteInspection({
        'task_id': widget.taskId,
        'material_tested': _material.isEmpty ? null : _material,
        'general_location': textOrNull(_generalLocation),
        'comments': textOrNull(_comments),
        'date_received': dateIso,
        'cylinders_made_by_us': _madeByUs,
        'cylinders_picked_by_us': _pickedByUs,
        for (final f in _headerFields) f.key: _value(f, _header[f.key]!.text),
      });

      final details = <Map<String, dynamic>>[];
      for (final row in _rows) {
        if (row.isBlank) continue;
        details.add({
          'task_id': widget.taskId,
          'sequence': details.length + 1,
          for (final f in _detailFields)
            f.key: _value(f, row.controllers[f.key]!.text),
          'results_comply': row.resultsComply.isEmpty
              ? null
              : row.resultsComply,
        });
      }
      await DbService.replaceConcreteInspectionDetails(widget.taskId, details);
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
      appBar: AppBar(title: const Text('Field Inspection of Concrete')),
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
        _label('Material Tested'),
        const SizedBox(height: 4),
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String>(
            initialValue: _material,
            isExpanded: true,
            decoration: _decoration(),
            items: [
              '',
              ..._materials,
              if (!_materials.contains(_material) && _material.isNotEmpty)
                _material,
            ].map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
            onChanged: (v) => setState(() => _material = v ?? ''),
          ),
        ),
        const SizedBox(height: 12),
        _label('General Location'),
        const SizedBox(height: 4),
        TextField(
          controller: _generalLocation,
          minLines: 2,
          maxLines: 4,
          decoration: _decoration(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: [
            for (final f in _headerFields)
              SizedBox(
                width: f.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(f.label),
                    const SizedBox(height: 4),
                    _input(_header[f.key]!, f),
                  ],
                ),
              ),
            SizedBox(
              width: 170,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Date Received'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _dateReceived,
                    readOnly: true,
                    decoration: _decoration().copyWith(
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        onPressed: _pickDate,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 24,
          children: [
            _checkbox(
              'Cylinders Made By Us',
              _madeByUs,
              (v) => setState(() => _madeByUs = v),
            ),
            _checkbox(
              'Cylinders Picked Up By Us',
              _pickedByUs,
              (v) => setState(() => _pickedByUs = v),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _label('Comments'),
        const SizedBox(height: 4),
        TextField(
          controller: _comments,
          minLines: 3,
          maxLines: 6,
          decoration: _decoration(),
        ),
        const SizedBox(height: 16),
        _label('Concrete Inspection Detail'),
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
              for (final f in _detailFields) _cell(f.width, _header2(f.label)),
              _cell(_complyWidth, _header2('Results Comply')),
            ],
          ),
          const SizedBox(height: 6),
          for (final row in _rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  for (final f in _detailFields)
                    _cell(f.width, _input(row.controllers[f.key]!, f)),
                  _cell(
                    _complyWidth,
                    DropdownButtonFormField<String>(
                      initialValue: row.resultsComply,
                      isExpanded: true,
                      decoration: _decoration(),
                      items:
                          [
                                ..._complyOptions,
                                if (!_complyOptions.contains(row.resultsComply))
                                  row.resultsComply,
                              ]
                              .map(
                                (o) =>
                                    DropdownMenuItem(value: o, child: Text(o)),
                              )
                              .toList(),
                      onChanged: (v) {
                        setState(() => row.resultsComply = v ?? '');
                        if (identical(_rows.last, row) && !row.isBlank) {
                          setState(() => _rows.add(_makeRow()));
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(double width, Widget child) => SizedBox(
    width: width,
    child: Padding(padding: const EdgeInsets.only(right: 8), child: child),
  );

  Widget _header2(String text) => Text(
    text,
    textAlign: TextAlign.center,
    style: const TextStyle(fontWeight: FontWeight.bold),
  );

  Widget _checkbox(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _label(String text) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.bold));

  InputDecoration _decoration() => const InputDecoration(
    border: OutlineInputBorder(),
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  );

  Widget _input(TextEditingController controller, _Field f) {
    if (f.kind == _Kind.text) {
      return TextField(controller: controller, decoration: _decoration());
    }
    final decimal = f.kind == _Kind.decimal;
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
