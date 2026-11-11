import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/db.dart';
import '../widgets/neutral_button_colors.dart';

/// True when a task type description refers to a field inspection of footings.
bool isFootingInspectionType(String taskType) {
  final t = taskType.toLowerCase();
  return t.contains('inspection') && t.contains('footing');
}

class _DetailRow {
  final TextEditingController location;
  final TextEditingController elevation;
  final TextEditingController bearingCapacity;
  final TextEditingController remarks;

  _DetailRow({
    String location = '',
    String elevation = '',
    String bearingCapacity = '',
    String remarks = '',
  }) : location = TextEditingController(text: location),
       elevation = TextEditingController(text: elevation),
       bearingCapacity = TextEditingController(text: bearingCapacity),
       remarks = TextEditingController(text: remarks);

  List<TextEditingController> get all => [
    location,
    elevation,
    bearingCapacity,
    remarks,
  ];

  bool get isBlank => all.every((c) => c.text.trim().isEmpty);

  void dispose() {
    for (final c in all) {
      c.dispose();
    }
  }
}

class FootingInspectionPage extends StatefulWidget {
  final int taskId;

  const FootingInspectionPage({super.key, required this.taskId});

  @override
  State<FootingInspectionPage> createState() => _FootingInspectionPageState();
}

class _FootingInspectionPageState extends State<FootingInspectionPage> {
  static const _locationWidth = 140.0;
  static const _elevationWidth = 140.0;
  static const _bearingWidth = 150.0;
  static const _remarksWidth = 300.0;

  final _otherDesc = TextEditingController();
  final _generalLocation = TextEditingController();
  final List<_DetailRow> _rows = [];

  bool _column = false;
  bool _continuousWall = false;
  bool _other = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _otherDesc.dispose();
    _generalLocation.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  String _fmt(dynamic v) => v == null ? '' : '$v';

  // A trailing blank row is kept so more footings can always be entered.
  _DetailRow _makeRow([Map<String, dynamic>? v]) {
    final row = v == null
        ? _DetailRow()
        : _DetailRow(
            location: _fmt(v['location']),
            elevation: _fmt(v['elevation']),
            bearingCapacity: _fmt(v['bearing_capacity']),
            remarks: _fmt(v['remarks']),
          );
    for (final c in row.all) {
      c.addListener(() {
        if (_rows.isNotEmpty && identical(_rows.last, row) && !row.isBlank) {
          setState(() => _rows.add(_makeRow()));
        }
      });
    }
    return row;
  }

  Future<void> _load() async {
    try {
      final inspection = await DbService.getFootingInspection(widget.taskId);
      final details = await DbService.getFootingInspectionDetails(
        widget.taskId,
      );
      if (!mounted) return;
      setState(() {
        if (inspection != null) {
          _column = inspection['footing_column'] == true;
          _continuousWall = inspection['continuous_wall'] == true;
          _other = inspection['other'] == true;
          _otherDesc.text = _fmt(inspection['other_description']);
          _generalLocation.text = _fmt(inspection['general_location']);
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

  String? _textOrNull(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _save() async {
    try {
      await DbService.upsertFootingInspection({
        'task_id': widget.taskId,
        'footing_column': _column,
        'continuous_wall': _continuousWall,
        'other': _other,
        'other_description': _textOrNull(_otherDesc),
        'general_location': _textOrNull(_generalLocation),
      });
      final details = <Map<String, dynamic>>[];
      for (final row in _rows) {
        if (row.isBlank) continue;
        details.add({
          'task_id': widget.taskId,
          'sequence': details.length + 1,
          'location': _textOrNull(row.location),
          'elevation': _textOrNull(row.elevation),
          'bearing_capacity': num.tryParse(row.bearingCapacity.text.trim()),
          'remarks': _textOrNull(row.remarks),
        });
      }
      await DbService.replaceFootingInspectionDetails(widget.taskId, details);
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
      appBar: AppBar(title: const Text('Field Inspection of Footing')),
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
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Task ID'),
                  const SizedBox(height: 4),
                  _readOnly('${widget.taskId}'),
                ],
              ),
            ),
            _checkbox('Column', _column, (v) => setState(() => _column = v)),
            _checkbox(
              'Continuous Wall',
              _continuousWall,
              (v) => setState(() => _continuousWall = v),
            ),
            _checkbox('Other', _other, (v) => setState(() => _other = v)),
            SizedBox(
              width: 240,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Other Description'),
                  const SizedBox(height: 4),
                  TextField(controller: _otherDesc, decoration: _decoration()),
                ],
              ),
            ),
          ],
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
        const SizedBox(height: 16),
        _label('Footing Inspection Detail'),
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
              _cell(_locationWidth, _headerText('Location')),
              _cell(_elevationWidth, _headerText('Elevation')),
              _cell(_bearingWidth, _headerText('Bearing Capacity')),
              _cell(_remarksWidth, _headerText('Remarks')),
            ],
          ),
          const SizedBox(height: 6),
          for (final row in _rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  _cell(_locationWidth, _textField(row.location)),
                  _cell(_elevationWidth, _textField(row.elevation)),
                  _cell(
                    _bearingWidth,
                    TextField(
                      controller: row.bearingCapacity,
                      textAlign: TextAlign.right,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
                      ],
                      decoration: _decoration(),
                    ),
                  ),
                  _cell(_remarksWidth, _textField(row.remarks)),
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

  Widget _headerText(String text) => Text(
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
