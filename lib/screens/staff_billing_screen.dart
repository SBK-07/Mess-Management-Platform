import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/mess_billing_service.dart';
import '../utils/constants.dart';

class StaffBillingScreen extends StatefulWidget {
  const StaffBillingScreen({super.key});

  @override
  State<StaffBillingScreen> createState() => _StaffBillingScreenState();
}

class _StaffBillingScreenState extends State<StaffBillingScreen> {
  late final List<BillMonthOption> _monthOptions;
  late BillMonthOption _selected;
  late Future<List<StudentMonthlyBill>> _billsFuture;

  @override
  void initState() {
    super.initState();
    _monthOptions = MessBillingService.instance.monthOptions();
    _selected = _monthOptions.first;
    _billsFuture = _loadBills();
  }

  Future<List<StudentMonthlyBill>> _loadBills() {
    return MessBillingService.instance.getAllStudentBillsForMonth(
      year: _selected.year,
      month: _selected.month,
    );
  }

  Future<void> _reload() async {
    final refreshed = _loadBills();
    setState(() {
      _billsFuture = refreshed;
    });
    await refreshed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Student Mess Bills',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppConstants.softShadow,
            ),
            child: Row(
              children: [
                Text(
                  'Select Month:',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<BillMonthOption>(
                    value: _selected,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppConstants.backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _monthOptions
                        .map(
                          (item) => DropdownMenuItem<BillMonthOption>(
                            value: item,
                            child: Text(
                              '${item.label} ${item.year}',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selected = value;
                        _billsFuture = _loadBills();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<StudentMonthlyBill>>(
              future: _billsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Unable to load student bills.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: AppConstants.errorColor,
                        ),
                      ),
                    ),
                  );
                }

                final bills = snapshot.data ?? const <StudentMonthlyBill>[];
                final totalAmount = bills.fold<int>(
                  0,
                  (sum, bill) => sum + bill.amount,
                );
                final paidCount = bills.where((b) => b.isPaid).length;

                if (bills.isEmpty) {
                  return Center(
                    child: Text(
                      'No student bills found for ${_selected.label} ${_selected.year}.',
                      style: GoogleFonts.poppins(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFF3EB), Color(0xFFFFFBF7)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppConstants.primaryColor.withOpacity(0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_selected.label} ${_selected.year} Overview',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppConstants.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Students: ${bills.length}  |  Paid: $paidCount',
                              style: GoogleFonts.poppins(
                                color: AppConstants.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total Bill Amount: Rs $totalAmount',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: AppConstants.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...bills.map(_buildBillTile),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillTile(StudentMonthlyBill bill) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppConstants.softShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                bill.studentName.isEmpty ? 'Unknown Student' : bill.studentName,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: bill.isPaid
                    ? const Color(0xFFE8F8EF)
                    : const Color(0xFFFDF1E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                bill.isPaid ? 'Paid' : 'Pending',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: bill.isPaid
                      ? const Color(0xFF1F9D57)
                      : const Color(0xFFA46208),
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Charged days: ${bill.chargedDays}',
            style: GoogleFonts.poppins(color: AppConstants.textSecondary),
          ),
        ),
        trailing: Text(
          'Rs ${bill.amount}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppConstants.primaryDark,
          ),
        ),
      ),
    );
  }
}
