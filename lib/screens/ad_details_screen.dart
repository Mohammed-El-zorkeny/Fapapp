import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class AdDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> ad;

  const AdDetailsScreen({super.key, required this.ad});

  @override
  State<AdDetailsScreen> createState() => _AdDetailsScreenState();
}

class _AdDetailsScreenState extends State<AdDetailsScreen> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  late final List<String> _imageUrls;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Parse comma-separated image URLs
    final rawUrl = (widget.ad['imageUrl'] ?? widget.ad['image'] ?? '').toString();
    _imageUrls = rawUrl.split(',').map((u) => u.trim()).where((u) => u.isNotEmpty && u.startsWith('http')).toList();
    
    // Auto-scroll every 3 seconds if multiple images
    if (_imageUrls.length > 1) {
      _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (mounted) {
          _currentPage = (_currentPage + 1) % _imageUrls.length;
          _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
        }
      });
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;
    final title = ad['titleAr'] ?? ad['title'] ?? 'إعلان';
    final body = ad['descriptionAr'] ?? ad['body'] ?? ad['description'] ?? '';
    final date = ad['startDate'] ?? ad['createdAt'] ?? ad['date'] ?? '';
    final adType = (ad['adType'] ?? ad['tag'] ?? ad['category'] ?? '').toString();
    final Color tagColor = _tagColor(adType);
    final bool hasImages = _imageUrls.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Hero App Bar with image carousel or gradient
            SliverAppBar(
              expandedHeight: hasImages ? 320 : 180,
              pinned: true,
              backgroundColor: Colors.black,
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
                background: hasImages
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          // Black background so contain doesn't show gaps
                          Container(color: Colors.black),
                          // Image carousel — contain shows full image
                          PageView.builder(
                            controller: _pageController,
                            itemCount: _imageUrls.length,
                            onPageChanged: (index) {
                              setState(() => _currentPage = index);
                            },
                            itemBuilder: (context, index) {
                              return Image.network(
                                _imageUrls[index],
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => _gradientHeader(),
                              );
                            },
                          ),
                          // Subtle bottom gradient for dots readability
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 60,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                                ),
                              ),
                            ),
                          ),
                          // Page dots indicator
                          if (_imageUrls.length > 1)
                            Positioned(
                              bottom: 16,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(_imageUrls.length, (index) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: _currentPage == index ? 24 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          // Image count badge
                          if (_imageUrls.length > 1)
                            Positioned(
                              top: 50,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_currentPage + 1}/${_imageUrls.length}',
                                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
                        if (adType.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: tagColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(_adTypeLabel(adType), style: GoogleFonts.cairo(fontSize: 11, color: tagColor, fontWeight: FontWeight.bold)),
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
                          body.replaceAll(RegExp(r'\r\n|\r|\n'), '\n').replaceAll(RegExp(r'[#*\[\]\(\)]'), ''),
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

  Color _tagColor(String adType) {
    if (adType == 'OFFER' || adType == 'DISCOUNT') return Colors.green;
    if (adType == 'ALERT' || adType == 'WARNING') return Colors.orange;
    if (adType == 'NEW') return Colors.blue;
    return AppColors.primary;
  }

  String _adTypeLabel(String adType) {
    switch (adType) {
      case 'CARD': return 'منتج';
      case 'FULL': return 'إعلان';
      case 'OFFER': return 'عرض';
      case 'DISCOUNT': return 'خصم';
      case 'ALERT': return 'تنبيه';
      case 'NEW': return 'جديد';
      default: return adType;
    }
  }

  String _formatDate(String raw) {
    try {
      // Handle dd-MM-yyyy format
      if (raw.contains('-') && raw.length == 10) {
        final parts = raw.split('-');
        if (parts.length == 3 && parts[0].length == 2) {
          return '${parts[0]}/${parts[1]}/${parts[2]}';
        }
      }
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}
