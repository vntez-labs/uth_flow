import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    this.children = const [],
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    const double barHeight = 62.0;
    final activeIndex = navigationShell.currentIndex;
    // Tab 0: -1.0, Tab 1: -0.333, Tab 2: 0.333, Tab 3: 1.0
    final alignmentX = -1.0 + activeIndex * (2.0 / 3.0);

    return Scaffold(
      extendBody: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      // Hiển thị nội dung tab dạng IndexedStack không trượt qua lại
      body: children.isNotEmpty
          ? IndexedStack(
              index: activeIndex,
              children: children,
            )
          : navigationShell,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(bottom: 16),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 350),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: barHeight,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262522) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.35 : 0.08,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // CỤC INDICATOR CAPSULE LƯỚT NHẸ DƯỚI THANH TAB
                  Positioned.fill(
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment(alignmentX, 0.0),
                      child: IgnorePointer(
                        child: FractionallySizedBox(
                          widthFactor: 1 / 4,
                          heightFactor: 1.0,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? primaryColor.withValues(alpha: 0.22)
                                  : primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 4 TAB NẰM TRÊN CÙNG: TỔNG QUAN | LỊCH HỌC | TIỆN ÍCH | HỒ SƠ
                  Row(
                    children: [
                      Expanded(
                        child: _NavBarTabItem(
                          iconOutline: SolarIconsOutline.compass,
                          iconBold: SolarIconsBold.compass,
                          label: 'Tổng quan',
                          isSelected: activeIndex == 0,
                          onTap: () => _onTap(0),
                        ),
                      ),
                      Expanded(
                        child: _NavBarTabItem(
                          iconOutline: SolarIconsOutline.calendar,
                          iconBold: SolarIconsBold.calendar,
                          label: 'Lịch học',
                          isSelected: activeIndex == 1,
                          onTap: () => _onTap(1),
                        ),
                      ),
                      Expanded(
                        child: _NavBarTabItem(
                          iconOutline: SolarIconsOutline.widget_2,
                          iconBold: SolarIconsBold.widget_2,
                          label: 'Tiện ích',
                          isSelected: activeIndex == 2,
                          onTap: () => _onTap(2),
                        ),
                      ),
                      Expanded(
                        child: _NavBarTabItem(
                          iconOutline: SolarIconsOutline.user,
                          iconBold: SolarIconsBold.user,
                          label: 'Hồ sơ',
                          isSelected: activeIndex == 3,
                          onTap: () => _onTap(3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarTabItem extends StatelessWidget {
  final IconData iconOutline;
  final IconData iconBold;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarTabItem({
    required this.iconOutline,
    required this.iconBold,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF6B6864);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? iconBold : iconOutline,
            size: 23,
            color: isSelected ? activeColor : inactiveColor,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? activeColor : inactiveColor,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
