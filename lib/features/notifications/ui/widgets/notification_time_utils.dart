String formatRelativeTime(DateTime createdAt) {
  final now = DateTime.now();
  final created = createdAt.toLocal();
  final difference = now.difference(created);

  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24 &&
      now.day == created.day &&
      now.month == created.month &&
      now.year == created.year) {
    return '${difference.inHours}h ago';
  }

  final dayDiff = DateTime(now.year, now.month, now.day)
      .difference(DateTime(created.year, created.month, created.day))
      .inDays;

  if (dayDiff == 1) return '1d ago';
  if (dayDiff < 7) return '${dayDiff}d ago';
  if (dayDiff < 30) return '${(dayDiff / 7).floor()}w ago';
  return '${(dayDiff / 30).floor()}mo ago';
}
