import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:uth_flow/features/auth/domain/models/saved_account_model.dart';
import 'package:uth_flow/features/auth/presentation/controllers/auth_controller.dart';

class AccountSwitcherSheet extends ConsumerStatefulWidget {
  const AccountSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AccountSwitcherSheet(),
    );
  }

  @override
  ConsumerState<AccountSwitcherSheet> createState() =>
      _AccountSwitcherSheetState();
}

class _AccountSwitcherSheetState extends ConsumerState<AccountSwitcherSheet> {
  bool _isAddingAccount = false;
  final _mssvController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _addError;

  @override
  void dispose() {
    _mssvController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAddNewAccount() async {
    final mssv = _mssvController.text.trim();
    final pwd = _passwordController.text.trim();

    if (mssv.isEmpty) {
      setState(() => _addError = 'Vui lòng nhập MSSV hoặc Email');
      return;
    }
    if (pwd.isEmpty) {
      setState(() => _addError = 'Vui lòng nhập mật khẩu');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _addError = null;
    });

    final success = await ref.read(authProvider.notifier).login(mssv, pwd);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã thêm và chuyển sang tài khoản mới 🎉',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF2ED573),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final authState = ref.read(authProvider);
      setState(() {
        _isSubmitting = false;
        _addError = authState.errorMessage ?? 'Đăng nhập không thành công';
      });
    }
  }

  void _confirmDeleteAccount(SavedAccount account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Xóa tài khoản?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa tài khoản "${account.fullName}" (${account.mssv}) khỏi danh sách đã lưu?',
          style: GoogleFonts.beVietnamPro(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Hủy',
              style: GoogleFonts.beVietnamPro(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(authProvider.notifier)
                  .removeAccount(account.mssv);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4757),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Xóa',
              style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final cardBgColor = isDark ? const Color(0xFF282724) : Colors.white;
    final currentUser = ref.watch(currentUserProvider);
    final accountsAsync = ref.watch(savedAccountsProvider);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: bottomInset + (bottomInset > 0 ? 16 : bottomPadding + 16),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar kéo
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        SolarIconsBold.usersGroupRounded,
                        size: 20,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isAddingAccount
                          ? 'Thêm tài khoản mới'
                          : 'Chuyển tài khoản',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF191919),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    if (_isAddingAccount) {
                      setState(() {
                        _isAddingAccount = false;
                        _addError = null;
                      });
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  icon: Icon(
                    _isAddingAccount ? Icons.arrow_back : Icons.close,
                    size: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (_isAddingAccount) ...[
              // ==================== FORM THÊM TÀI KHOẢN MỚI ====================
              Text(
                'Nhập MSSV và mật khẩu tài khoản sinh viên cần thêm. Tài khoản sẽ được lưu an toàn để chuyển đổi nhanh.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12.5,
                  color: isDark ? Colors.white60 : const Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 16),

              if (_addError != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4757).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF4757).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 18,
                        color: Color(0xFFFF4757),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _addError!,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12.5,
                            color: const Color(0xFFFF4757),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              TextField(
                controller: _mssvController,
                autofocus: true,
                style: GoogleFonts.beVietnamPro(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'MSSV hoặc Email',
                  hintText: 'VD: 074207005137',
                  prefixIcon: const Icon(SolarIconsOutline.user, size: 20),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: GoogleFonts.beVietnamPro(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  hintText: 'Nhập mật khẩu Portal/Moodle',
                  prefixIcon: const Icon(SolarIconsOutline.lock, size: 20),
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
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleAddNewAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Đăng nhập & Lưu tài khoản',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                ),
              ),
            ] else ...[
              // ==================== DANH SÁCH TÀI KHOẢN ĐÃ LƯU ====================
              accountsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Không thể tải danh sách tài khoản: $err',
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ),
                data: (accounts) {
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        children: [
                      ...accounts.map((acc) {
                        final isCurrent = currentUser?.mssv == acc.mssv;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? primaryColor.withValues(
                                    alpha: isDark ? 0.15 : 0.08)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.03)
                                    : Colors.black.withValues(alpha: 0.02)),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isCurrent
                                  ? primaryColor.withValues(alpha: 0.4)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.04)),
                              width: isCurrent ? 1.5 : 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: isCurrent
                                ? null
                                : () async {
                                    Navigator.pop(context);
                                    await ref
                                        .read(authProvider.notifier)
                                        .switchAccount(acc);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Đã chuyển sang ${acc.fullName} 🎉',
                                            style: GoogleFonts.beVietnamPro(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          backgroundColor: primaryColor,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Avatar
                                  _buildAvatar(acc, primaryColor),
                                  const SizedBox(width: 14),

                                  // Thông tin
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                acc.fullName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF191919),
                                                ),
                                              ),
                                            ),
                                            if (isCurrent) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: primaryColor,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'Đang dùng',
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'MSSV: ${acc.mssv}',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? Colors.white60
                                                : const Color(0xFF666666),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Nút xóa (nếu không phải tài khoản duy nhất)
                                  IconButton(
                                    icon: const Icon(
                                      SolarIconsOutline.trashBinTrash,
                                      size: 18,
                                      color: Color(0xFFFF4757),
                                    ),
                                    onPressed: () => _confirmDeleteAccount(acc),
                                    tooltip: 'Xóa tài khoản này',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
              ),

              const SizedBox(height: 8),

              // Nút thêm tài khoản khác
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isAddingAccount = true;
                    _mssvController.clear();
                    _passwordController.clear();
                    _addError = null;
                  });
                },
                icon: const Icon(Icons.add, size: 20),
                label: Text(
                  'Thêm tài khoản khác',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(
                    color: primaryColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(SavedAccount account, Color primaryColor) {
    if (account.avatarBase64 != null && account.avatarBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(account.avatarBase64!);
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: MemoryImage(bytes),
              fit: BoxFit.cover,
            ),
          ),
        );
      } catch (_) {}
    }

    final initial = account.fullName.isNotEmpty
        ? account.fullName.trim()[0].toUpperCase()
        : 'U';

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            const Color(0xFF005E60),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
