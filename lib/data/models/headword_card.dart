class HeadwordCard {
  const HeadwordCard({
    required this.id,
    required this.headwordId,
    required this.headword,
    required this.yomiDisplay,
    required this.romajiDisplay,
    required this.freq,
    required this.basicword,
    required this.checked,
    this.sortkey,
    this.yomi1,
    this.yomi2,
    this.yomi3,
    this.romaji1,
    this.romaji2,
    this.romaji3,
  });

  final int id;
  final String headwordId;
  final String headword;
  final String yomiDisplay;
  final String romajiDisplay;
  final int freq;
  final bool basicword;
  final bool checked;
  final String? sortkey;
  final String? yomi1;
  final String? yomi2;
  final String? yomi3;
  final String? romaji1;
  final String? romaji2;
  final String? romaji3;

  factory HeadwordCard.fromJson(Map<String, Object?> json) {
    return HeadwordCard(
      id: (json['id'] as num).toInt(),
      headwordId: json['headword_id'] as String? ?? '',
      headword: json['headword'] as String? ?? '',
      yomiDisplay: json['yomi_display'] as String? ?? '',
      romajiDisplay: json['romaji_display'] as String? ?? '',
      freq: (json['freq'] as num?)?.toInt() ?? 0,
      basicword: json['basicword'] as bool? ?? false,
      checked: json['checked'] as bool? ?? false,
      sortkey: json['sortkey'] as String?,
      yomi1: json['yomi1'] as String?,
      yomi2: json['yomi2'] as String?,
      yomi3: json['yomi3'] as String?,
      romaji1: json['romaji1'] as String?,
      romaji2: json['romaji2'] as String?,
      romaji3: json['romaji3'] as String?,
    );
  }
}
