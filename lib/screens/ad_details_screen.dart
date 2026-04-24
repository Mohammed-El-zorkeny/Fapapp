import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class AdDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> ad;

  const AdDetailsScreen({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    final title = ad['title'] ?? ad['titleAr'] ?? 'إعلان';
    final body = ad['body'] ?? ad['description'] ?? ad['descriptionAr'] ?? '';
    final imageUrl = ad['imageUrl'] ?? ad['image'] ?? '';
    final date = ad['createdAt'] ?? ad['date'] ?? '';
    final tag = ad['tag'] ?? ad['category'] ?? '';
    final Color tagColor = _tagColor(tag);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Hero App Bar with image or gradient
            SliverAppBar(
              expandedHeight: imageUrl.isNotEmpty ? 260 : 180,
              pinned: true,
              backgroundColor: AppColors.primary,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: imageUrl.isNotEmpty
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(imageUrl, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _gradientHeader()),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                              ),
                            ),
                          ),
                        ],
                      )
                    : _gradientHeader(),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag + Date row
                    Row(
                      children: [
                        if (tag.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: tagColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(tag, style: GoogleFonts.cairo(fontSize: 11, color: tagColor, fontWeight: FontWeight.bold)),
                          ),
                        const Spacer(),
                        if (date.isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 13, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text(_formatDate(date), style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                      ],
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 14),

                    // Title
                    Text(
                      title,
                      style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark, height: 1.4),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 16),

                    // Divider
                    Container(height: 2, width: 40, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)))
                        .animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 16),

                    // Body text
                    if (body.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Text(
                          body,
                          style: GoogleFonts.cairo(fontSize: 15, color: AppColors.textMedium, height: 1.8),
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.campaign_rounded, color: Colors.white, size: 56),
            const SizedBox(height: 8),
            Text('إعلان', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Color _tagColor(String tag) {
    if (tag.contains('عرض') || tag.contains('خصم')) return Colors.green;
    if (tag.contains('تنبيه') || tag.contains('هام')) return Colors.orange;
    if (tag.contains('جديد')) return Colors.blue;
    return AppColors.primary;
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}
