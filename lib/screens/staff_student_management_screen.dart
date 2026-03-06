import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_state.dart';
import '../services/bulk_import_service.dart';
import '../utils/constants.dart';

/// Screen for mess staff to add students — manually or via bulk import.
class StaffStudentManagementScreen extends StatelessWidget {
  const StaffStudentManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Manage Students',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            tabs: const [
              Tab(icon: Icon(Icons.person_add_rounded), text: 'Add Student'),
              Tab(icon: Icon(Icons.upload_file_rounded), text: 'Bulk Import'),
            ],
          ),
        ),
        body: Container(
          color: AppConstants.backgroundColor,
          child: const TabBarView(
            children: [_AddSingleStudentTab(), _BulkImportTab()],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TAB 1: ADD SINGLE STUDENT
// ─────────────────────────────────────────────────────────────

class _AddSingleStudentTab extends StatefulWidget {
  const _AddSingleStudentTab();

  @override
  State<_AddSingleStudentTab> createState() => _AddSingleStudentTabState();
}

class _AddSingleStudentTabState extends State<_AddSingleStudentTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  final _planCtrl = TextEditingController();
  final _passCtrl = TextEditingController(text: 'mess@1234');

  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _rollCtrl.dispose();
    _roomCtrl.dispose();
    _planCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _createStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Provider.of<AppState>(context, listen: false).createStudent(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        phone: _phoneCtrl.text,
        rollNo: _rollCtrl.text,
        roomNo: _roomCtrl.text,
        messPlan: _planCtrl.text,
        tempPassword: _passCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student account created successfully!'),
          backgroundColor: AppConstants.successColor,
        ),
      );

      // Clear form
      _nameCtrl.clear();
      _emailCtrl.clear();
      _phoneCtrl.clear();
      _rollCtrl.clear();
      _roomCtrl.clear();
      _planCtrl.clear();
      _passCtrl.text = 'mess@1234';
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create a student account. Default password is mess@1234.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildTextField(_nameCtrl, 'Full Name', Icons.person),
            const SizedBox(height: 16),
            _buildTextField(
              _emailCtrl,
              'Email',
              Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _passCtrl,
              'Password',
              Icons.lock,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _phoneCtrl,
              'Phone',
              Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _rollCtrl,
                    'Roll No / Digital ID',
                    Icons.badge,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(_roomCtrl, 'Room No', Icons.room),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _planCtrl,
              'Department / Mess Plan',
              Icons.restaurant_menu,
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _createStudent,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Create Account',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: (val) =>
          val == null || val.isEmpty ? '$label is required' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TAB 2: BULK IMPORT
// ─────────────────────────────────────────────────────────────

class _BulkImportTab extends StatefulWidget {
  const _BulkImportTab();

  @override
  State<_BulkImportTab> createState() => _BulkImportTabState();
}

class _BulkImportTabState extends State<_BulkImportTab> {
  final _importService = BulkImportService.instance;

  List<StudentImportRecord>? _parsedRecords;
  String? _fileName;
  bool _isParsing = false;
  bool _isImporting = false;
  int _importProgress = 0;
  int _importTotal = 0;
  List<Map<String, dynamic>>? _importResults;
  String? _parseError;

  Future<void> _pickFile() async {
    setState(() {
      _parseError = null;
      _parsedRecords = null;
      _importResults = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final fileBytes = file.bytes;
      if (fileBytes == null || fileBytes.isEmpty) {
        setState(
          () => _parseError = 'Could not read file data. Please try again.',
        );
        return;
      }

      setState(() {
        _isParsing = true;
        _fileName = file.name;
      });

      final ext = (file.extension ?? file.name.split('.').last).toLowerCase();
      List<StudentImportRecord> records;

      if (ext == 'xlsx' || ext == 'xls') {
        records = _importService.parseXlsx(fileBytes);
      } else if (ext == 'pdf') {
        records = _importService.parsePdf(fileBytes);
      } else {
        setState(() {
          _isParsing = false;
          _parseError = 'Unsupported file format. Please use .xlsx or .pdf';
        });
        return;
      }

      setState(() {
        _isParsing = false;
        _parsedRecords = records;
        if (records.isEmpty) {
          _parseError =
              'No student records found in the file. Make sure the file has columns like Name, Department, Email, and Digital ID.';
        }
      });
    } catch (e, stack) {
      debugPrint('File pick/parse error: $e\n$stack');
      setState(() {
        _isParsing = false;
        _parseError =
            'Error processing file: ${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  Future<void> _importStudents() async {
    if (_parsedRecords == null || _parsedRecords!.isEmpty) return;

    // Pre-validate: count records with valid vs invalid emails
    final validCount = _parsedRecords!
        .where((r) => r.email.trim().isNotEmpty && r.email.contains('@'))
        .length;
    final invalidCount = _parsedRecords!.length - validCount;

    // Show confirmation dialog
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Import'),
        content: Text(
          'This will create $validCount student accounts with email as login ID '
          'and "mess@1234" as the default password.'
          '${invalidCount > 0 ? '\n\n$invalidCount record(s) have missing or invalid emails and will be skipped.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (shouldProceed != true || !mounted) return;

    setState(() {
      _isImporting = true;
      _importProgress = 0;
      _importTotal = _parsedRecords!.length;
    });

    try {
      final students = _parsedRecords!
          .map(
            (r) => {
              'name': r.name,
              'email': r.email,
              'department': r.department,
              'digitalId': r.digitalId,
            },
          )
          .toList();

      final results = await Provider.of<AppState>(context, listen: false)
          .createStudentsBulk(
            students: students,
            onProgress: (completed, total) {
              if (mounted) {
                setState(() {
                  _importProgress = completed;
                  _importTotal = total;
                });
              }
            },
          );

      if (!mounted) return;
      setState(() {
        _isImporting = false;
        _importResults = results;
      });

      // Show success snackbar
      final successCount = results.where((r) => r['success'] == true).length;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$successCount student accounts created successfully!',
            ),
            backgroundColor: AppConstants.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _removeRecord(int index) {
    setState(() {
      _parsedRecords!.removeAt(index);
      if (_parsedRecords!.isEmpty) {
        _parsedRecords = null;
        _fileName = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.upload_file_rounded,
                      color: AppConstants.primaryColor,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Bulk Import Students',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Upload an Excel (.xlsx) or PDF file containing student details. '
                  'The file should have columns for Name, Department, Email, and Digital ID.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expected columns:',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _columnHint('Name', 'Full name of student'),
                      _columnHint('Department', 'e.g. CSE, ECE, ME'),
                      _columnHint('Email', 'College email ID'),
                      _columnHint(
                        'Digital ID',
                        'Roll number / registration no',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Default password: mess@1234 (students change it on first login)',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Upload button
          OutlinedButton.icon(
            onPressed: _isParsing ? null : _pickFile,
            icon: _isParsing
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_outlined),
            label: Text(
              _isParsing
                  ? 'Parsing file...'
                  : (_fileName != null
                        ? 'Change File ($_fileName)'
                        : 'Select Excel or PDF File'),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.primaryColor,
              side: BorderSide(
                color: AppConstants.primaryColor.withOpacity(0.5),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Error message
          if (_parseError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.errorColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppConstants.errorColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppConstants.errorColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _parseError!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppConstants.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Parsed records preview
          if (_parsedRecords != null && _parsedRecords!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Preview (${_parsedRecords!.length} students found)',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _parsedRecords = null;
                    _fileName = null;
                    _importResults = null;
                  }),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppConstants.errorColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Student list
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header row
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.06),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        _headerCell('Name', flex: 3),
                        _headerCell('Department', flex: 2),
                        _headerCell('Email', flex: 3),
                        _headerCell('Digital ID', flex: 2),
                        const SizedBox(width: 32),
                      ],
                    ),
                  ),
                  // Data rows
                  ...List.generate(_parsedRecords!.length, (index) {
                    final record = _parsedRecords![index];
                    final hasResult =
                        _importResults != null &&
                        index < _importResults!.length;
                    final success = hasResult
                        ? _importResults![index]['success']
                        : null;
                    final hasInvalidEmail =
                        record.email.trim().isEmpty ||
                        !record.email.contains('@');

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: hasResult
                            ? (success == true
                                  ? AppConstants.successColor.withOpacity(0.05)
                                  : AppConstants.errorColor.withOpacity(0.05))
                            : hasInvalidEmail
                            ? Colors.orange.withOpacity(0.08)
                            : null,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade100),
                        ),
                      ),
                      child: Row(
                        children: [
                          _dataCell(record.name, flex: 3),
                          _dataCell(record.department, flex: 2),
                          _dataCell(
                            record.email.isEmpty ? '(no email)' : record.email,
                            flex: 3,
                            color: hasInvalidEmail ? Colors.red : null,
                          ),
                          _dataCell(record.digitalId, flex: 2),
                          if (hasResult)
                            Icon(
                              success == true
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: success == true
                                  ? AppConstants.successColor
                                  : AppConstants.errorColor,
                              size: 18,
                            )
                          else
                            SizedBox(
                              width: 32,
                              child: IconButton(
                                icon: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                                onPressed: () => _removeRecord(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Import results summary
            if (_importResults != null) ...[
              _buildResultsSummary(),
              const SizedBox(height: 16),
            ],

            // Import button
            if (_importResults == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isImporting) ...[
                    // Progress bar during import
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Creating accounts... $_importProgress / $_importTotal',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppConstants.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                _importTotal > 0
                                    ? '${(_importProgress / _importTotal * 100).toInt()}%'
                                    : '0%',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: _importTotal > 0
                                  ? _importProgress / _importTotal
                                  : 0,
                              backgroundColor: AppConstants.primaryColor
                                  .withAlpha(30),
                              color: AppConstants.primaryColor,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    ElevatedButton.icon(
                      onPressed: _importStudents,
                      icon: const Icon(Icons.group_add_rounded),
                      label: Text(
                        'Import ${_parsedRecords!.length} Students',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsSummary() {
    final success = _importResults!.where((r) => r['success'] == true).length;
    final failed = _importResults!.length - success;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: failed == 0
            ? AppConstants.successColor.withOpacity(0.08)
            : AppConstants.warningColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: failed == 0
              ? AppConstants.successColor.withOpacity(0.3)
              : AppConstants.warningColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                failed == 0 ? Icons.celebration : Icons.info_outline,
                color: failed == 0
                    ? AppConstants.successColor
                    : AppConstants.warningColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Import Complete',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$success accounts created successfully'
            '${failed > 0 ? ', $failed failed' : ''}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppConstants.textSecondary,
            ),
          ),
          if (failed > 0) ...[
            const SizedBox(height: 8),
            ...(_importResults!
                .where((r) => r['success'] != true)
                .map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${r['name'] ?? r['email']}: ${r['error']}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppConstants.errorColor,
                      ),
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _columnHint(String name, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$name — ',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            desc,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppConstants.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppConstants.textSecondary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _dataCell(String text, {int flex = 1, Color? color}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: color ?? AppConstants.textPrimary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
