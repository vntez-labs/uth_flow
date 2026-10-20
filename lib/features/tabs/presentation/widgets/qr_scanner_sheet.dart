import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class QrScannerSheet extends StatefulWidget {
  const QrScannerSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QrScannerSheet(),
    );
  }

  /// Xử lý nút Quét QR:
  /// - Kiểm tra xem có app UTH chính thức trên máy không, nếu có thì mở luôn.
  /// - Nếu không có, thông báo: "Tính năng này đang được phát triển, vui lòng dùng app UTH bạn nhé!"
  static Future<void> handleQrAction(BuildContext context) async {
    // 1. Danh sách các URI để thử mở trực tiếp app UTH đã cài trên máy
    final installedAppUris = [
      Uri.parse('android-app://vn.edu.ut.uth'),
      Uri.parse('uth://'),
      Uri.parse('android-app://com.uth.app'),
    ];

    for (final uri in installedAppUris) {
      try {
        if (await canLaunchUrl(uri)) {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
          if (launched) return;
        }
      } catch (_) {}
    }

    if (!context.mounted) return;

    // 2. Nếu không tìm thấy app UTH trên máy, hiển thị thông báo
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF008689).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                SolarIconsBold.scanner_2,
                color: Color(0xFF008689),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Quét mã QR',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Tính năng này đang được phát triển, vui lòng dùng app UTH bạn nhé!',
          style: GoogleFonts.beVietnamPro(fontSize: 14, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Đóng',
              style: GoogleFonts.beVietnamPro(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              launchUthOfficialApp(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008689),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Tải app UTH',
              style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Mở ứng dụng UTH chính thức trên Google Play (Android) hoặc App Store (iOS)
  static Future<void> launchUthOfficialApp(BuildContext context) async {
    final playStoreUri =
        Uri.parse('https://play.google.com/store/apps/details?id=vn.edu.ut.uth');
    final marketUri = Uri.parse('market://details?id=vn.edu.ut.uth');
    final fallbackPlayStore =
        Uri.parse('https://play.google.com/store/apps/details?id=com.uth.app');
    final iosAppStoreUri =
        Uri.parse('https://apps.apple.com/vn/app/uth/id1659204010');
    final webPortalUri = Uri.parse('https://sv.ut.edu.vn');

    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    if (isIOS) {
      try {
        final launched = await launchUrl(
          iosAppStoreUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      } catch (_) {}
    } else {
      // 1. Thử gọi trực tiếp app hoặc market://
      try {
        final launched = await launchUrl(
          marketUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      } catch (_) {}

      // 2. Thử Google Play Store
      try {
        final launched = await launchUrl(
          playStoreUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      } catch (_) {}

      try {
        final launched = await launchUrl(
          fallbackPlayStore,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      } catch (_) {}
    }

    // 3. Fallback Cổng sinh viên UTH
    try {
      final launched = await launchUrl(
        webPortalUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    } catch (_) {}

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Vui lòng truy cập Cổng sinh viên UTH tại: https://sv.ut.edu.vn'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Mở Cổng sinh viên UTH trực tuyến
  static Future<void> launchUthPortal(BuildContext context) async {
    final uri = Uri.parse('https://sv.ut.edu.vn');
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    } catch (_) {}

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể kết nối đến https://sv.ut.edu.vn'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  State<QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<QrScannerSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showManualInputDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _ManualInputDialog(
        onConfirm: (code) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã ghi nhận mã điểm danh: $code'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF008689),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boxSize = (size.shortestSide * 0.44).clamp(140.0, 180.0);

    return Container(
      constraints: BoxConstraints(
        maxHeight: size.height * 0.94,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0C1719),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              // Drag handle
              Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quét mã QR UTH',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Khung kính ngắm QR nghệ thuật với hiệu ứng Laser
              Center(
                child: Container(
                  width: boxSize,
                  height: boxSize,
                  decoration: BoxDecoration(
                    color: _isTorchOn
                        ? const Color(0xFF1E383C)
                        : const Color(0xFF10191B),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFF00A2A6).withValues(alpha: 0.8),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isTorchOn
                            ? const Color(0xFF00FFC2).withValues(alpha: 0.45)
                            : const Color(0xFF008689).withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Biểu tượng UTH & QR Scanner ở trung tâm
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF008689)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    'assets/images/uth_card_logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => const Icon(
                                      SolarIconsBold.scanner_2,
                                      color: Color(0xFF008689),
                                      size: 26,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Xác thực qua App UTH',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Bảo mật điểm danh chính thức',
                                style: GoogleFonts.beVietnamPro(
                                  color: Colors.white60,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Các góc nhọn định vị QR
                        ..._buildCornerMarkers(),

                        // Tia quét laser chạy lên xuống
                        AnimatedBuilder(
                          animation: _animController,
                          builder: (context, _) {
                            return Positioned(
                              top: (boxSize - 4) * _animController.value,
                              left: 12,
                              right: 12,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Color(0xFF00FFC2),
                                      Colors.white,
                                      Color(0xFF00FFC2),
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00FFC2)
                                          .withValues(alpha: 0.8),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Cụm điều khiển: Đèn pin & Nhập mã thủ công
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Nút bật/tắt đèn flash
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isTorchOn = !_isTorchOn;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: _isTorchOn
                              ? const Color(0xFF008689)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isTorchOn
                                  ? SolarIconsBold.flashlightOn
                                  : SolarIconsOutline.flashlight,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isTorchOn ? 'Tắt đèn' : 'Bật đèn',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Nút nhập mã thủ công
                    GestureDetector(
                      onTap: _showManualInputDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              SolarIconsOutline.pen,
                              size: 17,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Nhập mã',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Thông báo hướng dẫn mở App UTH
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF142427),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF00A2A6).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        SolarIconsBold.infoCircle,
                        color: Color(0xFF00FFC2),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Mã QR điểm danh được mã hóa độc quyền bởi UTH. Vui lòng sử dụng app UTH chính thức để quét.',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11.5,
                            height: 1.35,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Cụm Nút mở Ứng dụng UTH & Cổng sinh viên
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Nút mở App UTH chính thức
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          QrScannerSheet.launchUthOfficialApp(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF008689),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(SolarIconsBold.smartphone, size: 19),
                            const SizedBox(width: 8),
                            Text(
                              'Mở ứng dụng UTH chính thức',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Nút mở Cổng sinh viên sv.ut.edu.vn
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          QrScannerSheet.launchUthPortal(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(SolarIconsOutline.global, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Mở Cổng sinh viên (sv.ut.edu.vn)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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

  List<Widget> _buildCornerMarkers() {
    const size = 22.0;
    const thickness = 3.5;
    const color = Color(0xFF00FFC2);

    return [
      // Top Left
      Positioned(
        top: 10,
        left: 10,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
      // Top Right
      Positioned(
        top: 10,
        right: 10,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
      // Bottom Left
      Positioned(
        bottom: 10,
        left: 10,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
      // Bottom Right
      Positioned(
        bottom: 10,
        right: 10,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
    ];
  }
}

class _ManualInputDialog extends StatefulWidget {
  final ValueChanged<String> onConfirm;

  const _ManualInputDialog({required this.onConfirm});

  @override
  State<_ManualInputDialog> createState() => _ManualInputDialogState();
}

class _ManualInputDialogState extends State<_ManualInputDialog> {
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Nhập mã điểm danh thủ công',
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nhập mã ca học hoặc mã điểm danh do giảng viên cung cấp trên lớp:',
            style: GoogleFonts.beVietnamPro(fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            style: GoogleFonts.jetBrainsMono(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              hintText: 'VD: UTH-8829',
              hintStyle: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                letterSpacing: 0,
                color: Colors.black26,
              ),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Hủy',
            style: GoogleFonts.beVietnamPro(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final code = _codeController.text.trim();
            Navigator.of(context).pop();
            if (code.isNotEmpty) {
              widget.onConfirm(code);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF008689),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            'Xác nhận',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}



