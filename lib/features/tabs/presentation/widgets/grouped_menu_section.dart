import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:uth_flow/features/tabs/domain/portal_menu_model.dart';
import 'package:uth_flow/features/tabs/domain/portal_menu_utils.dart';

class GroupedMenuSection extends StatelessWidget {
  final List<PortalMenuItem> groups;
  final String searchQuery;
  final bool isDark;

  const GroupedMenuSection({
    super.key,
    required this.groups,
    required this.searchQuery,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final query = searchQuery.trim().toLowerCase();
    final filteredGroups = <PortalMenuItem>[];

    for (final group in groups) {
      final children = group.children;
      if (children.isEmpty &&
          (group.route == null || group.route!.trim().isEmpty)) {
        continue;
      }

      if (query.isEmpty) {
        filteredGroups.add(group);
      } else {
        final groupNameMatches = group.name.toLowerCase().contains(query);
        final matchedChildren = children.where((child) {
          final nameMatch = child.name.toLowerCase().contains(query);
          final routeMatch =
              child.route?.toLowerCase().contains(query) ?? false;
          return nameMatch || routeMatch;
        }).toList();

        if (groupNameMatches) {
          filteredGroups.add(group);
        } else if (matchedChildren.isNotEmpty) {
          filteredGroups.add(
            PortalMenuItem(
              id: group.id,
              name: group.name,
              route: group.route,
              icon: group.icon,
              color: group.color,
              children: matchedChildren,
            ),
          );
        }
      }
    }

    filteredGroups.sort((a, b) {
      int score(String name) {
        final lower = name.toLowerCase();
        if (lower.contains('học tập') || lower.contains('đào tạo')) return 1;
        if (lower.contains('công nợ') || lower.contains('học phí')) return 2;
        if (lower.contains('hỗ trợ') || lower.contains('dịch vụ')) return 3;
        if (lower.contains('thông tin')) return 4;
        return 5;
      }

      return score(a.name).compareTo(score(b.name));
    });

    if (filteredGroups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: Column(
            children: [
              Icon(
                SolarIconsOutline.sadSquare,
                size: 48,
                color: isDark ? Colors.white30 : Colors.black26,
              ),
              const SizedBox(height: 12),
              Text(
                'Không tìm thấy tiện ích phù hợp',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              SolarIconsOutline.widget_2,
              size: 18,
              color: Color(0xFF008689),
            ),
            const SizedBox(width: 8),
            Text(
              query.isEmpty
                  ? 'Tất cả dịch vụ UTH'
                  : 'Kết quả tìm kiếm (${filteredGroups.fold<int>(0, (prev, g) => prev + (g.children.isEmpty ? 1 : g.children.length))})',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF191919),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...filteredGroups.map((group) {
          return _buildCategoryGroup(context, group);
        }),
      ],
    );
  }

  Widget _buildCategoryGroup(BuildContext context, PortalMenuItem group) {
    final categoryColor = PortalMenuUtils.getCategoryColor(group.name);
    final categoryIcon = PortalMenuUtils.getCategoryIcon(group.name);
    final children = group.children;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282724) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    categoryIcon,
                    size: 18,
                    color: categoryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    group.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF191919),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${children.length} mục',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
          ),
          if (children.isEmpty)
            Material(
              color: Colors.transparent,
              child: ListTile(
                onTap: () =>
                    PortalMenuUtils.openRoute(context, group.route, group.name),
                leading: Icon(
                  PortalMenuUtils.getItemIcon(group.name),
                  size: 20,
                  color: categoryColor,
                ),
                title: Text(
                  group.name,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(
                  SolarIconsOutline.altArrowRight,
                  size: 16,
                  color: Colors.black26,
                ),
              ),
            )
          else
            Column(
              children: [
                for (int idx = 0; idx < children.length; idx++) ...[
                  if (idx > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 52,
                      endIndent: 16,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                    ),
                  _buildCategoryChildTile(
                    context,
                    children[idx],
                    isLast: idx == children.length - 1,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChildTile(
    BuildContext context,
    PortalMenuItem child, {
    required bool isLast,
  }) {
    final icon = PortalMenuUtils.getItemIcon(child.name);
    final isExternal = child.route?.startsWith('http') ?? false;

    return InkWell(
      onTap: () =>
          PortalMenuUtils.openRoute(context, child.route, child.name),
      borderRadius: isLast
          ? const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            )
          : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF5F4F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 17,
                color: isDark ? Colors.white70 : const Color(0xFF4A4844),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF191919),
                    ),
                  ),
                  if (child.route != null && child.route!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      child.route!.replaceFirst('https://', ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isExternal
                  ? SolarIconsOutline.arrowRightUp
                  : SolarIconsOutline.altArrowRight,
              size: 16,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}
