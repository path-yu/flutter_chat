String formatDate(int timestamp) {
  DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  Duration difference = date.difference(DateTime.now());
  int days = difference.inDays;
  if (date.year == DateTime.now().year) {
    if (days == 0) {
      return 'today ${date.hour}:${date.minute}';
    } else if (days == 1) {
      return 'yesterday';
    } else if (days < 7) {
      int weekDay = date.weekday;
      return getWeekday(weekDay);
    } else {
      return '${date.month}-${date.day}';
    }
  } else {
    return '${date.year}${date.month}-${date.day}';
  }
}

String formatMessageDate(int timestamp) {
  DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  Duration difference = date.difference(DateTime.now());
  int days = difference.inDays;
  var timeStr = '${date.hour}:${date.minute}:${date.second}';
  if (days == 0) {
    return 'today $timeStr';
  } else {
    return '${date.year}/${date.month}/${date.day} $timeStr';
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
