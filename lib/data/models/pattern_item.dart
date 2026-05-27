class PatternItem {
  const PatternItem({
    required this.id,
    required this.name,
    required this.freq,
    required this.percentage,
  });

  final String id;
  final String name;
  final int freq;
  final num percentage;

  factory PatternItem.fromJson(Map<String, Object?> json) {
    return PatternItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      freq: (json['freq'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?) ?? 0,
    );
  }
}
