import 'package:event_bus/event_bus.dart';

EventBus eventBus = EventBus();

class UserChangeEvent {
  Map<String, dynamic> user;

  UserChangeEvent(this.user);
}
