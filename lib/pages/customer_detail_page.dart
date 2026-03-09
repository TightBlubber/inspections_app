import 'package:flutter/material.dart';

class CustomerDetailPage extends StatefulWidget {
  final Map<String, String> customer;

  const CustomerDetailPage({super.key, this.customer = const {}});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  late final TextEditingController _customerId;
  late final TextEditingController _companyName;
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
  late final TextEditingController _website;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _customerId = TextEditingController(text: widget.customer['id'] ?? '');
    _companyName = TextEditingController(text: widget.customer['company'] ?? '');
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
    _website = TextEditingController();
    _notes = TextEditingController();
  }

  @override
  void dispose() {
    _customerId.dispose();
    _companyName.dispose();
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
    _website.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    // TODO: persist changes
    Navigator.pop(context);
  }

  void _cancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.isEmpty ? 'New Customer' : 'Customer Detail'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  final content = isWide
                      ? _buildWideLayout()
                      : _buildNarrowLayout();
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
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFED7422),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Save'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _cancel,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
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
        _sectionHeader('Identification'),
        _field('Customer ID', _customerId),
        _field('Company Name', _companyName),
        _sectionHeader('Contact'),
        _field('First Name', _contactFirstName),
        _field('Last Name', _contactLastName),
        _field('Title', _contactTitle),
        _field('Company / Department', _companyDepartment),
        _sectionHeader('Address'),
        _field('Address Line 1', _addressLine1),
        _field('Address Line 2', _addressLine2),
        _field('City', _city),
        _field('State / Province', _stateProvince),
        _field('Postal Code', _postalCode),
        _field('Country', _country),
        _sectionHeader('Communication'),
        _field('Phone Number', _phone),
        _field('Extension', _extension),
        _field('Fax Number', _fax),
        _field('Email Address', _email),
        _field('Web Site', _website),
        _sectionHeader('Notes'),
        _field('Notes', _notes, maxLines: 5),
      ],
    );
  }

  Widget _buildWideLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Identification'),
        _row2(
          _field('Customer ID', _customerId),
          _field('Company Name', _companyName),
        ),
        _sectionHeader('Contact'),
        _row2(
          _field('First Name', _contactFirstName),
          _field('Last Name', _contactLastName),
        ),
        _row2(
          _field('Title', _contactTitle),
          _field('Company / Department', _companyDepartment),
        ),
        _sectionHeader('Address'),
        _row2(
          _field('Address Line 1', _addressLine1),
          _field('Address Line 2', _addressLine2),
        ),
        _row2(
          _field('City', _city),
          _field('State / Province', _stateProvince),
        ),
        _row2(
          _field('Postal Code', _postalCode),
          _field('Country', _country),
        ),
        _sectionHeader('Communication'),
        _row2(
          _field('Phone Number', _phone),
          _field('Extension', _extension),
        ),
        _row2(
          _field('Fax Number', _fax),
          _field('Email Address', _email),
        ),
        _field('Web Site', _website),
        _sectionHeader('Notes'),
        _field('Notes', _notes, maxLines: 5),
      ],
    );
  }

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
}
