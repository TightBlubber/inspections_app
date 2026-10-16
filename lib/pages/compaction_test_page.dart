import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/db.dart';

class CompactionTestPage extends StatefulWidget {
  final int taskId;

  const CompactionTestPage({super.key, required this.taskId});

  @override
  State<CompactionTestPage> createState() => _CompactionTestPageState();
}

class _CompactionTestPageState extends State<CompactionTestPage> {
  static const _testTypes = [
    '',
    'ASTM D-698 Procedure A',
    'ASTM D-698 Procedure B',
    'ASTM D-698 Procedure C',
    'ASTM D-1557 Procedure A',
    'ASTM D-1557 Procedure B',
    'ASTM D-1557 Procedure C',
  ];

  static const _detailHeaders = [
    'Weight wet sample + mold',
    'Weight wet sample + can',
    'Weight dry sample + can',
    'Weight of can',
  ];

  final _source = TextEditingController();
  final _hammerWeight = TextEditingController();
  final _dropDistance = TextEditingController();
  final _layers = TextEditingController();
  final _blows = TextEditingController();
  final _material = TextEditingController();
  final _maxDryDensity = TextEditingController();
  final _optMoisture = TextEditingController();
  final _maxDensityOc = TextEditingController();
  final _optMoistOc = TextEditingController();

  final List<List<TextEditingController>> _detailRows = [];

  List<String> _testTypeOptions = _testTypes.toList();
  List<String> _moldNumbers = [''];
  String _testType = '';
  String _moldNumber = '';
  bool _isLoading = true;

  List<TextEditingController> get _headerControllers => [
    _source,
    _hammerWeight,
    _dropDistance,
    _layers,
    _blows,
    _material,
    _maxDryDensity,
    _optMoisture,
    _maxDensityOc,
    _optMoistOc,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _headerControllers) {
      c.dispose();
    }
    for (final row in _detailRows) {
      for (final c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  // A trailing blank row is kept so more readings can always be entered.
  List<TextEditingController> _makeDetailRow([List<String>? values]) {
    final row = List.generate(
      4,
      (i) => TextEditingController(text: values == null ? '' : values[i]),
    );
    for (final c in row) {
      c.addListener(() {
        if (_detailRows.isNotEmpty &&
            identical(_detailRows.last, row) &&
            row.any((c) => c.text.isNotEmpty)) {
          setState(() => _detailRows.add(_makeDetailRow()));
        }
      });
    }
    return row;
  }

  String _fmt(dynamic v) => v == null ? '' : '$v';

  Future<void> _load() async {
    try {
      final molds = await DbService.getMolds();
      final test = await DbService.getCompactionTest(widget.taskId);
      final details = await DbService.getCompactionTestDetails(widget.taskId);
      if (!mounted) return;

      final moldNumbers = [
        '',
        ...molds
            .map((m) => m['mold_number'] as String? ?? '')
            .where((m) => m.isNotEmpty),
      ];
      final savedType = test?['test_type'] as String? ?? '';
      final savedMold = test?['mold_number'] as String? ?? '';
      final types = _testTypes.toList();
      if (savedType.isNotEmpty && !types.contains(savedType)) {
        types.insert(1, savedType);
      }
      if (savedMold.isNotEmpty && !moldNumbers.contains(savedMold)) {
        moldNumbers.insert(1, savedMold);
      }

      setState(() {
        _testTypeOptions = types;
        _moldNumbers = moldNumbers;
        _testType = savedType;
        _moldNumber = savedMold;
        if (test != null) {
          _source.text = _fmt(test['source']);
          _hammerWeight.text = _fmt(test['hammer_weight']);
          _dropDistance.text = _fmt(test['drop_distance']);
          _layers.text = _fmt(test['number_of_layers']);
          _blows.text = _fmt(test['number_of_blows']);
          _material.text = _fmt(test['material_description']);
          _maxDryDensity.text = _fmt(test['max_dry_density']);
          _optMoisture.text = _fmt(test['opt_moisture']);
          _maxDensityOc.text = _fmt(test['max_density_oc']);
          _optMoistOc.text = _fmt(test['opt_moist_oc']);
        }
        for (final d in details) {
          _detailRows.add(
            _makeDetailRow([
              _fmt(d['wt_wet_sample_mold']),
              _fmt(d['wt_wet_sample_can']),
              _fmt(d['wt_dry_sample_can']),
              _fmt(d['wt_can']),
            ]),
          );
        }
        _detailRows.add(_makeDetailRow());
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_detailRows.isEmpty) _detailRows.add(_makeDetailRow());
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
    }
  }

  num? _num(TextEditingController c) => num.tryParse(c.text.trim());

  String? _textOrNull(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _save() async {
    try {
      await DbService.upsertCompactionTest({
        'task_id': widget.taskId,
        'source': _textOrNull(_source),
        'hammer_weight': _num(_hammerWeight),
        'drop_distance': _num(_dropDistance),
        'number_of_layers': _num(_layers)?.toInt(),
        'number_of_blows': _num(_blows)?.toInt(),
        'test_type': _testType.isEmpty ? null : _testType,
        'mold_number': _moldNumber.isEmpty ? null : _moldNumber,
        'material_description': _textOrNull(_material),
        'max_dry_density': _num(_maxDryDensity),
        'opt_moisture': _num(_optMoisture),
        'max_density_oc': _num(_maxDensityOc),
        'opt_moist_oc': _num(_optMoistOc),
      });
      final details = <Map<String, dynamic>>[];
      for (final row in _detailRows) {
        if (row.every((c) => c.text.trim().isEmpty)) continue;
        details.add({
          'task_id': widget.taskId,
          'sequence': details.length + 1,
          'wt_wet_sample_mold': _num(row[0]),
          'wt_wet_sample_can': _num(row[1]),
          'wt_dry_sample_can': _num(row[2]),
          'wt_can': _num(row[3]),
        });
      }
      await DbService.replaceCompactionTestDetails(widget.taskId, details);
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
      appBar: AppBar(title: const Text('Compaction Test')),
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
          _box('Task ID', _readOnly('${widget.taskId}'), flex: 2),
          _box('Source', _textField(_source), flex: 4),
          _box('Hammer Weight', _numberField(_hammerWeight), flex: 3),
          _box('Drop Distance', _numberField(_dropDistance), flex: 3),
          _box(
            'Number of Layers',
            _numberField(_layers, decimal: false),
            flex: 3,
          ),
        ]),
        _row([
          _box('Number of Blows', _numberField(_blows, decimal: false)),
          _box(
            'Type of Test',
            _dropdown(
              _testTypeOptions,
              _testType,
              (v) => setState(() => _testType = v ?? ''),
            ),
            flex: 4,
          ),
          _box(
            'Mold Number',
            _dropdown(
              _moldNumbers,
              _moldNumber,
              (v) => setState(() => _moldNumber = v ?? ''),
            ),
          ),
          _box('Material Description', _textField(_material), flex: 5),
        ]),
        _row([
          _box('Max Dry Density', _numberField(_maxDryDensity)),
          _box('Opt Moisture', _numberField(_optMoisture)),
          _box('Max Density w/OC', _numberField(_maxDensityOc)),
          _box('Opt Moist w/OC', _numberField(_optMoistOc)),
        ]),
        const SizedBox(height: 8),
        const Text(
          'Compaction Test Detail',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildDetailGrid(),
      ],
    );
  }

  Widget _buildDetailGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final h in _detailHeaders)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    h,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (final row in _detailRows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                for (final c in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _numberField(c),
                    ),
                  ),
              ],
            ),
          ),
      ],
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

  Widget _box(String label, Widget child, {int flex = 3}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            child,
          ],
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
        fillColor: Colors.grey.shade100,
      ),
      child: Text(value, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _textField(TextEditingController controller) =>
      TextField(controller: controller, decoration: _decoration());

  Widget _numberField(TextEditingController controller, {bool decimal = true}) {
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

  Widget _dropdown(
    List<String> options,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: _decoration(),
      items: options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: onChanged,
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
            : Colors.grey.shade200,
        foregroundColor: primary ? Colors.white : Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
}
