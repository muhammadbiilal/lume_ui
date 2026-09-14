/// A calendar day written `yyyy-mm-dd` — what `<input type="date">` holds and
/// what a tool keeps in its session.
library;

/// The day [iso] names, at local midnight, or `null` for anything that is not
/// a real day ("2026-02-30" included).
DateTime? lumeParseIsoDay(String iso) {
  final RegExpMatch? m = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})$',
  ).firstMatch(iso.trim());
  if (m == null) return null;
  final int y = int.parse(m.group(1)!);
  final int mo = int.parse(m.group(2)!);
  final int d = int.parse(m.group(3)!);
  final DateTime day = DateTime(y, mo, d);
  return day.year == y && day.month == mo && day.day == d ? day : null;
}

/// [d] as `yyyy-mm-dd`.
String lumeIsoDate(DateTime d) {
  String two(int v) => v < 10 ? '0$v' : '$v';
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
}
