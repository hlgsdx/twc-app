String normalizeWhitespace(String input) {
  return input.replaceAll('\r', '').replaceAll(RegExp(r'\s+\n'), '\n').trim();
}

String buildContextId(String fileId, int sentenceNo) => '$fileId.$sentenceNo';

int? parseSentenceNumber(String sentenceId) {
  final match = RegExp(r'^S(\d+)$').firstMatch(sentenceId);
  if (match == null) {
    return null;
  }
  return int.tryParse(match.group(1)!);
}
