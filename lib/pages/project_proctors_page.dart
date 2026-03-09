import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProjectProctorsPage extends StatefulWidget {
  const ProjectProctorsPage({super.key});

  @override
  State<ProjectProctorsPage> createState() => _ProjectProctorsPageState();
}

class _ProjectProctorsPageState extends State<ProjectProctorsPage> {
  final List<_ProctorRow> _rows = [];

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _rows.add(_ProctorRow());
    });
  }

  void _removeRow(int index) {
    setState(() {
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
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black87,
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

class _ProctorRow {
  final TextEditingController soilNo = TextEditingController();
  final TextEditingController maxDryDensity = TextEditingController();
  final TextEditingController optimumMoisture = TextEditingController();
  final TextEditingController soilClassification = TextEditingController();

  void dispose() {
    soilNo.dispose();
    maxDryDensity.dispose();
    optimumMoisture.dispose();
    soilClassification.dispose();
  }
}
