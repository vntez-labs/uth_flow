import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uth_flow/core/storage/secure_storage_service.dart';
import 'package:uth_flow/features/auth/presentation/controllers/auth_controller.dart';
import 'package:uth_flow/features/moodle/presentation/controllers/moodle_controller.dart';

class SyncMoodlePasswordSheet extends ConsumerStatefulWidget {
  final String initialPassword;
  final String mssv;

  const SyncMoodlePasswordSheet({
    super.key,
    required this.initialPassword,
    required this.mssv,
  });

  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final secureStorage = ref.read(secureStorageProvider);
    final user = ref.read(currentUserProvider);
    final mssv = user?.mssv ?? '';
    final creds = await secureStorage.getCredentials();
    final savedAcc = await secureStorage.getAccount(mssv);

    String initialPassword = creds.password?.trim() ?? '';
    if (initialPassword.isEmpty &&
        savedAcc != null &&
        savedAcc.password.isNotEmpty) {
      initialPassword = savedAcc.password.trim();
    }
    if (initialPassword.isEmpty && user?.ngaySinh != null) {
      final dob = user!.ngaySinh!.replaceAll(RegExp(r'[^0-9]'), '');
      if (dob.length == 8) {
        initialPassword = dob;
      }
    }

    if (!context.mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF282724) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SyncMoodlePasswordSheet(
        initialPassword: initialPassword,
        mssv: mssv,
      ),
    );
  }

  @override
  ConsumerState<SyncMoodlePasswordSheet> createState() =>
      _SyncMoodlePasswordSheetState();
}

class _SyncMoodlePasswordSheetState
    extends ConsumerState<SyncMoodlePasswordSheet> {
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController(text: widget.initialPassword);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final secureStorage = ref.read(secureStorageProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đồng bộ Deadlines Moodle',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF191919),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Nhập mật khẩu Moodle/Portal (Mặc định tài khoản LMS của sinh viên UTH là ngày sinh dạng ddmmyyyy, ví dụ: 01062007).',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: isDark ? Colors.white60 : const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofocus: true,
            style: GoogleFonts.beVietnamPro(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              hintText: 'Nhập mật khẩu Moodle (hoặc ngày sinh ddmmyyyy)',
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final pwd = _passwordController.text.trim();
                if (pwd.isEmpty) return;

                await secureStorage.saveCredentials(
                  username: widget.mssv,
                  password: pwd,
                );
                final currentAcc = await secureStorage.getAccount(widget.mssv);
                if (currentAcc != null) {
                  await secureStorage.saveOrUpdateAccount(
                    currentAcc.copyWith(password: pwd),
                  );
                }

                if (context.mounted) {
                  Navigator.pop(context);
                }
                ref.invalidate(savedAccountsProvider);
                ref.invalidate(moodleDeadlinesProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Lưu & Đồng bộ bài tập',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
