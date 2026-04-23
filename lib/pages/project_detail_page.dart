import 'package:flutter/material.dart';
import 'project_billing_page.dart';
import 'project_breaks_page.dart';
import 'project_proctors_page.dart';
import '../services/db.dart';

class ProjectDetailPage extends StatefulWidget {
  final Map<String, dynamic> project;

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
  List<Map<String, dynamic>> _customers = [];

  Future<void> _loadCustomers() async {
    try {
      final data = await DbService.getCustomers();
      setState(() => _customers = data);
    } catch (_) {}
  }

  Future<void> _onCustomerChanged(String? customerId) async {
    setState(() => _selectedCustomerId = customerId);
    if (customerId == null) return;
    try {
      final customer = await DbService.getCustomer(customerId);
      if (customer == null || !mounted) return;
      setState(() {
        _contactFirstName.text = customer['contact_first_name'] as String? ?? '';
        _contactLastName.text = customer['contact_last_name'] as String? ?? '';
        _companyDepartment.text = customer['company_department'] as String? ?? '';
        _addressLine1.text = customer['address_line1'] as String? ?? '';
        _addressLine2.text = customer['address_line2'] as String? ?? '';
        _city.text = customer['city'] as String? ?? '';
        _stateProvince.text = customer['state_province'] as String? ?? '';
        _postalCode.text = customer['postal_code'] as String? ?? '';
        _country.text = customer['country'] as String? ?? '';
        _contactTitle.text = customer['contact_title'] as String? ?? '';
        _phone.text = customer['phone'] as String? ?? '';
        _extension.text = customer['extension'] as String? ?? '';
        _fax.text = customer['fax'] as String? ?? '';
        _email.text = customer['email'] as String? ?? '';
      });
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _projectId = TextEditingController(text: widget.project['project_id'] as String? ?? '');
    _projectName = TextEditingController(text: widget.project['project_name'] as String? ?? '');
    _projectNameExt = TextEditingController(text: widget.project['project_name_ext'] as String? ?? '');
    _contactFirstName = TextEditingController(text: widget.project['contact_first_name'] as String? ?? '');
    _contactLastName = TextEditingController(text: widget.project['contact_last_name'] as String? ?? '');
    _companyDepartment = TextEditingController(text: widget.project['company_department'] as String? ?? '');
    _addressLine1 = TextEditingController(text: widget.project['address_line1'] as String? ?? '');
    _addressLine2 = TextEditingController(text: widget.project['address_line2'] as String? ?? '');
    _city = TextEditingController(text: widget.project['city'] as String? ?? '');
    _stateProvince = TextEditingController(text: widget.project['state_province'] as String? ?? '');
    _postalCode = TextEditingController(text: widget.project['postal_code'] as String? ?? '');
    _country = TextEditingController(text: widget.project['country'] as String? ?? '');
    _contactTitle = TextEditingController(text: widget.project['contact_title'] as String? ?? '');
    _phone = TextEditingController(text: widget.project['phone'] as String? ?? '');
    _extension = TextEditingController(text: widget.project['extension'] as String? ?? '');
    _fax = TextEditingController(text: widget.project['fax'] as String? ?? '');
    _email = TextEditingController(text: widget.project['email'] as String? ?? '');
    _emailBreaks = TextEditingController(text: widget.project['email_breaks'] as String? ?? '');
    _cylNumber = TextEditingController(text: widget.project['cyl_number'] as String? ?? '');
    _cylSize = TextEditingController(text: widget.project['cyl_size'] as String? ?? '');
    _notes = TextEditingController(text: widget.project['notes'] as String? ?? '');
    _activeProject = widget.project['active_project'] as bool? ?? true;
    _emailReports = widget.project['email_reports'] as bool? ?? false;
    _eeiProject = widget.project['eei_project'] as bool? ?? false;
    _selectedCustomerId = widget.project['customer_id'] as String?;
    _loadCustomers();
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

  Future<void> _save() async {
    try {
      await DbService.upsertProject({
        'project_id': _projectId.text.trim(),
        'project_name': _projectName.text.trim(),
        'project_name_ext': _projectNameExt.text.trim(),
        'customer_id': _selectedCustomerId,
        'contact_first_name': _contactFirstName.text.trim(),
        'contact_last_name': _contactLastName.text.trim(),
        'contact_title': _contactTitle.text.trim(),
        'company_department': _companyDepartment.text.trim(),
        'address_line1': _addressLine1.text.trim(),
        'address_line2': _addressLine2.text.trim(),
        'city': _city.text.trim(),
        'state_province': _stateProvince.text.trim(),
        'postal_code': _postalCode.text.trim(),
        'country': _country.text.trim(),
        'phone': _phone.text.trim(),
        'extension': _extension.text.trim(),
        'fax': _fax.text.trim(),
        'email': _email.text.trim(),
        'email_breaks': _emailBreaks.text.trim(),
        'cyl_number': _cylNumber.text.trim(),
        'cyl_size': _cylSize.text.trim(),
        'active_project': _activeProject,
        'email_reports': _emailReports,
        'eei_project': _eeiProject,
        'notes': _notes.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
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
                      builder: (_) => ProjectBillingPage(
                        projectId: _projectId.text,
                      ),
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
                      builder: (_) => ProjectProctorsPage(
                        projectId: _projectId.text,
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                _bottomButton('Save', _save, primary: true),
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
        initialValue: _selectedCustomerId,
        decoration: const InputDecoration(
          labelText: 'Customer',
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        items: _customers
            .map((c) => DropdownMenuItem(
                  value: c['customer_id'] as String?,
                  child: Text('${c['customer_id']} — ${c['company_name']}'),
                ))
            .toList(),
        onChanged: _onCustomerChanged,
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
