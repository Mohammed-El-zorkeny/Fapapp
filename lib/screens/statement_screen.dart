import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' as intl;
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

class StatementScreen extends StatefulWidget {
  const StatementScreen({super.key});

  @override
  State<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  int? _currentCustomerId;

  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  List<Map<String, dynamic>> _statementData = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserAndFetch();
  }

  Future<void> _loadUserAndFetch() async {
    final userData = await _storageService.getUserData();
    if (userData != null) {
      setState(() {
        _currentCustomerId = int.tryParse(userData['userId']?.toString() ?? '');
      });
      if (_currentCustomerId != null) {
        _fetchStatement();
      }
    }
  }

  Future<void> _fetchStatement() async {
    if (_currentCustomerId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statementData = [];
    });

    final dateFormat = intl.DateFormat('dd-MM-yyyy');
    final result = await _apiService.getCustomerStatement(
      customerId: _currentCustomerId!,
      startDate: dateFormat.format(_startDate),
      endDate: dateFormat.format(_endDate),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _statementData = List<Map<String, dynamic>>.from(result['data']);
        } else {
          _errorMessage = result['message'];
        }
      });
    }
  }

  double get _balance {
    if (_statementData.isEmpty) return 0.0;
    return (_statementData.last['netBalance'] as num?)?.toDouble() ?? 0.0;
  }

  bool get _isDebitBalance => _balance > 0;

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  double get _totalDebit {
    double total = 0;
    for (var t in _statementData) {
      total += (t['debitAmount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  double get _totalCredit {
    double total = 0;
    for (var t in _statementData) {
      total += (t['creditAmount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  void _openDateFilterSheet() {
    DateTime tempStart = _startDate;
    DateTime tempEnd = _endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Directionality(
                textDirection: ui.TextDirection.rtl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.date_range, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Text('تحديد الفترة الزمنية', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSheetDatePicker(
                              label: 'من تاريخ',
                              value: tempStart,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context, initialDate: tempStart,
                                  firstDate: DateTime(2020), lastDate: DateTime(DateTime.now().year + 1),
                                  locale: const Locale('ar'),
                                );
                                if (picked != null) setSheetState(() => tempStart = picked);
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward, color: Colors.grey.shade400, size: 20),
                          ),
                          Expanded(
                            child: _buildSheetDatePicker(
                              label: 'إلى تاريخ',
                              value: tempEnd,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context, initialDate: tempEnd,
                                  firstDate: DateTime(2020), lastDate: DateTime(DateTime.now().year + 1),
                                  locale: const Locale('ar'),
                                );
                                if (picked != null) setSheetState(() => tempEnd = picked);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 5))],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    setState(() { _startDate = tempStart; _endDate = tempEnd; });
                                    Navigator.pop(context);
                                    _fetchStatement();
                                  },
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.search, color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Text('عرض الكشف', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetDatePicker({required String label, required DateTime value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(_formatDate(value), style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Column(
            children: [
              // Custom AppBar
              _buildAppBar(),
              // Balance Card
              _buildBalanceCard(),
              // Period & Stats
              _buildPeriodChips(),
              // Transactions header
              _buildTransactionsHeader(),
              // Transactions list
              Expanded(child: _buildTransactionsList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: const Icon(Icons.arrow_forward_ios, color: AppColors.textDark, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text('كشف الحساب', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          ),
          GestureDetector(
            onTap: _openDateFilterSheet,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.filter_list_rounded, color: AppColors.primary, size: 22),
                  Positioned(
                    top: -2, right: -2,
                    child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildBalanceCard() {
    final bool isDebit = _isDebitBalance;
    final double absBalance = _balance.abs();
    final Color statusColor = isDebit ? AppColors.error : Colors.green;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFE21C34), Color(0xFF8B0A1E), Color(0xFF500B28)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: const Color(0xFFE21C34).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(
        children: [
          Positioned(top: -20, left: -15, child: Container(width: 70, height: 70, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)))),
          Positioned(bottom: -10, right: -10, child: Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04)))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الرصيد الحالي', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isDebit ? Icons.arrow_upward : Icons.arrow_downward, color: isDebit ? const Color(0xFFFF6B6B) : const Color(0xFF55EFC4), size: 14),
                        const SizedBox(width: 4),
                        Text(isDebit ? 'عليك' : 'لك', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${formatMoney(absBalance)} ج.م',
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Debit / Credit summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B6B).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.arrow_upward, color: Color(0xFFFF6B6B), size: 14),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('مدين', style: GoogleFonts.cairo(color: Colors.white60, fontSize: 10)),
                              Text('${_totalDebit.toStringAsFixed(0)}', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 30, color: Colors.white.withOpacity(0.15)),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF55EFC4).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.arrow_downward, color: Color(0xFF55EFC4), size: 14),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('دائن', style: GoogleFonts.cairo(color: Colors.white60, fontSize: 10)),
                              Text('${_totalCredit.toStringAsFixed(0)}', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPeriodChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(
        children: [
          Icon(Icons.date_range, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Text(
              '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
              style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
          const Spacer(),
          if (!_isLoading && _statementData.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text('${_statementData.length} عملية', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
            ),
        ],
      ).animate().fadeIn(delay: 300.ms),
    );
  }

  Widget _buildTransactionsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('تفاصيل العمليات', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          if (_isLoading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(_errorMessage!, style: GoogleFonts.cairo(color: Colors.grey)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _fetchStatement,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                child: Text('إعادة المحاولة', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    if (_statementData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(
              _currentCustomerId == null ? 'يرجى تسجيل الدخول لعرض كشف الحساب' : 'لا توجد بيانات للفترة المحددة',
              style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14),
            ),
            if (_currentCustomerId != null) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _openDateFilterSheet,
                child: Text('تغيير الفترة الزمنية', style: GoogleFonts.cairo(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13, decoration: TextDecoration.underline)),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchStatement,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _statementData.length,
        itemBuilder: (context, index) {
          final seq = (index + 1).toString().padLeft(2, '0');
          return _buildTransactionCard(_statementData[index], seq, index);
        },
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction, String seq, int index) {
    final double debit = (transaction['debitAmount'] as num?)?.toDouble() ?? 0.0;
    final double credit = (transaction['creditAmount'] as num?)?.toDouble() ?? 0.0;
    final bool isDebit = debit > 0;
    final double amount = isDebit ? debit : credit;
    final bool isOpening = transaction['descriptionAr'] == 'رصيد افتتاحي';
    final Color amountColor = isOpening ? Colors.blue : (credit > 0 ? Colors.green : AppColors.error);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: amountColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              seq,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: amountColor, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['descriptionAr'] ?? '',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                ),
                if (transaction['transDate'] != null)
                  Text(
                    transaction['transDate'].toString(),
                    style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textLight),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${credit > 0 ? '+' : '-'}${amount.toStringAsFixed(0)}',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15, color: amountColor),
              ),
              Text(
                credit > 0 ? 'دائن' : 'مدين',
                style: GoogleFonts.cairo(fontSize: 9, color: amountColor.withOpacity(0.7)),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 40).ms, duration: 250.ms).slideX(begin: 0.05, end: 0);
  }
}
