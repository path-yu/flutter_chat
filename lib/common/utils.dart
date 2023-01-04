import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/main.dart';

String formatChatDate(int timestamp) {
  DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  var timeStr =
      TimeOfDay.fromDateTime(date).format(navigatorKey.currentState!.context);
  if (date.year == DateTime.now().year) {
    if (isToday(date)) {
      return timeStr;
    } else if (isYesterday(date)) {
      return 'yesterday $timeStr';
    } else {
      return formatDate(date, [mm, '-', dd]);
    }
  } else {
    return formatDate(date, [yyyy, '-', mm, '-', dd]);
  }
}

String formatMessageDate(int timestamp) {
  DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  var timeStr =
      TimeOfDay.fromDateTime(date).format(navigatorKey.currentState!.context);
  if (isToday(date)) {
    return timeStr;
  } else if (isYesterday(date)) {
    return 'yesterday $timeStr';
  } else {
    return '${formatDate(date, [yyyy, '-', mm, '-', dd])} $timeStr';
  }
}

bool isToday(DateTime date) {
  final DateTime localDate = date.toLocal();
  final now = DateTime.now();
  final diff = now.difference(localDate).inDays;
  return diff == 0 && now.day == localDate.day;
}

bool isYesterday(DateTime date) {
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  return yesterday.day == date.day &&
      yesterday.month == date.month &&
      yesterday.year == date.year;
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

List<List<dynamic>>? sliceArr(List arr, {size = 10}) {
  List<List<dynamic>> result = [];
  var startIndex = 0;
  var length = arr.length;
  while (true) {
    var diff = length - startIndex;
    num end;
    if (diff > size) {
      end = startIndex + size;
    } else {
      end = startIndex + diff;
    }
    startIndex = end.toInt();
    result.add(arr.sublist(startIndex, end.toInt()));
    if (startIndex == length) {
      return result;
    }
  }
}
