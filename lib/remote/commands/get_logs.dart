import 'dart:io';
import 'dart:math';

Future<String> getLogPage(String? pageString, File file) async {
  final log = await file.readAsLines();
  final logEntries = log.reversed.toList();

  final page = _parsePage(pageString);
  if (page == null) return "Invalid page";

  final range = PaginationRange.calculate(page: page, pageSize: 10, totalItems: logEntries.length);
  if (!range.isValid) return "Invalid page";

  final selectedLogs = logEntries.sublist(range.safeStart, range.safeEnd).reversed.join("\n");
  return 'Logs: ${range.safeStart}-${range.safeEnd} of ${logEntries.length}\n$selectedLogs';
}

class PaginationRange {
  static const defaultPageSize = 10;

  final int start;
  final int end;
  final int totalItems;

  const PaginationRange({
    required this.start,
    required this.end,
    required this.totalItems,
  });

  bool get isValid => start < totalItems && start >= 0 && end >= 0;
  int get safeStart => min(start, totalItems);
  int get safeEnd => min(end, totalItems);

  factory PaginationRange.calculate({required int page, int pageSize = defaultPageSize, required int totalItems}) {
    if (page < 0) {
      page = max(0, (page * -1) - 1);
      final end = totalItems - (page * pageSize);
      final start = max(0, end - pageSize);
      return PaginationRange(start: start, end: end, totalItems: totalItems);
    }

    final start = page * pageSize;
    return PaginationRange(start: start, end: start + pageSize, totalItems: totalItems);
  }
}

int? _parsePage(String? data) {
  if (data?.isEmpty ?? true) return 0;
  return int.tryParse(data!);
}
