import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/mess_billing_service.dart';
import '../utils/constants.dart';
import 'payment_success_screen.dart';

class StudentPendingBillsScreen extends StatefulWidget {
  const StudentPendingBillsScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  final String studentId;
  final String studentName;

  @override
  State<StudentPendingBillsScreen> createState() =>
      _StudentPendingBillsScreenState();
}

class _StudentPendingBillsScreenState extends State<StudentPendingBillsScreen> {
  late Future<List<_MonthBillView>> _billsFuture;

  @override
  void initState() {
    super.initState();
    _billsFuture = _loadBills();
  }

  Future<List<_MonthBillView>> _loadBills() async {
    final options = MessBillingService.instance.monthOptions();
    final result = <_MonthBillView>[];

    for (final item in options) {
      final summary = await MessBillingService.instance.getStudentBillForMonth(
        studentId: widget.studentId,
        year: item.year,
        month: item.month,
      );
      result.add(
        _MonthBillView(
          label: item.label,
          month: item.month,
          year: item.year,
          summary: summary,
        ),
      );
    }

    result.sort((a, b) {
      final aKey = a.year * 100 + a.month;
      final bKey = b.year * 100 + b.month;
      return bKey.compareTo(aKey);
    });

    return result;
  }

  Future<void> _refreshBills() async {
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
          'Pending Bills',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<_MonthBillView>>(
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
                  'Could not load bills.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: AppConstants.errorColor),
                ),
              ),
            );
          }

          final bills = snapshot.data ?? const <_MonthBillView>[];

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bills.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final monthBill = bills[index];
              return _buildBillCard(monthBill);
            },
          );
        },
      ),
    );
  }

  Widget _buildBillCard(_MonthBillView bill) {
    final isPending = !bill.summary.isPaid && bill.summary.amount > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppConstants.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openBillDialog(bill),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isPending
                        ? AppConstants.warningColor.withOpacity(0.13)
                        : const Color(0xFF1F9D57).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPending
                        ? Icons.pending_actions_rounded
                        : Icons.verified_rounded,
                    color: isPending
                        ? AppConstants.warningColor
                        : const Color(0xFF1F9D57),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${bill.label} ${bill.year}',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rs ${bill.summary.amount}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.primaryDark,
                        ),
                      ),
                      Text(
                        'Charged days: ${bill.summary.chargedDays}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isPending
                        ? const Color(0xFFFDF1E0)
                        : const Color(0xFFE8F8EF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPending ? 'Pending' : 'Paid',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: isPending
                          ? const Color(0xFFA46208)
                          : const Color(0xFF1F9D57),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openBillDialog(_MonthBillView bill) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        final canPay = !bill.summary.isPaid && bill.summary.amount > 0;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${bill.label} ${bill.year} Bill',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Amount: Rs ${bill.summary.amount}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primaryDark,
                  ),
                ),
                Text(
                  'Charged days: ${bill.summary.chargedDays}',
                  style: GoogleFonts.poppins(color: AppConstants.textSecondary),
                ),
                if (bill.summary.isPaid && bill.summary.paidAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Paid on: ${_formatDateTime(bill.summary.paidAt!)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF1F9D57),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: canPay
                        ? () async {
                            Navigator.pop(context);
                            await _payNow(bill);
                          }
                        : null,
                    icon: const Icon(Icons.payments_rounded),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F9D57),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: Text(
                      canPay ? 'Pay Now' : 'Already Paid',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _payNow(_MonthBillView bill) async {
    await MessBillingService.instance.markBillAsPaid(
      studentId: widget.studentId,
      studentName: widget.studentName,
      year: bill.year,
      month: bill.month,
      amount: bill.summary.amount,
    );

    if (!mounted) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          amount: bill.summary.amount,
          monthLabel: bill.label,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _refreshBills();
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }
}

class _MonthBillView {
  final String label;
  final int month;
  final int year;
  final StudentBillSummary summary;

  const _MonthBillView({
    required this.label,
    required this.month,
    required this.year,
    required this.summary,
  });
}
