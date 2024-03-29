# flutter_chat

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## screenshot

![newFriends.png](https://github.com/path-yu/flutter_chat/blob/main/img/chatGPT.png)

![addContact.png](https://github.com/path-yu/flutter_chat/blob/main/img/addContact.png)

![chat.png](https://github.com/path-yu/flutter_chat/blob/main/img/chat.png)

![contacts.png](https://github.com/path-yu/flutter_chat/blob/main/img/contacts.png)

![edit_user.png](https://github.com/path-yu/flutter_chat/blob/main/img/edit_user.png)

![login.png](https://github.com/path-yu/flutter_chat/blob/main/img/login.png)

![newFriends.png](https://github.com/path-yu/flutter_chat/blob/main/img/newFriends.png)

## run for web

```shell
flutter run -d chrome --web-renderer html
```

## build apk

```shell
flutter build apk --obfuscate --split-debug-info=splitMap --target-platform android-arm,android-arm64,android-x64 --split-per-abi
```

## build web

```shell
flutter build web --output=web_build
```

## test DeepLink

```shell
./adb shell am start -a android.intent.action.VIEW \
    -c android.intent.category.BROWSABLE \
    -d "http://flutterbooksample.com/book/1" \
    com.example.flutter_chat
./adb shell am start -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d "http://flutterbooksample.com/book/1" com.example.flutter_chat
```
