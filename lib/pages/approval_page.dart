import 'package:flutter/material.dart';

class ApprovalPage extends StatefulWidget {
  const ApprovalPage({super.key});

  @override
  State<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  int? _selectedIndex;

  static const List<String> _taskTypeOptions = [
    'Inspection',
    'Testing',
    'Review',
    'Survey',
  ];

  static const List<String> _extendedOptions = [
    'Yes',
    'No',
  ];

  // Placeholder data — replace with real data later
  final List<Map<String, String>> _rows = [
    {'projectId': 'P001', 'sequence': '1', 'taskType': 'Inspection', 'extended': 'No'},
    {'projectId': 'P001', 'sequence': '2', 'taskType': 'Testing',    'extended': 'Yes'},
    {'projectId': 'P002', 'sequence': '1', 'taskType': 'Review',     'extended': 'No'},
    {'projectId': 'P003', 'sequence': '1', 'taskType': 'Survey',     'extended': 'No'},
    {'projectId': 'P003', 'sequence': '2', 'taskType': 'Inspection', 'extended': 'Yes'},
  ];

  bool get _hasSelection => _selectedIndex != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval'),
      ),
      body: Column(
        children: [
          // ── Data table ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  showCheckboxColumn: false,
                  columns: const [
                    DataColumn(
                      label: Text('Project ID',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text('Sequence',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text('Task Type',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text('Extended',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                  rows: List.generate(_rows.length, (index) {
                    final row = _rows[index];
                    return DataRow(
                      selected: _selectedIndex == index,
                      onSelectChanged: (selected) {
                        setState(() {
                          _selectedIndex = selected == true ? index : null;
                        });
                      },
                      cells: [
                        DataCell(Text(row['projectId']!)),
                        DataCell(Text(row['sequence']!)),
                        DataCell(
                          DropdownButton<String>(
                            value: row['taskType'],
                            isDense: true,
                            underline: const SizedBox(),
                            items: _taskTypeOptions
                                .map((v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _rows[index]['taskType'] = value);
                            },
                          ),
                        ),
                        DataCell(
                          DropdownButton<String>(
                            value: row['extended'],
                            isDense: true,
                            underline: const SizedBox(),
                            items: _extendedOptions
                                .map((v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _rows[index]['extended'] = value);
                            },
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // ── For Selected Task label + 4 buttons ─────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'For Selected Task',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    _ActionButton(
                      label: 'Detail',
                      enabled: _hasSelection,
                      onPressed: () {},
                    ),
                    _ActionButton(
                      label: 'Form',
                      enabled: _hasSelection,
                      onPressed: () {},
                    ),
                    _ActionButton(
                      label: 'Report',
                      enabled: _hasSelection,
                      onPressed: () {},
                    ),
                    _ActionButton(
                      label: 'Approve',
                      enabled: _hasSelection,
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── PRINT and Close buttons ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionButton(
                  label: 'PRINT',
                  enabled: true,
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  label: 'Close',
                  enabled: true,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFED7422),
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade500,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label),
    );
  }
}
