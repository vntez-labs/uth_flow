class PortalMenuItem {
  final int id;
  final String name;
  final String? route;
  final String? icon;
  final String? color;
  final List<PortalMenuItem> children;

  const PortalMenuItem({
    required this.id,
    required this.name,
    this.route,
    this.icon,
    this.color,
    this.children = const [],
  });

  factory PortalMenuItem.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'];
    List<PortalMenuItem> parsedChildren = [];
    if (rawChildren is List) {
      parsedChildren = rawChildren
          .map((c) => PortalMenuItem.fromJson(Map<String, dynamic>.from(c as Map)))
          .toList();
    }

    return PortalMenuItem(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      route: json['route'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      children: parsedChildren,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'route': route,
        'icon': icon,
        'color': color,
        'children': children.map((c) => c.toJson()).toList(),
      };
}
