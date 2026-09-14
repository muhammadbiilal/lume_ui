/// The numbers a calculator's fields hold, as the reference reads and writes
/// them — Tax, Tip & Split, Loan / EMI, Compound Interest and Date Calculator
/// all keep their inputs this way.
library;

/// `String(n)` — no trailing `.0` on a whole number, every digit of one that
/// is not.
String lumeJsNumber(double v) => v == v.truncateToDouble() && v.abs() < 1e15
    ? v.toInt().toString()
    : v.toString();

/// `Number(text)` — an empty or unreadable field is zero.
double lumeFieldNumber(String text) => double.tryParse(text.trim()) ?? 0;
