import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../services/api_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;
  final String? invoiceNumber;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    this.invoiceNumber,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _steps = [];
  String _currentStatus = '';
  int _currentStep = 0;
  int _totalSteps = 0;

  @override
  void initState() {
    super.initState();
    _loadTrackingData();
  }

  Future<void> _loadTrackingData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.getOrderStatusSteps(widget.orderId);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['success']) {
            final data = result['data'];
            _steps = data['steps'] ?? [];
            _currentStatus = data['currentStatus'] ?? '';
            _currentStep = data['currentStep'] ?? 0;
            _totalSteps = data['totalSteps'] ?? 0;
          } else {
            _errorMessage = result['message'];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'حدث خطأ: $e';
        });
      }
    }
  }

  Color _getStepColor(String state) {
    switch (state) {
      case 'done':
        return const Color(0xFF00B894);
      case 'current':
        return const Color(0xFF0984E3);
      case 'pending':
      default:
        return Colors.grey.shade300;
    }
  }

  IconData _getStepIconByCode(String code) {
    switch (code) {
      case 'NEW':
        return Icons.add_circle_outline;
      case 'SEND':
        return Icons.send_outlined;
      case 'RECEIVED':
        return Icons.inbox_outlined;
      case 'IN_PROGRESS':
        return Icons.autorenew;
      case 'SEND_TO_CLIENT':
        return Icons.person_outline;
      case 'ANSWERED_BY_CLIENT':
        return Icons.thumb_up_outlined;
      case 'INVOICED':
        return Icons.receipt_outlined;
      case 'IN_PROGRESS_STOCK':
        return Icons.inventory_outlined;
      case 'DONE_STOCK':
        return Icons.check_box_outlined;
      case 'WAITING_DELIVERY_DATE':
        return Icons.calendar_today_outlined;
      case 'ORDER_WAY':
        return Icons.local_shipping_outlined;
      case 'CUSTOMER_ORDER_RECEIVED':
        return Icons.handshake_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(child: _buildBody()),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تتبع الطلب', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                if (widget.invoiceNumber != null)
                  Text(widget.invoiceNumber!, style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textLight)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 22),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text('جاري تحميل حالة الطلب...', style: GoogleFonts.cairo(color: AppColors.textLight)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _loadTrackingData,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                child: Text('إعادة المحاولة', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: Column(
        children: [
          _buildProgressCard(),
          const SizedBox(height: 24),
          _buildStepsTimeline(),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final double progress = _totalSteps > 0 ? _currentStep / _totalSteps : 0;
    final int percentage = (progress * 100).round();

    String currentDesc = '';
    for (var step in _steps) {
      if (step['state'] == 'current') {
        currentDesc = step['description'] ?? '';
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF0984E3), Color(0xFF6C5CE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: const Color(0xFF0984E3).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(
        children: [
          Positioned(top: -15, left: -15, child: Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)))),
          Positioned(bottom: -10, right: -10, child: Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('طلب رقم #${widget.orderId}', style: GoogleFonts.cairo(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 10),
                        Text('الحالة الحالية', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
                        Text(currentDesc, style: GoogleFonts.cairo(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 6,
                            backgroundColor: Colors.white.withOpacity(0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Text('$percentage%', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$_currentStep من $_totalSteps مرحلة', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11)),
                  Text(_getStatusLabel(_currentStatus), style: GoogleFonts.cairo(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'NEW': return 'جديد';
      case 'SEND': return 'تم الإرسال';
      case 'RECEIVED': return 'تم الاستلام';
      case 'IN_PROGRESS': return 'جاري التجهيز';
      case 'SEND_TO_CLIENT': return 'ينتظر التأكيد';
      case 'ANSWERED_BY_CLIENT': return 'تم التأكيد';
      case 'INVOICED': return 'تمت الفوترة';
      case 'IN_PROGRESS_STOCK': return 'تجهيز المخازن';
      case 'DONE_STOCK': return 'تم التجهيز';
      case 'WAITING_DELIVERY_DATE': return 'انتظار التسليم';
      case 'ORDER_WAY': return 'في الطريق';
      case 'CUSTOMER_ORDER_RECEIVED': return 'تم الاستلام';
      default: return status;
    }
  }

  Widget _buildStepsTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('مراحل الطلب', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 16),
        ...List.generate(_steps.length, (index) {
          final step = _steps[index] as Map<String, dynamic>;
          final state = step['state'] ?? 'pending';
          final isLast = index == _steps.length - 1;
          return _buildTimelineStep(step, state, isLast, index);
        }),
      ],
    );
  }

  Widget _buildTimelineStep(Map<String, dynamic> step, String state, bool isLast, int index) {
    final Color stepColor = _getStepColor(state);
    final bool isDone = state == 'done';
    final bool isCurrent = state == 'current';
    final bool isPending = state == 'pending';
    final String code = step['code'] ?? '';
    final String description = step['description'] ?? '';
    final int stepNum = step['step'] ?? 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline Column
        SizedBox(
          width: 48,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isCurrent ? 44 : 36,
                height: isCurrent ? 44 : 36,
                decoration: BoxDecoration(
                  color: isDone ? stepColor : isCurrent ? stepColor.withOpacity(0.15) : Colors.grey.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: stepColor,
                    width: isCurrent ? 2.5 : isDone ? 0 : 1.5,
                  ),
                  boxShadow: isCurrent ? [
                    BoxShadow(color: stepColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                  ] : isDone ? [
                    BoxShadow(color: stepColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3)),
                  ] : [],
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : isCurrent
                          ? Icon(_getStepIconByCode(code), color: stepColor, size: 18)
                          : Text(
                              '$stepNum',
                              style: GoogleFonts.cairo(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                ),
              ),
              if (!isLast)
                Container(
                  width: isDone ? 3 : 2,
                  height: 40,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: isDone ? stepColor : isCurrent ? null : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                    gradient: isCurrent ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [stepColor, Colors.grey.shade200],
                    ) : null,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Content Card
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 12, top: isCurrent ? 4 : 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isCurrent ? stepColor.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCurrent ? stepColor.withOpacity(0.2) : isDone ? stepColor.withOpacity(0.1) : Colors.grey.shade100,
                width: isCurrent ? 1.5 : 1,
              ),
              boxShadow: [
                if (!isPending)
                  BoxShadow(
                    color: isCurrent ? stepColor.withOpacity(0.06) : Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: isCurrent || isDone ? FontWeight.bold : FontWeight.w600,
                          color: isPending ? Colors.grey.shade400 : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDone
                              ? const Color(0xFF00B894).withOpacity(0.08)
                              : isCurrent
                                  ? const Color(0xFF0984E3).withOpacity(0.08)
                                  : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isDone ? '✓ مكتمل' : isCurrent ? '● جاري حالياً' : '○ قادم',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDone
                                ? const Color(0xFF00B894)
                                : isCurrent
                                    ? const Color(0xFF0984E3)
                                    : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: stepColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_getStepIconByCode(code), color: stepColor, size: 18),
                  ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: (200 + index * 60).ms, duration: 300.ms).slideX(begin: 0.05, end: 0);
  }
}
