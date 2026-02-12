import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: Text(
            'الإشعارات',
            style: GoogleFonts.cairo(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.done_all,
                      color: Color(0xFFD32F2F),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'تحديد كـ مقروء',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFFD32F2F),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: TabBar(
                padding: EdgeInsets.zero,
                labelColor: const Color(0xFFD32F2F),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFD32F2F),
                indicatorWeight: 3,
                labelStyle: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('فواتير'),
                        const SizedBox(width: 4),
                        const Icon(Icons.description_outlined),
                        const SizedBox(width: 4),
                        CircleAvatar(
                          radius: 9,
                          backgroundColor: const Color(0xFFD32F2F),
                          child: Text(
                            '3',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('التحويلات'),
                        SizedBox(width: 4),
                        Icon(Icons.sync_alt),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('العام'),
                        SizedBox(width: 4),
                        Icon(Icons.notifications_none),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _BillsTab(),
            Center(child: Text('التحويلات')),
            Center(child: Text('العام')),
          ],
        ),
      ),
    );
  }
}

class _BillsTab extends StatelessWidget {
  const _BillsTab();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card 1
          const _NotificationCard(
            title: 'فاتورة جديدة #0005001-R',
            subtitle: 'تم إنشاء فاتورة توريد جديدة بقيمة 2,550.00 جنيه.',
            time: 'منذ 5 دقائق',
            icon: Icons.note_add_outlined,
            iconColor: Color(0xFF2E7D32),
            iconBgColor: Color(0xFFE8F5E9),
            isUnread: true,
            isWarning: false,
            isArchive: false,
          ),

          const SizedBox(height: 12),

          // Card 2
          const _NotificationCard(
            title: 'تم استلام الدفع',
            subtitle: 'تم تأكيد سداد الفاتورة #0004998-R بنجاح.',
            time: 'منذ ساعة',
            icon: Icons.check_circle_outline,
            iconColor: Color(0xFF1976D2),
            iconBgColor: Color(0xFFE3F2FD),
            isUnread: false,
            isWarning: false,
            isArchive: false,
          ),

          const SizedBox(height: 12),

          // Card 3
          const _NotificationCard(
            title: 'تنبيه بالسداد',
            subtitle: 'يرجى سداد الفاتورة المستحقة #0004985-R قبل الموعد.',
            time: 'منذ ساعتين',
            icon: Icons.info_outline,
            iconColor: Color(0xFFEF6C00),
            iconBgColor: Color(0xFFFFF3E0),
            isUnread: true,
            isWarning: true,
            isArchive: false,
          ),

          const SizedBox(height: 24),

          // Section Header
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0, right: 4),
            child: Text(
              'أمس',
              style: GoogleFonts.cairo(
                color: const Color(0xFF9E9E9E),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          // Card 4
          const _NotificationCard(
            title: 'أرشفة فاتورة',
            subtitle: 'تم أرشفة الفاتورة السابقة #0004900-R تلقائياً.',
            time: '10:30 ص',
            icon: Icons.archive_outlined,
            iconColor: Color(0xFF616161),
            iconBgColor: Color(0xFFF5F5F5),
            isUnread: false,
            isWarning: false,
            isArchive: true,
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final bool isUnread;
  final bool isWarning;
  final bool isArchive;

  const _NotificationCard({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.isUnread,
    required this.isWarning,
    required this.isArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWarning || isUnread ? const Color(0xFFFFEBEE) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          time,
                          style: GoogleFonts.cairo(
                            color: isWarning
                                ? const Color(0xFFB71C1C)
                                : const Color(0xFF757575),
                            fontSize: 11,
                          ),
                        ),
                        if (isUnread)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD32F2F),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    color: Colors.grey[700],
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
