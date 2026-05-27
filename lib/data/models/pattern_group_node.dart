class PatternGroupNode {
  const PatternGroupNode({
    required this.id,
    required this.name,
    required this.freq,
    required this.percentage,
    required this.level,
    required this.parent,
    required this.isLeaf,
    required this.expanded,
  });

  final String id;
  final String name;
  final int freq;
  final num percentage;
  final int level;
  final String parent;
  final bool isLeaf;
  final bool expanded;

  factory PatternGroupNode.fromJson(Map<String, Object?> json) {
    return PatternGroupNode(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      freq: (json['freq'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?) ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 0,
      parent: json['parent'] as String? ?? '',
      isLeaf: json['isLeaf'] == true || json['isLeaf'] == 'true',
      expanded: json['expanded'] == true || json['expanded'] == 'true',
    );
  }
}
