import 'package:flutter/material.dart';

class ProjectEmailPage extends StatefulWidget {
  final Map<String, dynamic> project;

  const ProjectEmailPage({super.key, required this.project});

  @override
  State<ProjectEmailPage> createState() => _ProjectEmailPageState();
}

class _ProjectEmailPageState extends State<ProjectEmailPage> {
  static const List<String> _taskTypes = [
    'Inspection',
    'Testing',
    'Observation',
    'Review',
  ];

  static const List<String> _extendedOptions = [
    'Yes',
    'No',
  ];

  final List<_EmailReportRow> _rows = [];

  @override
  void initState() {
    super.initState();
    // Start with one blank row
    _rows.add(_EmailReportRow(
      taskType: _taskTypes.first,
      extended: _extendedOptions.first,
    ));
  }

  void _addRow() {
    setState(() {
      _rows.add(_EmailReportRow(
        taskType: _taskTypes.first,
        extended: _extendedOptions.first,
      ));
    });
  }

  void _deleteRow(int index) {
    setState(() {
      _rows.removeAt(index);
    });
  }

  void _onEmailPressed() {
    // TODO: Print reports for all rows where print == true.
    // TODO: If email is enabled for this project, also email the reports.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Email Reports – ${widget.project['project_name'] ?? ''}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      _buildHeaderRow(),
                      const Divider(height: 1),
                      // Data rows
                      ..._rows.asMap().entries.map((entry) {
                        final index = entry.key;
                        final row = entry.value;
                        return _buildDataRow(index, row);
                      }),
                      // Add row button
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextButton.icon(
                          onPressed: _addRow,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Row'),
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
            child: ElevatedButton.icon(
              onPressed: _onEmailPressed,
              icon: const Icon(Icons.email_outlined, size: 16),
              label: const Text('Email / Print Reports'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFED7422),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                textStyle: const TextStyle(fontSize: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ], //
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: const [
          SizedBox(
            width: 60,
            child: Text('Seq',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 160,
            child: Text('Task Type',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text('Extended',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text('Print',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ),
          SizedBox(width: 8),
          // Delete column placeholder
          SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildDataRow(int index, _EmailReportRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Sequence
          SizedBox(
            width: 60,
            child: Text(
              '${index + 1}',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          // Task Type dropdown
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<String>(
              initialValue: row.taskType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              items: _taskTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => row.taskType = v!),
            ),
          ),
          const SizedBox(width: 8),
          // Extended dropdown
          SizedBox(
            width: 100,
            child: DropdownButtonFormField<String>(
              initialValue: row.extended,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              items: _extendedOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => row.extended = v!),
            ),
          ),
          const SizedBox(width: 8),
          // Print checkbox
          SizedBox(
            width: 60,
            child: Center(
              child: Checkbox(
                value: row.print,
                onChanged: (v) => setState(() => row.print = v ?? false),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Delete button
          SizedBox(
            width: 32,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red.shade400,
              padding: EdgeInsets.zero,
              onPressed: () => _deleteRow(index),
              tooltip: 'Remove row',
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailReportRow {
  String taskType;
  String extended;
  bool print;

  _EmailReportRow({
    required this.taskType,
    required this.extended,
    this.print = false,
  });
}
