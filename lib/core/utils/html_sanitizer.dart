String stripHtmlTags(String input) {
  return input.replaceAll(RegExp(r'<[^>]*>'), '');
}
