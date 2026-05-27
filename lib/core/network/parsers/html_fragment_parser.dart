import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;

import '../../../data/models/context_snippet.dart';
import '../../utils/text_normalizer.dart';

class HtmlFragmentParser {
  const HtmlFragmentParser();

  List<ContextSnippet> parseContext(
    String fragment, {
    String? targetSentenceId,
  }) {
    final document = html_parser.parseFragment(fragment);
    final snippets = <ContextSnippet>[];

    for (final node in document.nodes) {
      if (node is html_dom.Element && node.localName == 'span') {
        final sentenceId = node.attributes['id'] ?? '';
        final text = normalizeWhitespace(node.text);
        final html = node.outerHtml;
        snippets.add(
          ContextSnippet(
            sentenceId: sentenceId,
            text: text,
            isTarget:
                targetSentenceId != null && sentenceId == targetSentenceId,
            rawHtml: html,
          ),
        );
      }
    }

    return snippets;
  }
}
