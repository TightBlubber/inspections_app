import 'package:flutter/material.dart';
import '../services/db.dart';

class AllProctorsPage extends StatefulWidget {
  final bool activeOnly;

  const AllProctorsPage({super.key, required this.activeOnly});

  @override
  State<AllProctorsPage> createState() => _AllProctorsPageState();
}

class _AllProctorsPageState extends State<AllProctorsPage> {
  List<Map<String, dynamic>> _rows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await DbService.getAllProctors(activeOnly: widget.activeOnly);
      setState(() {
        _rows = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load proctors: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activeOnly ? 'Active Project Proctors' : 'All Project Proctors'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(
                            label: Text('Project ID',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          DataColumn(
                            label: Text('Soil #',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          DataColumn(
                            label: Text('Max Dry Density',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          DataColumn(
                            label: Text('Optimum Moisture',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          DataColumn(
                            label: Text('Soil Classification',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                        rows: _rows.map((row) {
                          return DataRow(cells: [
                            DataCell(Text(row['project_id'] as String? ?? '')),
                            DataCell(Text((row['soil_no'] ?? '').toString())),
                            DataCell(Text((row['max_dry_density'] ?? '').toString())),
                            DataCell(Text((row['optimum_moisture'] ?? '').toString())),
                            DataCell(Text(row['soil_classification'] as String? ?? '')),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFED7422),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
    );
  }
}
