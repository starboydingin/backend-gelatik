class PaginatedResult<T> {
  final List<T> items;
  final int total;
  final int currentPage;
  final int lastPage;

  const PaginatedResult({
    required this.items,
    required this.total,
    required this.currentPage,
    required this.lastPage,
  });
}
