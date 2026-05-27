import '../../core/network/api_exception.dart';
import 'pattern_group_node.dart';
import 'pattern_item.dart';

class HeadwordDetail {
  const HeadwordDetail({
    required this.headword,
    required this.freq,
    required this.katuyonoshurui,
    required this.yomi,
    required this.pos2,
  });

  final String headword;
  final int freq;
  final String katuyonoshurui;
  final String yomi;
  final String? pos2;

  factory HeadwordDetail.fromJson(Map<String, Object?> json) {
    return HeadwordDetail(
      headword: json['headword'] as String? ?? '',
      freq: (json['freq'] as num?)?.toInt() ?? 0,
      katuyonoshurui: json['katuyonoshurui'] as String? ?? '',
      yomi: json['yomi'] as String? ?? '',
      pos2: json['pos2'] as String?,
    );
  }
}

class ShojikeiItem {
  const ShojikeiItem({
    required this.name,
    required this.freq,
    required this.percentage,
  });

  final String name;
  final int freq;
  final num percentage;

  factory ShojikeiItem.fromJson(Map<String, Object?> json) {
    return ShojikeiItem(
      name: json['name'] as String? ?? '',
      freq: (json['freq'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?) ?? 0,
    );
  }
}

class HeadwordShojikeiView {
  const HeadwordShojikeiView({
    required this.headword,
    required this.shojikei,
  });

  final String headword;
  final List<ShojikeiItem> shojikei;

  factory HeadwordShojikeiView.fromJson(Map<String, Object?> json) {
    final itemsJson = (json['shojikei'] as List<dynamic>? ?? const []);
    return HeadwordShojikeiView(
      headword: json['headword'] as String? ?? '',
      shojikei: itemsJson
          .whereType<Map>()
          .map((entry) => ShojikeiItem.fromJson(entry.cast<String, Object?>()))
          .toList(growable: false),
    );
  }
}

class KatuyokeiItem {
  const KatuyokeiItem({
    required this.name,
    required this.freq,
    required this.percentage,
  });

  final String name;
  final int freq;
  final num percentage;

  factory KatuyokeiItem.fromJson(Map<String, Object?> json) {
    return KatuyokeiItem(
      name: json['name'] as String? ?? '',
      freq: (json['freq'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?) ?? 0,
    );
  }
}

class HeadwordKatuyokeiView {
  const HeadwordKatuyokeiView({
    required this.headword,
    required this.katuyokei,
  });

  final String headword;
  final List<KatuyokeiItem> katuyokei;

  factory HeadwordKatuyokeiView.fromJson(Map<String, Object?> json) {
    final itemsJson = (json['katuyokei'] as List<dynamic>? ?? const []);
    return HeadwordKatuyokeiView(
      headword: json['headword'] as String? ?? '',
      katuyokei: itemsJson
          .whereType<Map>()
          .map(
            (entry) => KatuyokeiItem.fromJson(entry.cast<String, Object?>()),
          )
          .toList(growable: false),
    );
  }
}

class JodoshisetuzokuDoshiItem {
  const JodoshisetuzokuDoshiItem({
    required this.name,
    required this.freq,
    required this.doshiJodoshiPercentage,
  });

  final String name;
  final int freq;
  final num doshiJodoshiPercentage;

  factory JodoshisetuzokuDoshiItem.fromJson(Map<String, Object?> json) {
    return JodoshisetuzokuDoshiItem(
      name: json['name'] as String? ?? '',
      freq: (json['freq'] as num?)?.toInt() ?? 0,
      doshiJodoshiPercentage:
          (json['doshi_jodoshi_percentage'] as num?) ?? 0,
    );
  }
}

class JodoshisetuzokuItem {
  const JodoshisetuzokuItem({
    required this.name,
    required this.jodoshiFreq,
    required this.jodoshiPercentage,
    required this.doshiJodoshi,
  });

  final String name;
  final int jodoshiFreq;
  final String jodoshiPercentage;
  final List<JodoshisetuzokuDoshiItem> doshiJodoshi;

  factory JodoshisetuzokuItem.fromJson(Map<String, Object?> json) {
    final doshiJson = (json['doshi_jodoshi'] as List<dynamic>? ?? const []);
    return JodoshisetuzokuItem(
      name: json['name'] as String? ?? '',
      jodoshiFreq: (json['jodoshi_freq'] as num?)?.toInt() ?? 0,
      jodoshiPercentage: json['jodoshi_percentage'] as String? ?? '',
      doshiJodoshi: doshiJson
          .whereType<Map>()
          .map(
            (entry) =>
                JodoshisetuzokuDoshiItem.fromJson(entry.cast<String, Object?>()),
          )
          .toList(growable: false),
    );
  }
}

class HeadwordJodoshisetuzokuView {
  const HeadwordJodoshisetuzokuView({
    required this.headword,
    required this.setuzoku,
  });

  final String headword;
  final List<JodoshisetuzokuItem> setuzoku;

  factory HeadwordJodoshisetuzokuView.fromJson(Map<String, Object?> json) {
    final itemsJson = (json['setuzoku'] as List<dynamic>? ?? const []);
    return HeadwordJodoshisetuzokuView(
      headword: json['headword'] as String? ?? '',
      setuzoku: itemsJson
          .whereType<Map>()
          .map(
            (entry) =>
                JodoshisetuzokuItem.fromJson(entry.cast<String, Object?>()),
          )
          .toList(growable: false),
    );
  }
}

class HeadwordDetailViews {
  const HeadwordDetailViews({
    this.shojikei,
    this.katuyokei,
    this.jodoshisetuzoku,
  });

  final HeadwordShojikeiView? shojikei;
  final HeadwordKatuyokeiView? katuyokei;
  final HeadwordJodoshisetuzokuView? jodoshisetuzoku;
}

class HeadwordDetailBundle {
  const HeadwordDetailBundle({
    required this.headwordId,
    this.basicInfo,
    this.basicInfoViews = const HeadwordDetailViews(),
    this.patternFrequency = const <PatternItem>[],
    this.patternGroups = const <String, List<PatternGroupNode>>{},
    this.issues = const <ApiException>[],
  });

  final String headwordId;
  final HeadwordDetail? basicInfo;
  final HeadwordDetailViews basicInfoViews;
  final List<PatternItem> patternFrequency;
  final Map<String, List<PatternGroupNode>> patternGroups;
  final List<ApiException> issues;
}
