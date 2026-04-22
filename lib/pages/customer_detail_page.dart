import 'package:flutter/material.dart';
import '../services/db.dart';

class CustomerDetailPage extends StatefulWidget {
  final Map<String, dynamic> customer;

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
    _customerId = TextEditingController(text: widget.customer['customer_id'] as String? ?? '');
    _companyName = TextEditingController(text: widget.customer['company_name'] as String? ?? '');
    _contactFirstName = TextEditingController(text: widget.customer['contact_first_name'] as String? ?? '');
    _contactLastName = TextEditingController(text: widget.customer['contact_last_name'] as String? ?? '');
    _companyDepartment = TextEditingController(text: widget.customer['company_department'] as String? ?? '');
    _addressLine1 = TextEditingController(text: widget.customer['address_line1'] as String? ?? '');
    _addressLine2 = TextEditingController(text: widget.customer['address_line2'] as String? ?? '');
    _city = TextEditingController(text: widget.customer['city'] as String? ?? '');
    _stateProvince = TextEditingController(text: widget.customer['state_province'] as String? ?? '');
    _postalCode = TextEditingController(text: widget.customer['postal_code'] as String? ?? '');
    _country = TextEditingController(text: widget.customer['country'] as String? ?? '');
    _contactTitle = TextEditingController(text: widget.customer['contact_title'] as String? ?? '');
    _phone = TextEditingController(text: widget.customer['phone'] as String? ?? '');
    _extension = TextEditingController(text: widget.customer['extension'] as String? ?? '');
    _fax = TextEditingController(text: widget.customer['fax'] as String? ?? '');
    _email = TextEditingController(text: widget.customer['email'] as String? ?? '');
    _website = TextEditingController(text: widget.customer['website'] as String? ?? '');
    _notes = TextEditingController(text: widget.customer['notes'] as String? ?? '');
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

  Future<void> _save() async {
    try {
      await DbService.upsertCustomer({
        'customer_id': _customerId.text.trim(),
        'company_name': _companyName.text.trim(),
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
        'website': _website.text.trim(),
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
