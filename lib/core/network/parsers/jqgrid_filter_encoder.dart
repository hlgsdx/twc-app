import 'dart:convert';

class JqGridFilterEncoder {
  const JqGridFilterEncoder();

  String encodeExactHeadword(String keyword) {
    return jsonEncode({
      'groupOp': 'OR',
      'rules': [
        {'field': 'headword', 'op': 'eq', 'data': keyword},
      ],
    });
  }
}
