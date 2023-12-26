import 'dart:typed_data';

import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/main.dart';
import 'package:flutter_chat/pages/chat/voice_calling_chat_page.dart';

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
    return formatDate(date, [dd, '-', mm, '-', yyyy]);
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
    return '${formatDate(date, [dd, '-', mm, '-', yyyy])} $timeStr';
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
      return 'unknown';
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

String getCallMessageText(bool isMyRequest, int status, int? timestamp) {
  if (status == 4) {
    return isMyRequest ? 'Cancelled, click to redial' : 'User canceled';
  } else if (status == 5) {
    return 'Voice call missed';
  } else if (status == 3) {
    return isMyRequest ? 'you have declined' : 'The other party has declined';
  } else if (status == 2) {
    return 'Call time ${formatDate(DateTime.fromMillisecondsSinceEpoch(timestamp!), [
          hh,
          ':',
          mm,
        ])}';
  } else {
    return '';
  }
}

void toVoiceCallingPage(
    BuildContext context, Map<String, dynamic> callMessageData) {
  Navigator.push(
    context,
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => VoiceCallingChatPage(
        callMessageData: callMessageData,
      ),
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          )),
          child: child,
        );
      },
    ),
  );
}

Future<Uint8List> convertStreamToUint8List(Stream<Uint8List> byteStream) async {
  // 使用toList将所有的Uint8List合并到一个List中
  List<Uint8List> byteList = await byteStream.toList();

  // 计算所有Uint8List的总长度
  int totalLength =
      byteList.fold(0, (int sum, Uint8List list) => sum + list.length);

  // 创建一个Uint8List，其长度为所有字节的总和
  Uint8List result = Uint8List(totalLength);

  // 将每个Uint8List的字节拷贝到结果Uint8List中
  int offset = 0;
  for (Uint8List list in byteList) {
    result.setAll(offset, list);
    offset += list.length;
  }

  return result;
}

bool isUint8ListAllZeros(Uint8List data) {
  // 使用 every 函数检查是否所有元素都是 0
  return data.every((element) => element == 0);
}
