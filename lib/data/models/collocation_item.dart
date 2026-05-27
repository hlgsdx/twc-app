class CollocationItem {
  const CollocationItem({
    required this.id,
    required this.headwordCollocationId,
    required this.collocationId,
    required this.collocation,
    required this.freq,
    required this.mi,
    required this.logdice,
  });

  final int id;
  final String headwordCollocationId;
  final String collocationId;
  final String collocation;
  final int freq;
  final num mi;
  final num logdice;

  factory CollocationItem.fromJson(Map<String, Object?> json) {
    return CollocationItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      headwordCollocationId: json['headword_collocation_id'] as String? ?? '',
      collocationId: json['collocation_id'] as String? ?? '',
      collocation: json['collocation'] as String? ?? '',
      freq: (json['freq'] as num?)?.toInt() ?? 0,
      mi: (json['mi'] as num?) ?? 0,
      logdice: (json['logdice'] as num?) ?? 0,
    );
  }
}
