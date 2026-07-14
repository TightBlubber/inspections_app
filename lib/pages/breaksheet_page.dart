import 'package:flutter/material.dart';
import '../services/db.dart';

class BreaksheetPage extends StatefulWidget {
  final String date; // MM/DD/YYYY

  const BreaksheetPage({super.key, required this.date});

  @override
  State<BreaksheetPage> createState() => _BreaksheetPageState();
}

class _BreaksheetPageState extends State<BreaksheetPage> {
  List<Map<String, dynamic>> _rows = [];
  bool _isLoading = true;

  static const List<String> _breakTypes = [
    '',
    'Cone',
    'Cone & Sheer',
    'Sheer',
    'Columnar',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await DbService.getBreaksheetByDate(widget.date);
      setState(() {
        _rows = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    }
  }

  Future<void> _updateBreakType(int id, String breakType) async {
    try {
      await DbService.updateBreakType(id, breakType);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Break Sheet — ${widget.date}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _rows.isEmpty
                      ? const Center(
                          child: Text('No breaks scheduled for this date.'),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                const Color(0xFFED7422).withValues(alpha: 0.1),
                              ),
                              columns: const [
                                DataColumn(
                                    label: Text('Project No',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Set No',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Age',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Break Date',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Diameter',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Length',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Width',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Type of Break',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                              ],
                              rows: _rows.asMap().entries.map((entry) {
                                final i = entry.key;
                                final row = entry.value;
                                final id = row['id'] as int? ?? 0;
                                final currentType =
                                    row['break_type'] as String? ?? '';
                                final safeType = _breakTypes.contains(currentType)
                                    ? currentType
                                    : '';
                                return DataRow(
                                  cells: [
                                    DataCell(Text(
                                        row['project_id'] as String? ?? '')),
                                    DataCell(Text(
                                        (row['set_number'] ?? '').toString())),
                                    DataCell(Text(
                                        (row['test_age_days'] ?? '').toString())),
                                    DataCell(Text(
                                        row['test_date'] as String? ?? '')),
                                    DataCell(Text(
                                        (row['cylinder_diameter'] ?? '')
                                            .toString())),
                                    DataCell(Text(
                                        (row['mold_length'] ?? '').toString())),
                                    DataCell(Text(
                                        (row['mold_width'] ?? '').toString())),
                                    DataCell(
                                      DropdownButton<String>(
                                        value: safeType,
                                        isDense: true,
                                        underline: const SizedBox(),
                                        items: _breakTypes
                                            .map((t) => DropdownMenuItem(
                                                  value: t,
                                                  child: Text(t.isEmpty
                                                      ? '—'
                                                      : t),
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                          if (value == null) return;
                                          setState(() =>
                                              _rows[i]['break_type'] = value);
                                          _updateBreakType(id, value);
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
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
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: implement print
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Print not yet implemented')),
                          );
                        },
                        icon: const Icon(Icons.print),
                        label: const Text('Print'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFED7422),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
