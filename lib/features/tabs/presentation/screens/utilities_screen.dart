import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:uth_flow/features/tabs/domain/portal_menu_utils.dart';
import 'package:uth_flow/features/tabs/presentation/controllers/portal_menu_controller.dart';
import 'package:uth_flow/features/tabs/presentation/widgets/grouped_menu_section.dart';
import 'package:uth_flow/features/tabs/presentation/widgets/quick_shortcuts_section.dart';

class UtilitiesScreen extends ConsumerStatefulWidget {
  const UtilitiesScreen({super.key});

  @override
  ConsumerState<UtilitiesScreen> createState() => _UtilitiesScreenState();
}

class _UtilitiesScreenState extends ConsumerState<UtilitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sideMenuAsync = ref.watch(portalSideMenuProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Tiện ích',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(portalSideMenuProvider);
          ref.invalidate(portalMainMenuProvider);
          await ref.read(portalSideMenuProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. THANH TÌM KIẾM DỊCH VỤ NHANH
              _buildSearchBar(isDark),

              const SizedBox(height: 20),

              // 2. KHỐI LỐI TẮT PHỔ BIẾN (Ẩn khi đang gõ tìm kiếm)
              if (_searchQuery.isEmpty) ...[
                const QuickShortcutsSection(),
                const SizedBox(height: 24),
              ],

              // 3. DANH SÁCH TIỆN ÍCH THEO NHÓM
              sideMenuAsync.when(
                data: (menuItems) {
                  final activeItems = menuItems.isNotEmpty
                      ? menuItems
                      : PortalMenuUtils.getFallbackSideMenu();
                  return GroupedMenuSection(
                    groups: activeItems,
                    searchQuery: _searchQuery,
                    isDark: isDark,
                  );
                },
                loading: () => GroupedMenuSection(
                  groups: PortalMenuUtils.getFallbackSideMenu(),
                  searchQuery: _searchQuery,
                  isDark: isDark,
                ),
                error: (err, stack) => GroupedMenuSection(
                  groups: PortalMenuUtils.getFallbackSideMenu(),
                  searchQuery: _searchQuery,
                  isDark: isDark,
                ),
              ),

              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282724) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim();
          });
        },
        style: GoogleFonts.beVietnamPro(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm tiện ích, dịch vụ, trang portal...',
          hintStyle: GoogleFonts.beVietnamPro(
            fontSize: 13.5,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          prefixIcon: const Icon(
            SolarIconsOutline.magnifier,
            size: 20,
            color: Color(0xFF008689),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
