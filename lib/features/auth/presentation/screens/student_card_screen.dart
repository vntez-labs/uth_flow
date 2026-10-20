import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uth_flow/features/auth/domain/models/user_model.dart';
import 'package:uth_flow/features/auth/presentation/controllers/auth_controller.dart';
import 'package:uth_flow/features/auth/presentation/widgets/barcode_widget.dart';

class StudentCardScreen extends ConsumerWidget {
  const StudentCardScreen({super.key});

  Future<void> _callHotline(BuildContext context) async {
    const phone = '02838992862';
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hotline UTH: (028) 3899 2862'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final mssv = (user?.mssv != null && user!.mssv.isNotEmpty)
        ? user.mssv
        : '074207005137';

    return Scaffold(
      backgroundColor: const Color(0xFF012022),
      body: Column(
        children: [
          // ==================== 1. NỬA TRÊN CỐ ĐỊNH (FIXED TOP - KHÔNG SCROLL) ====================
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF012022),
                  Color(0xFF022B2E),
                  Color(0xFF043336),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Custom AppBar
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(SolarIconsOutline.arrowLeft,
                              color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        Expanded(
                          child: Text(
                            'Thẻ sinh viên điện tử',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Gọi tổng đài UTH',
                          icon: const Icon(SolarIconsBold.phoneCalling,
                              color: Colors.white),
                          onPressed: () => _callHotline(context),
                        ),
                      ],
                    ),
                  ),

                  // Thẻ sinh viên UTH cố định
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
                    child: _buildStudentCard(context, user, mssv),
                  ),
                ],
              ),
            ),
          ),

          // ==================== 2. NỬA DƯỚI ĐỘC LẬP (SCROLLABLE BOTTOM SHEET) ====================
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7F7),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thanh gạt (Drag indicator nhẹ nhàng)
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCAD7D8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Thông tin số hóa
                      Text(
                        'Thông tin số hóa',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0E282A),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mã vạch',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF162527),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Center(
                              child: BarcodeWidget(
                                code: mssv,
                                height: 85,
                                showText: false,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Thông tin thêm
                      Text(
                        'Thông tin thêm',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0E282A),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 30),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5EEED),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Biểu tượng hộp rỗng cách điệu màu mint/teal
                            Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: Color(0xFFCCDEDE),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                SolarIconsOutline.inbox,
                                size: 32,
                                color: Color(0xFF4C7577),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không có thông tin',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF182729),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Bạn chưa có dữ liệu nào, cập nhật hoạt động để hệ thống ghi nhận lịch sử.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12.5,
                                height: 1.45,
                                color: const Color(0xFF6B7E81),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(
    BuildContext context,
    UserModel? user,
    String mssv,
  ) {
    final fullName = (user?.fullName != null && user!.fullName.isNotEmpty)
        ? user.fullName.toUpperCase()
        : 'NGUYỄN HOÀNG NAM';

    final program = (user?.chuyenNganh != null && user!.chuyenNganh!.isNotEmpty)
        ? user.chuyenNganh!.toUpperCase()
        : (user?.nganh != null && user!.nganh!.isNotEmpty)
            ? user.nganh!.toUpperCase()
            : 'CÔNG NGHỆ THÔNG TIN';

    final courseYear =
        (user?.khoaHoc != null && user!.khoaHoc!.isNotEmpty)
            ? user.khoaHoc!
            : '2025';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF274746),
            Color(0xFF203F3E),
            Color(0xFF163231),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD8A538),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD8A538).withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Thẻ: Tên trường + Logo UTH HÌNH VUÔNG (Square)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRƯỜNG ĐẠI HỌC',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'GIAO THÔNG VẬN TẢI TP. HỒ CHÍ MINH',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Logo UTH hình vuông chuẩn (Square Logo Box)
              _buildSquareLogo(),
            ],
          ),

          const SizedBox(height: 14),

          // Body: Ảnh chân dung + Thông tin sinh viên
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh chân dung thẻ sinh viên (Avatar)
              Container(
                width: 82,
                height: 108,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildPortraitPhoto(user),
                ),
              ),

              const SizedBox(width: 14),

              // Thông tin chi tiết sinh viên
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildCardInfoRow('MSSV:', mssv),
                    const SizedBox(height: 3),
                    _buildCardInfoRow(
                      'CHƯƠNG TRÌNH(CHUYÊN NGÀNH):',
                      program,
                    ),
                    const SizedBox(height: 3),
                    _buildCardInfoRow('KHÓA HỌC:', courseYear),
                    const SizedBox(height: 3),
                    _buildCardInfoRow('TRẠNG THÁI:', 'ĐANG HỌC'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Barcode nhỏ góc dưới phải của Thẻ
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: BarcodeWidget(
                code: mssv,
                height: 24,
                showText: false,
                barColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Logo UTH hình vuông chuẩn (Square Logo Box: 52x52)
  Widget _buildSquareLogo() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          'assets/images/uth_card_logo.png',
          width: 52,
          height: 52,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Container(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'UTH',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF008689),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'TP.HCM',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 6.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD63031),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardInfoRow(String label, String value) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.beVietnamPro(
          fontSize: 10.5,
          color: Colors.white.withValues(alpha: 0.9),
          height: 1.25,
        ),
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitPhoto(UserModel? user) {
    final avatarBase64 = user?.avatarBase64;
    if (avatarBase64 != null && avatarBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(avatarBase64);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackPortrait(user),
        );
      } catch (_) {}
    }
    return _buildFallbackPortrait(user);
  }

  Widget _buildFallbackPortrait(UserModel? user) {
    return Container(
      color: const Color(0xFF007578),
      alignment: Alignment.center,
      child: Text(
        user?.initials ?? 'HN',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

