class JqGridResponse<T> {
  const JqGridResponse({
    required this.page,
    required this.total,
    required this.rows,
    this.records,
  });

  final int page;
  final int total;
  final int? records;
  final List<T> rows;
}
