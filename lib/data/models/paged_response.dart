class PagedResponse<T> {
  const PagedResponse({
    required this.page,
    required this.total,
    required this.items,
    this.records,
  });

  final int page;
  final int total;
  final int? records;
  final List<T> items;
}
