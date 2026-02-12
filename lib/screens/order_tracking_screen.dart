import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(30.0444, 31.2357), // Cairo coordinates
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onPressed: () {},
        ),
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'تتبع الطلب',
              style: GoogleFonts.cairo(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'رقم الطلب: #R-0005001',
              style: GoogleFonts.cairo(
                color: const Color(0xFFD32F2F),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end, // RTL
            children: [
              // Top Status Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFFFF5F5,
                  ), // Light reddish pink background
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left side (Items count)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '5',
                            style: GoogleFonts.cairo(
                              color: const Color(0xFFD32F2F),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'أصناف',
                            style: GoogleFonts.cairo(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Right Side (Status Text)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800), // Orange
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'في الطريق',
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.local_shipping_outlined,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'التسليم المتوقع اليوم في 4:00 مساءً',
                          style: GoogleFonts.cairo(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'الوصول خلال ساعتين تقريباً',
                          style: GoogleFonts.cairo(
                            color: const Color(0xFFD32F2F),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Map Section
              Container(
                height: 250, // Increased height for better map view
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      GoogleMap(
                        mapType: MapType.normal,
                        initialCameraPosition: _kGooglePlex,
                        onMapCreated: (GoogleMapController controller) {
                          _controller.complete(controller);
                        },
                        zoomControlsEnabled: false, // Cleaner look
                        myLocationButtonEnabled: false,
                      ),

                      // Overlay Card
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'الوقت المقدر',
                                    style: GoogleFonts.cairo(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    '25 دقيقة',
                                    style: GoogleFonts.cairo(
                                      color: const Color(0xFFD32F2F),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'المسافة المتبقية',
                                        style: GoogleFonts.cairo(
                                          color: Colors.grey,
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        '8.5 كم',
                                        style: GoogleFonts.cairo(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFEBEE), // Pinkish
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.straighten,
                                      color: Color(0xFFD32F2F),
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'مراحل الشحنة',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                'تتبع حالة طلبك خطوة بخطوة',
                style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
              ),

              const SizedBox(height: 16),

              // Verticle Timeline
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _TimelineStep(
                    title: 'طلب جديد',
                    subtitle: 'تم استلام طلبك بنجاح ونحن في خدمتك',
                    date: '7 فبراير - 10:30 ص',
                    status: TimelineStatus.completed,
                    icon: Icons.description_outlined,
                    isFirst: true,
                  ),
                  _TimelineStep(
                    title: 'تم استلام الطلب',
                    subtitle: 'تم تأكيد الطلب من قبل النظام المالي',
                    date: '7 فبراير - 10:45 ص',
                    status: TimelineStatus.completed,
                    icon: Icons.check,
                  ),
                  _TimelineStep(
                    title: 'يتم تجهيز الطلب',
                    subtitle: 'جاري تجميع وتجهيز الأصناف من المخازن',
                    date: '7 فبراير - 11:15 ص',
                    status: TimelineStatus.completed,
                    icon: Icons.inventory_2_outlined,
                  ),
                  _TimelineStep(
                    title: 'تم تأكيد الطلب',
                    subtitle: 'تمت المراجعة النهائية والموافقة على التحميل',
                    date: '7 فبراير - 12:00 م',
                    status: TimelineStatus.completed,
                    icon: Icons.hourglass_top_outlined,
                  ),
                  _TimelineStep(
                    title: 'يتم تجهيز البضائع',
                    subtitle: 'تم الانتهاء من تعبئة وتغليف جميع الأصناف',
                    date: '7 فبراير - 1:30 م',
                    status: TimelineStatus.completed,
                    icon: Icons.assignment_outlined,
                  ),
                  _TimelineStep(
                    title: 'البضاعة في الطريق',
                    subtitle: 'الشحنة في طريقها إليك الآن بكل أمان',
                    date: '7 فبراير - 02:00 م',
                    status: TimelineStatus.current,
                    icon: Icons.local_shipping_outlined,
                    isDriverInfo: true,
                  ),
                  _TimelineStep(
                    title: 'تم التسليم بنجاح',
                    subtitle: 'سيتم تحديث الحالة فور وصول الشحنة',
                    date: 'قريباً',
                    status: TimelineStatus.pending,
                    icon: Icons.verified_user_outlined,
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Bottom Action
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD32F2F)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFD32F2F)),
                    const SizedBox(width: 8),
                    Text(
                      'الإبلاغ عن مشكلة',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFFD32F2F),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

enum TimelineStatus { completed, current, pending }

class _TimelineStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final TimelineStatus status;
  final IconData icon;
  final bool isFirst;
  final bool isLast;
  final bool isDriverInfo;

  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.status,
    required this.icon,
    this.isFirst = false,
    this.isLast = false,
    this.isDriverInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color lineColor;

    if (status == TimelineStatus.completed) {
      bgColor = const Color(0xFF4CAF50); // Green
      lineColor = const Color(0xFF4CAF50);
    } else if (status == TimelineStatus.current) {
      bgColor = const Color(0xFFFF9800); // Orange
      lineColor = Colors.grey.shade300;
    } else {
      bgColor = Colors.white; // Or transparent with border
      lineColor = Colors.grey.shade300;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (status == TimelineStatus.completed)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'مكتمل',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF4CAF50),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                if (status == TimelineStatus.current)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'المرحلة الحالية',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFFFF9800),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: status == TimelineStatus.pending
                        ? Colors.grey.shade300
                        : Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: status == TimelineStatus.pending
                        ? Colors.grey.shade200
                        : Colors.grey,
                  ),
                ),
                Text(
                  date,
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: status == TimelineStatus.pending
                        ? Colors.grey.shade200
                        : (status == TimelineStatus.current
                              ? const Color(0xFFFF9800)
                              : Colors.grey), // Orange if current
                  ),
                ),

                if (isDriverInfo)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.phone,
                            color: Colors.green,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'السائق: أحمد محمد',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '4.5 ★',
                              style: GoogleFonts.cairo(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const CircleAvatar(
                          radius: 14,
                          backgroundImage: NetworkImage(
                            'https://i.pravatar.cc/100?u=driver',
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 30),
              ],
            ),
          ),

          const SizedBox(width: 16),

          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: status == TimelineStatus.pending
                      ? Border.all(color: Colors.grey.shade200)
                      : null,
                ),
                child: Icon(
                  icon,
                  color: status == TimelineStatus.pending
                      ? Colors.grey.shade200
                      : Colors.white,
                  size: 16,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: lineColor, // Dashed if pending? Solid for now.
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
