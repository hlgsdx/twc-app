class ContextSnippet {
  const ContextSnippet({
    required this.sentenceId,
    required this.text,
    required this.isTarget,
    this.rawHtml,
  });

  final String sentenceId;
  final String text;
  final bool isTarget;
  final String? rawHtml;
}
