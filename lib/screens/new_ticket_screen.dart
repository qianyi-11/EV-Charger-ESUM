import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/support_ticket.dart';
import '../models/diagnostic_state.dart';
import '../services/ticket_service.dart';
import '../services/auth_service.dart';

class NewTicketScreen extends StatefulWidget {
  final TicketPrefill? prefill;

  const NewTicketScreen({super.key, this.prefill});

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _carOtherController = TextEditingController();
  final _chargerOtherController = TextEditingController();
  final _serialController = TextEditingController();
  final _detailsController = TextEditingController();

  static const _green = Color(0xFF1B5E20);
  static const _greenLight = Color(0xFFE8F5E9);
  static const _labelColor = Color(0xFF1A237E);
  static const _sectionGrey = Color(0xFF9E9E9E);
  static const _borderGrey = Color(0xFFE0E0E0);
  static const _hintGrey = Color(0xFFBDBDBD);

  String? _salutation;
  String? _carBrand;
  String? _installedWithRexharge;
  String? _chargerBrand;
  DateTime? _installationDate;
  String? _faultyComponent;
  String? _describeIssue;

  File? _eboxScreenshot;
  bool _submitting = false;

  static const _carBrands = ['Proton', 'BYD', 'Tesla'];
  static const _chargerBrands = [
    'RExharge REVO',
    'Proton',
    'Starcharge Artemis',
    'Starcharge Aurora',
    'Pingalax',
    'Joycharge',
  ];
  static const _rexhargeOptions = ['Yes', 'No', 'Not sure'];
  static const _faultyComponents = ['Charger', 'Isolator', 'EVDB', 'Other'];

  @override
  void initState() {
    super.initState();
    _applyPrefill();
  }

  void _applyPrefill() {
    final profile = AuthService.instance.profile;
    if (profile != null) {
      if (_fullNameController.text.isEmpty) {
        _fullNameController.text = profile.displayName;
      }
      if (_contactController.text.isEmpty && profile.phone.isNotEmpty) {
        _contactController.text = profile.phone;
      }
    }

    final prefill = widget.prefill;
    if (prefill == null) return;

    final state = DiagnosticState();
    if (prefill.chargerSerialNumber != null && prefill.chargerSerialNumber!.isNotEmpty) {
      _serialController.text = prefill.chargerSerialNumber!;
    } else if (state.serialNumber.isNotEmpty) {
      _serialController.text = state.serialNumber;
    }

    _faultyComponent = prefill.faultyComponent;
    _describeIssue = prefill.describeIssue;
    if (prefill.describeIssue == 'Wrong Component / Specs' &&
        prefill.details != null &&
        prefill.details!.isNotEmpty) {
      _detailsController.text = prefill.details!;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _carOtherController.dispose();
    _chargerOtherController.dispose();
    _serialController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  bool get _describeIssueEnabled =>
      _faultyComponent != null && _faultyComponent != 'Other';

  bool get _showSolidRedUpload =>
      _faultyComponent == 'Charger' && _describeIssue == 'Solid red light';

  bool get _showOtherHint => _faultyComponent == 'Other';

  List<String> get _describeIssueOptions {
    switch (_faultyComponent) {
      case 'Charger':
        return [
          'No light',
          'Solid red light',
          'Red light flashes 6 times',
          'Red light flashes 7 times',
          'Red light flashes 8 times',
          'Red light flashes 9 times',
          'Other',
        ];
      case 'Isolator':
        return ['Isolator OFF', 'Other'];
      case 'EVDB':
        return [
          'Missing MCB',
          'Missing RCCB',
          'Wrong Component / Specs',
          'Other',
        ];
      default:
        return const [];
    }
  }

  Future<void> _pickInstallationDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _installationDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: _green),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _installationDate = picked);
    }
  }

  Future<void> _pickEboxScreenshot() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo from gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: choice == 'gallery' ? ImageSource.gallery : ImageSource.camera,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _eboxScreenshot = File(file.path));
  }

  void _showSerialHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _green, width: 1.5),
        ),
        title: const Row(
          children: [
            Text('📋', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'How to find your serial number',
                style: TextStyle(color: _green, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• Check the label sticker on the left/right/underside of the charger unit.',
              style: TextStyle(color: _green, height: 1.5),
            ),
            SizedBox(height: 8),
            Text(
              '• Look for a code often starting with "S/N", "SN", "SSN" or "TPN".',
              style: TextStyle(color: _green, height: 1.5),
            ),
            SizedBox(height: 8),
            Text(
              '• Also found on the installation certificate or warranty card.',
              style: TextStyle(color: _green, height: 1.5),
            ),
            Divider(height: 24),
            Text.rich(
              TextSpan(
                text: 'Example: ',
                style: TextStyle(color: Colors.black87),
                children: [
                  TextSpan(
                    text: 'SN1234567890',
                    style: TextStyle(color: _green, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: _green)),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_salutation == null) {
      _showError('Please select a salutation.');
      return;
    }
    if (_carBrand == null) {
      _showError('Please select a car brand / model.');
      return;
    }
    if (_carBrand == 'Others' && _carOtherController.text.trim().isEmpty) {
      _showError('Please specify your car brand / model.');
      return;
    }
    if (_installedWithRexharge == null) {
      _showError('Please answer whether your charger was installed with RExharge.');
      return;
    }
    if (_chargerBrand == null) {
      _showError('Please select a charger brand / model.');
      return;
    }
    if (_chargerBrand == 'Others' && _chargerOtherController.text.trim().isEmpty) {
      _showError('Please specify your charger brand / model.');
      return;
    }
    if (_faultyComponent == null) {
      _showError('Please select a faulty component.');
      return;
    }
    if (_describeIssueEnabled && _describeIssue == null) {
      _showError('Please describe the issue.');
      return;
    }
    setState(() => _submitting = true);

    final ticket = SupportTicket(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      salutation: _salutation!,
      fullName: _fullNameController.text.trim(),
      contactNumber: _contactController.text.trim(),
      address: _addressController.text.trim(),
      carBrand: _carBrand!,
      carBrandOther: _carBrand == 'Others' ? _carOtherController.text.trim() : null,
      installedWithRexharge: _installedWithRexharge!,
      chargerBrand: _chargerBrand!,
      chargerBrandOther: _chargerBrand == 'Others' ? _chargerOtherController.text.trim() : null,
      chargerSerialNumber: _serialController.text.trim(),
      installationDate: _installationDate,
      faultyComponent: _faultyComponent!,
      describeIssue: _describeIssueEnabled ? _describeIssue : null,
      details: _detailsController.text.trim(),
      sourceErrorCode: widget.prefill?.sourceErrorCode,
    );

    await TicketService.instance.addTicket(ticket);
    await TicketService.instance.load();

    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ticket submitted successfully.')),
    );
    Navigator.pop(context, true);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _labelColor,
        title: const Text(
          'New Ticket',
          style: TextStyle(fontWeight: FontWeight.bold, color: _labelColor),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            _buildPageHeader(),
            const SizedBox(height: 24),
            _buildSectionTitle('PERSONAL INFORMATION'),
            const SizedBox(height: 16),
            _buildFieldLabel('SALUTATION', required: true),
            const SizedBox(height: 8),
            _buildChipRow(
              options: const ['Mr', 'Ms'],
              selected: _salutation,
              onSelected: (v) => setState(() => _salutation = v),
            ),
            const SizedBox(height: 16),
            _buildFieldLabel('FULL NAME', required: true),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _fullNameController,
              hint: 'e.g. Ahmad bin Ibrahim',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildFieldLabel('CONTACT NUMBER', required: true),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _contactController,
              hint: 'e.g. 01X-XXXXXXXX',
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildFieldLabel('ADDRESS', required: true),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _addressController,
              hint: 'Full address',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 28),
            _buildSectionTitle('VEHICLE DETAILS'),
            const SizedBox(height: 16),
            _buildFieldLabel('CAR BRAND / MODEL', required: true),
            const SizedBox(height: 8),
            _buildChipRow(
              options: _carBrands,
              selected: _carBrand,
              onSelected: (v) => setState(() {
                _carBrand = v;
                if (v != 'Others') _carOtherController.clear();
              }),
            ),
            const SizedBox(height: 8),
            _buildOthersField(
              controller: _carOtherController,
              selected: _carBrand == 'Others',
              onTap: () => setState(() => _carBrand = 'Others'),
            ),
            const SizedBox(height: 16),
            _buildFieldLabel('HAVE YOU INSTALLED YOUR CHARGER WITH REXHARGE?', required: true),
            const SizedBox(height: 8),
            _buildDropdown<String>(
              value: _installedWithRexharge,
              hint: 'Select',
              items: _rexhargeOptions,
              onChanged: (v) => setState(() => _installedWithRexharge = v),
            ),
            const SizedBox(height: 28),
            _buildSectionTitle('CHARGER DETAILS'),
            const SizedBox(height: 16),
            _buildFieldLabel('CHARGER BRAND / MODEL', required: true),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _chargerBrands.map((brand) {
                final selected = _chargerBrand == brand;
                return _buildChip(
                  label: brand,
                  selected: selected,
                  onTap: () => setState(() {
                    _chargerBrand = brand;
                    _chargerOtherController.clear();
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            _buildOthersField(
              controller: _chargerOtherController,
              selected: _chargerBrand == 'Others',
              onTap: () => setState(() => _chargerBrand = 'Others'),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _buildFieldLabel('CHARGER SERIAL NUMBER', required: true)),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _showSerialHelp,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.help_outline, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _serialController,
              hint: 'e.g. SN1234567890',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildFieldLabel('INSTALLATION DATE'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickInstallationDate,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: _borderGrey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _installationDate == null
                            ? 'dd/mm/yyyy'
                            : '${_installationDate!.day.toString().padLeft(2, '0')}/${_installationDate!.month.toString().padLeft(2, '0')}/${_installationDate!.year}',
                        style: TextStyle(
                          color: _installationDate == null ? _hintGrey : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Icon(Icons.calendar_today_outlined, size: 18, color: _hintGrey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            _buildSectionTitle('ISSUE DETAILS'),
            const SizedBox(height: 16),
            _buildFieldLabel('FAULTY COMPONENT', required: true),
            const SizedBox(height: 8),
            _buildDropdown<String>(
              value: _faultyComponent,
              hint: 'Select',
              items: _faultyComponents,
              onChanged: (v) => setState(() {
                _faultyComponent = v;
                _describeIssue = null;
                _eboxScreenshot = null;
              }),
            ),
            if (_showOtherHint) ...[
              const SizedBox(height: 8),
              const Text(
                'Please describe your issue in the Detail Section below.',
                style: TextStyle(color: _hintGrey, fontSize: 13, height: 1.4),
              ),
            ],
            const SizedBox(height: 16),
            _buildFieldLabel('DESCRIBE ISSUE', required: _describeIssueEnabled),
            const SizedBox(height: 8),
            _buildDropdown<String>(
              value: _describeIssue,
              hint: 'Select',
              items: _describeIssueOptions,
              enabled: _describeIssueEnabled,
              onChanged: (v) => setState(() {
                _describeIssue = v;
                if (v != 'Solid red light') _eboxScreenshot = null;
              }),
            ),
            if (_showSolidRedUpload) ...[
              const SizedBox(height: 16),
              _buildFieldLabel('E.BOX APP SCREENSHOT (IF ANY)'),
              const SizedBox(height: 8),
              _buildUploadArea(
                file: _eboxScreenshot,
                onTap: _pickEboxScreenshot,
                onClear: () => setState(() => _eboxScreenshot = null),
                emptyLabel: 'Tap to upload e.Box app screenshot (optional)',
                optional: true,
              ),
            ],
            const SizedBox(height: 16),
            _buildFieldLabel('DETAILS', required: true),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _detailsController,
              hint: 'Describe the issue in detail...',
              maxLines: 5,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Submit Ticket',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _greenLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.description_outlined, color: _green, size: 26),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'Please fill in all required fields marked with *',
              style: TextStyle(fontSize: 13, color: _hintGrey, height: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _sectionGrey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: _borderGrey),
      ],
    );
  }

  Widget _buildFieldLabel(String label, {bool required = false}) {
    return RichText(
      softWrap: true,
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: _labelColor,
          letterSpacing: 0.3,
          height: 1.3,
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _hintGrey, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildChipRow({
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelected,
  }) {
    return Row(
      children: options.map((option) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: option != options.last ? 8 : 0),
            child: _buildChip(
              label: option,
              selected: selected == option,
              onTap: () => onSelected(option),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? _greenLight : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _green : _borderGrey,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? _green : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildOthersField({
    required TextEditingController controller,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? _greenLight : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _green : _borderGrey,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: TextField(
          controller: controller,
          onTap: onTap,
          enabled: selected,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          decoration: const InputDecoration(
            hintText: 'Others – please specify',
            hintStyle: TextStyle(color: _hintGrey, fontSize: 14),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    bool enabled = true,
  }) {
    const selectedColor = Color(0xFF212121);
    const hintColor = Color(0xFF757575);
    const disabledHintColor = Color(0xFF9E9E9E);

    return Theme(
      data: ThemeData.light().copyWith(
        canvasColor: Colors.white,
        dropdownMenuTheme: const DropdownMenuThemeData(
          textStyle: TextStyle(color: selectedColor, fontSize: 14),
        ),
      ),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xFFF0F0F0),
          border: Border.all(color: enabled ? _borderGrey : const Color(0xFFE8E8E8)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            dropdownColor: Colors.white,
            style: TextStyle(
              fontSize: 14,
              color: enabled ? selectedColor : disabledHintColor,
              fontWeight: FontWeight.w500,
            ),
            hint: Text(
              hint,
              style: TextStyle(
                color: enabled ? hintColor : disabledHintColor,
                fontSize: 14,
              ),
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: enabled ? hintColor : disabledHintColor,
            ),
            items: items
                .map(
                  (item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      item.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: selectedColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadArea({
    required File? file,
    required VoidCallback onTap,
    required VoidCallback onClear,
    required String emptyLabel,
    bool optional = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 120),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderGrey, style: BorderStyle.solid),
        ),
        child: file == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 32,
                        color: _hintGrey.withValues(alpha: 0.8),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        emptyLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _hintGrey, fontSize: 13),
                      ),
                      if (optional)
                        const Text(
                          '(Optional)',
                          style: TextStyle(color: _hintGrey, fontSize: 11),
                        ),
                    ],
                  ),
                ),
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      file,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 16,
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: onClear,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

}
