// Small date helpers, so the app does not need the intl package yet.

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "Oct 04, 2026"
String formatDate(DateTime date) => '${formatShortDate(date)}, ${date.year}';

/// "Oct 04"
String formatShortDate(DateTime date) =>
    '${_months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}';

/// "2:30 PM"
String formatTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${date.hour < 12 ? 'AM' : 'PM'}';
}

/// "Jan 2026"
String formatMonthYear(DateTime date) =>
    '${_months[date.month - 1]} ${date.year}';
