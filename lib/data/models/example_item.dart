import '../../core/utils/text_normalizer.dart';

class ExampleItem {
  const ExampleItem({
    required this.example,
    required this.subcorpus,
    required this.source,
    required this.fileid,
    required this.sentenceid,
    required this.length,
    required this.boldStart,
    required this.boldEnd,
    required this.url,
  });

  final String example;
  final String subcorpus;
  final String source;
  final String fileid;
  final String sentenceid;
  final int length;
  final int boldStart;
  final int boldEnd;
  final String url;

  String get contextId => buildContextId(fileid, sentenceNo);
  int get sentenceNo => parseSentenceNumber(sentenceid) ?? 0;

  factory ExampleItem.fromJson(Map<String, Object?> json) {
    return ExampleItem(
      example: json['example'] as String? ?? '',
      subcorpus: json['subcorpus'] as String? ?? '',
      source: json['source'] as String? ?? '',
      fileid: json['fileid'] as String? ?? '',
      sentenceid: json['sentenceid'] as String? ?? '',
      length: (json['length'] as num?)?.toInt() ?? 0,
      boldStart: (json['bold_start'] as num?)?.toInt() ?? 0,
      boldEnd: (json['bold_end'] as num?)?.toInt() ?? 0,
      url: (json['url'] as String? ?? '').trim(),
    );
  }
}
