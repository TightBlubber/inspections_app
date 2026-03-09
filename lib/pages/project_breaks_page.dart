import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProjectBreaksPage extends StatefulWidget {
  final String projectId;

  const ProjectBreaksPage({super.key, this.projectId = ''});

  @override
  State<ProjectBreaksPage> createState() => _ProjectBreaksPageState();
}

class _ProjectBreaksPageState extends State<ProjectBreaksPage> {
  final List<TextEditingController> _cylinderControllers =
      List.generate(10, (_) => TextEditingController());
  final TextEditingController _defaultDiameter = TextEditingController();

  static const List<String> _cylinderLabels = [
    'First Cylinder',
    'Second Cylinder',
    'Third Cylinder',
    'Fourth Cylinder',
    'Fifth Cylinder',
    'Sixth Cylinder',
    'Seventh Cylinder',
    'Eighth Cylinder',
    'Ninth Cylinder',
    'Tenth Cylinder',
  ];

  @override
  void dispose() {
    for (final c in _cylinderControllers) {
      c.dispose();
    }
    _defaultDiameter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breaks'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 600;
                final content = _buildContent();
                if (!isWide) return content;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
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

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field('Project ID', TextEditingController(text: widget.projectId),
            readOnly: true),
        const SizedBox(height: 12),
        const Text(
          'Cylinder Break Days - enter 999 for HOLD.',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        ...List.generate(10, (i) => _intField(_cylinderLabels[i], _cylinderControllers[i])),
        const Divider(height: 20),
        _field('Default Diameter', _defaultDiameter),
      ],
    );
  }

  Widget _field(String label, TextEditingController controller,
      {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          filled: readOnly,
          fillColor: readOnly ? Colors.grey.shade100 : null,
        ),
      ),
    );
  }

  Widget _intField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
    );
  }
}
