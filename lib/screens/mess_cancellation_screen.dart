import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/cancellation.dart';
import '../models/user.dart';
import '../providers/app_state.dart';
import '../services/cancellation_service.dart';

class MessCancellationScreen extends StatefulWidget {
  const MessCancellationScreen({super.key});

  @override
  State<MessCancellationScreen> createState() => _MessCancellationScreenState();
}

class _MessCancellationScreenState extends State<MessCancellationScreen> {
  final CancellationService _cancellationService = CancellationService();
  DateTimeRange? _selectedDateRange;
  String _selectedReason = 'Vacation';
  final List<String> _reasons = ['Vacation', 'Medical leave', 'Home visit', 'Others'];
  bool _isSubmitting = false;
  PlatformFile? _pickedFile;

  int get _duration => _selectedDateRange == null ? 0 : _selectedDateRange!.end.difference(_selectedDateRange!.start).inDays + 1;
  bool get _requiresAttachment => _duration > 4;

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDateRange: _selectedDateRange,
      helpText: 'SELECT CANCELLATION DATES',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade800,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.orange.shade800),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
        if (_duration <= 4) _pickedFile = null;
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
      });
    }
  }

  Future<void> _submitCancellation(AppUser user) async {
    if (_selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date range')),
      );
      return;
    }

    if (_requiresAttachment && _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF approval document is required for durations > 4 days')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? documentBase64;
      String? documentName;

      // 1. Encode PDF as base64 if attached
      if (_pickedFile != null && _pickedFile!.bytes != null) {
        debugPrint('Encoding PDF as base64...');
        documentBase64 = base64Encode(_pickedFile!.bytes!);
        documentName = _pickedFile!.name;
        debugPrint('PDF encoded: ${documentName} (${_pickedFile!.bytes!.length} bytes)');
      }

      // 2. Save to Firestore (with embedded PDF data)
      final cancellation = Cancellation(
        id: '',
        studentId: user.uid,
        studentName: user.name,
        absenceStartDate: _selectedDateRange!.start,
        absenceEndDate: _selectedDateRange!.end,
        cancellationReason: _selectedReason,
        status: _duration <= 4 ? 'Approved' : 'Pending',
        createdAt: DateTime.now(),
        documentBase64: documentBase64,
        documentName: documentName,
      );

      await _cancellationService.addCancellation(cancellation);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cancellation request submitted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _selectedDateRange = null;
          _pickedFile = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;

    if (user == null) return const Scaffold(body: Center(child: Text('Please login')));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Mess Cancellation', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Transform.translate(
              offset: const Offset(0, -24),
              child: _buildSubmissionForm(user),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Your Activity',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildCancellationsList(user.uid),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 48, left: 24, right: 24, top: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade800, Colors.orange.shade600],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan Your Absence',
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Minimize food wastage by informing the mess in advance.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionForm(AppUser user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 12,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add_task, color: Colors.orange.shade800, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Request Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDateSelector(),
              const SizedBox(height: 20),
              _buildReasonDropdown(),
              const SizedBox(height: 20),
              if (_requiresAttachment) _buildFileUploadSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(user),
              const SizedBox(height: 16),
              _buildInfoFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _pickDateRange,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.shade50.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade100, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.calendar_month_rounded, color: Colors.orange.shade900),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SELECT DURATION',
                    style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedDateRange == null
                        ? 'Select Dates'
                        : '${DateFormat('MMM d').format(_selectedDateRange!.start)}  →  ${DateFormat('MMM d').format(_selectedDateRange!.end)}',
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold, 
                      color: _selectedDateRange == null ? Colors.grey.shade600 : Colors.black87
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedDateRange != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade800,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_duration Days',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            const Icon(Icons.chevron_right, color: Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedReason,
      decoration: InputDecoration(
        labelText: 'REASON FOR CANCELLATION',
        labelStyle: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.orange.shade800, width: 2),
        ),
      ),
      items: _reasons.map((reason) {
        return DropdownMenuItem(value: reason, child: Text(reason, style: const TextStyle(fontWeight: FontWeight.w600)));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedReason = value!;
        });
      },
    );
  }

  Widget _buildFileUploadSection() {
    final String label = _selectedReason == 'Medical leave' ? 'Medical Receipt (PDF)' : 'Permission Letter (PDF)';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
        ),
        InkWell(
          onTap: _pickFile,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _pickedFile == null ? Colors.blue.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _pickedFile == null ? Colors.blue.shade100 : Colors.green.shade200, 
                width: 2,
                style: BorderStyle.solid
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _pickedFile == null ? Icons.picture_as_pdf_rounded : Icons.check_circle_rounded, 
                  color: _pickedFile == null ? Colors.blue.shade800 : Colors.green.shade800
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _pickedFile == null ? 'Upload Document' : _pickedFile!.name,
                    style: TextStyle(
                      color: _pickedFile == null ? Colors.blue.shade800 : Colors.green.shade900,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_pickedFile != null)
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, size: 20, color: Colors.green.shade800),
                    onPressed: _pickFile,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(AppUser user) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!_isSubmitting)
            BoxShadow(
              color: Colors.orange.shade800.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : () => _submitCancellation(user),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade800,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                  SizedBox(width: 16),
                  Text('PROCESSING...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                ],
              )
            : const Text('SUBMIT REQUEST', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
      ),
    );
  }

  Widget _buildInfoFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_clock_outlined, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Requests > 4 days require verification. Auto-approval for shorter durations.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontStyle: FontStyle.italic, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationsList(String studentId) {
    return StreamBuilder<List<Cancellation>>(
      stream: _cancellationService.getStudentCancellations(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading activity', style: TextStyle(color: Colors.red.shade300)));
        }
        final cancellations = snapshot.data ?? [];
        if (cancellations.isEmpty) {
          return Center(
            child: Column(
              children: [
                const SizedBox(height: 32),
                Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('No recent requests', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: cancellations.length,
          itemBuilder: (context, index) {
            final cancellation = cancellations[index];
            final bool isApproved = cancellation.status.toLowerCase() == 'approved';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04), 
                    blurRadius: 12, 
                    offset: const Offset(0, 4)
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        color: isApproved ? Colors.green : Colors.orange,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${DateFormat('MMM d').format(cancellation.absenceStartDate)} - ${DateFormat('MMM d').format(cancellation.absenceEndDate)}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isApproved ? Colors.green.shade50 : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      cancellation.status.toUpperCase(),
                                      style: TextStyle(
                                        color: isApproved ? Colors.green.shade800 : Colors.orange.shade900, 
                                        fontSize: 10, 
                                        fontWeight: FontWeight.w900
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.label_outline_rounded, size: 14, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${cancellation.cancellationReason} • ${cancellation.durationDays} days',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              if (cancellation.hasDocument) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.description, size: 12, color: Colors.blue.shade700),
                                      const SizedBox(width: 4),
                                      Text('Document Attached', style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
