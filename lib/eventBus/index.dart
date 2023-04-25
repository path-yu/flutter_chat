import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:event_bus/event_bus.dart';

EventBus eventBus = EventBus();

class UserChangeEvent {
  Map<String, dynamic> user;

  UserChangeEvent(this.user);
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
  RtcConnection connection;
  int elapsed;
  OnJoinChannelSuccessEvent(this.connection, this.elapsed);
}

class OnUserOfflineEvent {
  RtcConnection connection;
  int remoteUid;
  UserOfflineReasonType reason;
  OnUserOfflineEvent(this.connection, this.remoteUid, this.reason);
}
