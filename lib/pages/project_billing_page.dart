import 'package:flutter/material.dart';

class ProjectBillingPage extends StatefulWidget {
  const ProjectBillingPage({super.key});

  @override
  State<ProjectBillingPage> createState() => _ProjectBillingPageState();
}

class _ProjectBillingPageState extends State<ProjectBillingPage> {
  static const List<String> _billingCodes = [
    'Testing 1',
    'Testing 2',
    'Testing 3',
  ];

  // Each entry: {'code': String, 'rate': TextEditingController}
  final List<_BillingRow> _rows = [];

  @override
  void dispose() {
    for (final row in _rows) {
      row.rateController.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _rows.add(_BillingRow(code: _billingCodes.first));
    });
  }

  void _removeRow(int index) {
    setState(() {
      _rows[index].rateController.dispose();
      _rows.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 600;
                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          flex: 3,
                          child: Text('Billing Code',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          flex: 2,
                          child: Text('Rate',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 40), // space for delete icon
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
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: row.code,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                ),
                                items: _billingCodes
                                    .map((c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(c),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => row.code = v!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: row.rateController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                  prefixText: '\$ ',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
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
                );

                if (!isWide) return content;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: content,
                  ),
                );
              }),
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

class _BillingRow {
  String code;
  final TextEditingController rateController;

  _BillingRow({required this.code}) : rateController = TextEditingController();
}
