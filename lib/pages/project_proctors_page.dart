import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/db.dart';

class ProjectProctorsPage extends StatefulWidget {
  final String projectId;
  const ProjectProctorsPage({super.key, required this.projectId});

  @override
  State<ProjectProctorsPage> createState() => _ProjectProctorsPageState();
}

class _ProjectProctorsPageState extends State<ProjectProctorsPage> {
  final List<_ProctorRow> _rows = [];
  final List<int> _deletedIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await DbService.getProctors(widget.projectId);
      setState(() {
        for (final p in data) {
          final row = _ProctorRow(id: p['id'] as int?);
          row.soilNo.text = (p['soil_no'] ?? '').toString();
          row.maxDryDensity.text = (p['max_dry_density'] ?? '').toString();
          row.optimumMoisture.text = (p['optimum_moisture'] ?? '').toString();
          row.soilClassification.text = p['soil_classification'] as String? ?? '';
          _rows.add(row);
        }
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

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    try {
      for (final id in _deletedIds) {
        await DbService.deleteProctor(id);
      }
      for (final row in _rows) {
        final data = {
          'project_id': widget.projectId,
          'soil_no': int.tryParse(row.soilNo.text.trim()),
          'max_dry_density': double.tryParse(row.maxDryDensity.text.trim()),
          'optimum_moisture': double.tryParse(row.optimumMoisture.text.trim()),
          'soil_classification': row.soilClassification.text.trim(),
        };
        if (row.id != null) {
          await DbService.updateProctor(row.id!, data);
        } else {
          final res = await DbService.insertProctor(data);
          row.id = res['id'] as int?;
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  void _addRow() {
    setState(() {
      _rows.add(_ProctorRow());
    });
  }

  void _removeRow(int index) {
    setState(() {
      final id = _rows[index].id;
      if (id != null) _deletedIds.add(id);
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proctors'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: const [
                      SizedBox(width: 48, child: Text('Soil No.', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      SizedBox(width: 8),
                      Expanded(child: Text('Max Dry Density', style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 8),
                      Expanded(child: Text('Optimum Moisture', style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 8),
                      Expanded(child: Text('Soil Classification', style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 40),
                    ],
                  ),
                  const Divider(),
                  ..._rows.asMap().entries.map((entry) {
                    final i = entry.key;
                    final row = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 48,
                            child: TextField(
                              controller: row.soilNo,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: row.maxDryDensity,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: row.optimumMoisture,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: row.soilClassification,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _removeRow(i),
                            tooltip: 'Remove',
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _addRow,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Row'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFED7422),
                    ),
                  ),
                ],
              ),
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
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFED7422),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Save & Close'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProctorRow {
  int? id;
  final TextEditingController soilNo = TextEditingController();
  final TextEditingController maxDryDensity = TextEditingController();
  final TextEditingController optimumMoisture = TextEditingController();
  final TextEditingController soilClassification = TextEditingController();

  _ProctorRow({this.id});

  void dispose() {
    soilNo.dispose();
    maxDryDensity.dispose();
    optimumMoisture.dispose();
    soilClassification.dispose();
  }
}
