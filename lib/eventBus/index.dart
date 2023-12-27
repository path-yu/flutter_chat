import 'package:event_bus/event_bus.dart';

EventBus eventBus = EventBus();

class UserChangeEvent {
  Map<String, dynamic> user;

  UserChangeEvent(this.user);
}

class UserOnlineChangeEvent {
  List<dynamic> chatIds;
  String type;
  UserOnlineChangeEvent(this.chatIds, this.type);
}

class CloseSocketEvent {}

class TypingEvent {
  bool isTyping;
  TypingEvent(this.isTyping);
}

class ChatsChangeEvent {
  List<dynamic> value;

  ChatsChangeEvent(this.value);
}

class CallMessageChangeEvent {
  Map<String, dynamic> data;

  CallMessageChangeEvent(this.data);
}

class OnJoinChannelSuccessEvent {
  int elapsed;
  OnJoinChannelSuccessEvent(this.elapsed);
}

class OnUserOfflineEvent {
  int remoteUid;
  OnUserOfflineEvent(this.remoteUid);
}
