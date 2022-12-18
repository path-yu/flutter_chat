import 'package:date_format/date_format.dart';

String formatChatDate(int timestamp) {
  DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  Duration difference = date.difference(DateTime.now());
  int days = difference.inDays;
  if (date.year == DateTime.now().year) {
    if (days == 0) {
      return 'today ${formatDate(date, [HH, ':', nn])}';
    } else if (days == 1) {
      return 'yesterday';
    } else if (days < 7) {
      int weekDay = date.weekday;
      return getWeekday(weekDay);
    } else {
      return formatDate(date, [mm, ':', dd]);
    }
  } else {
    return formatDate(date, [yyyy, '-', mm, '-', dd]);
  }
}

String formatMessageDate(int timestamp) {
  DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  Duration difference = date.difference(DateTime.now());
  int days = difference.inDays;
  var timeStr = formatDate(date, [HH, ':', nn]);
  if (days == 0) {
    return 'today $timeStr';
  } else {
    return '${formatDate(date, [yyyy, '-', mm, '-', dd])} $timeStr';
  }
}

String getWeekday(int weekDay) {
  switch (weekDay) {
    case 1:
      return 'Monday';
    case 2:
      return 'Tuesday';
    case 3:
      return 'Wednesday';
    case 4:
      return 'Thursday';
    case 5:
      return 'Friday';
    case 6:
      return 'Saturday';
    case 7:
      return 'Sunday';
    default:
      return '未知';
  }
}
