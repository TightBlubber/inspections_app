import 'package:flutter/material.dart';
import 'project_billing_page.dart';
import 'project_breaks_page.dart';
import 'project_proctors_page.dart';

class ProjectDetailPage extends StatefulWidget {
  final Map<String, String> project;

  const ProjectDetailPage({super.key, this.project = const {}});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  // Text controllers
  late final TextEditingController _projectId;
  late final TextEditingController _projectName;
  late final TextEditingController _projectNameExt;
  late final TextEditingController _contactFirstName;
  late final TextEditingController _contactLastName;
  late final TextEditingController _companyDepartment;
  late final TextEditingController _addressLine1;
  late final TextEditingController _addressLine2;
  late final TextEditingController _city;
  late final TextEditingController _stateProvince;
  late final TextEditingController _postalCode;
  late final TextEditingController _country;
  late final TextEditingController _contactTitle;
  late final TextEditingController _phone;
  late final TextEditingController _extension;
  late final TextEditingController _fax;
  late final TextEditingController _email;
  late final TextEditingController _emailBreaks;
  late final TextEditingController _cylNumber;
  late final TextEditingController _cylSize;
  late final TextEditingController _notes;

  // Checkboxes
  bool _activeProject = true;
  bool _emailReports = false;
  bool _eeiProject = false;

  // Customer dropdown
  String? _selectedCustomerId;
  final List<Map<String, String>> _customers = [
    {'id': 'C001', 'company': 'testing1'},
    {'id': 'C002', 'company': 'testing2'},
    {'id': 'C003', 'company': 'testing3'},
    {'id': 'C004', 'company': 'testing4'},
    {'id': 'C005', 'company': 'testing5'},
  ];

  @override
  void initState() {
    super.initState();
    _projectId = TextEditingController(text: widget.project['id'] ?? '');
    _projectName = TextEditingController(text: widget.project['name'] ?? '');
    _projectNameExt = TextEditingController();
    _contactFirstName = TextEditingController();
    _contactLastName = TextEditingController();
    _companyDepartment = TextEditingController();
    _addressLine1 = TextEditingController();
    _addressLine2 = TextEditingController();
    _city = TextEditingController();
    _stateProvince = TextEditingController();
    _postalCode = TextEditingController();
    _country = TextEditingController();
    _contactTitle = TextEditingController();
    _phone = TextEditingController();
    _extension = TextEditingController();
    _fax = TextEditingController();
    _email = TextEditingController();
    _emailBreaks = TextEditingController();
    _cylNumber = TextEditingController();
    _cylSize = TextEditingController();
    _notes = TextEditingController();
  }

  @override
  void dispose() {
    _projectId.dispose();
    _projectName.dispose();
    _projectNameExt.dispose();
    _contactFirstName.dispose();
    _contactLastName.dispose();
    _companyDepartment.dispose();
    _addressLine1.dispose();
    _addressLine2.dispose();
    _city.dispose();
    _stateProvince.dispose();
    _postalCode.dispose();
    _country.dispose();
    _contactTitle.dispose();
    _phone.dispose();
    _extension.dispose();
    _fax.dispose();
    _email.dispose();
    _emailBreaks.dispose();
    _cylNumber.dispose();
    _cylSize.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.isEmpty ? 'New Project' : 'Project Detail'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  final content = isWide ? _buildWideLayout() : _buildNarrowLayout();
                  if (!isWide) return content;
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: content,
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _bottomButton('Billing', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProjectBillingPage(),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                _bottomButton('Breaks', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProjectBreaksPage(
                        projectId: _projectId.text,
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                _bottomButton('Proctors', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProjectProctorsPage(),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                _bottomButton('Save', () => Navigator.pop(context),
                    primary: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Project Info'),
        _field('Project ID', _projectId),
        _field('Project Name', _projectName),
        _field('Project Name Ext.', _projectNameExt),
        _checkRow('Active Project', _activeProject,
            (v) => setState(() => _activeProject = v!)),
        _sectionHeader('Customer'),
        _customerDropdown(),
        _field('Contact First Name', _contactFirstName),
        _field('Contact Last Name', _contactLastName),
        _field('Company / Department', _companyDepartment),
        _sectionHeader('Address'),
        _field('Address Line 1', _addressLine1),
        _field('Address Line 2', _addressLine2),
        _field('City', _city),
        _field('State / Province', _stateProvince),
        _field('Postal Code', _postalCode),
        _field('Country', _country),
        _sectionHeader('Contact'),
        _field('Contact Title', _contactTitle),
        _field('Phone Number', _phone),
        _field('Extension', _extension),
        _field('Fax Number', _fax),
        _field('Email Address', _email),
        _sectionHeader('Options'),
        _checkRow('Email Reports', _emailReports,
            (v) => setState(() => _emailReports = v!)),
        _checkRow('EEI Project', _eeiProject,
            (v) => setState(() => _eeiProject = v!)),
        _field('Email Breaks', _emailBreaks),
        _field('Cyl #', _cylNumber),
        _field('Cyl Size', _cylSize),
        _sectionHeader('Notes'),
        _field('Notes', _notes, maxLines: 5),
      ],
    );
  }

  Widget _buildWideLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Project Info'),
        _row2(_field('Project ID', _projectId),
            _field('Project Name', _projectName)),
        _row2(_field('Project Name Ext.', _projectNameExt),
            _checkRow('Active Project', _activeProject,
                (v) => setState(() => _activeProject = v!))),
        _sectionHeader('Customer'),
        _customerDropdown(),
        _row2(_field('Contact First Name', _contactFirstName),
            _field('Contact Last Name', _contactLastName)),
        _field('Company / Department', _companyDepartment),
        _sectionHeader('Address'),
        _row2(_field('Address Line 1', _addressLine1),
            _field('Address Line 2', _addressLine2)),
        _row2(_field('City', _city), _field('State / Province', _stateProvince)),
        _row2(_field('Postal Code', _postalCode), _field('Country', _country)),
        _sectionHeader('Contact'),
        _row2(_field('Contact Title', _contactTitle),
            _field('Phone Number', _phone)),
        _row2(_field('Extension', _extension), _field('Fax Number', _fax)),
        _field('Email Address', _email),
        _sectionHeader('Options'),
        Row(
          children: [
            _checkRow('Email Reports', _emailReports,
                (v) => setState(() => _emailReports = v!)),
            const SizedBox(width: 24),
            _checkRow('EEI Project', _eeiProject,
                (v) => setState(() => _eeiProject = v!)),
          ],
        ),
        _row2(_field('Email Breaks', _emailBreaks),
            _row2(_field('Cyl #', _cylNumber), _field('Cyl Size', _cylSize))),
        _sectionHeader('Notes'),
        _field('Notes', _notes, maxLines: 5),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Color(0xFFED7422),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
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

  Widget _checkRow(String label, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFED7422),
          ),
          Text(label),
        ],
      ),
    );
  }

  Widget _customerDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        value: _selectedCustomerId,
        decoration: const InputDecoration(
          labelText: 'Customer',
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        items: _customers
            .map((c) => DropdownMenuItem(
                  value: c['id'],
                  child: Text('${c['id']} — ${c['company']}'),
                ))
            .toList(),
        onChanged: (v) => setState(() => _selectedCustomerId = v),
      ),
    );
  }

  Widget _row2(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _bottomButton(String label, VoidCallback onPressed,
      {bool primary = false}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            primary ? const Color(0xFFED7422) : Colors.grey.shade200,
        foregroundColor: primary ? Colors.white : Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
}
