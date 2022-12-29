import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_chat/common/utils.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/main.dart';

var db = FirebaseFirestore.instance;
const UsersDbKey = 'Users';
const NOTIFICATION = "notification";
const ChatsKey = 'chats';
addContactsNotification(
    String email, String remarks, BuildContext context) async {
  // if not logged in
  if (FirebaseAuth.instance.currentUser == null) return;
  var currentUser = FirebaseAuth.instance.currentUser!;
  var userCollection = db.collection(UsersDbKey);

  if (email == currentUser.email) {
    return showMessage(
        context: navigatorKey.currentState!.context,
        title: 'cannot add itself');
  }
  var data = {
    'userName': currentUser.displayName,
    'email': currentUser.email,
    'targetEmail': email,
    'type': "addContact",
    'status': "pending",
    'uid': currentUser.uid,
    'photoURL': currentUser.photoURL,
    'remarks': remarks,
  };

  // Does the user exist
  final query = await searchUserByEmail(email);
  if (query.docs.isEmpty) {
    return showMessage(
        context: navigatorKey.currentState!.context,
        title: 'User does not exist');
  }
  // Is already a friend
  final queryContact = await userCollection
      .where('email', isEqualTo: currentUser.email)
      .where('contacts', arrayContains: email)
      .get();

  if (queryContact.docs.isNotEmpty) {
    return showMessage(
        context: navigatorKey.currentState!.context,
        title: 'Is already a friend');
  }
  var notificationCollection = db.collection(NOTIFICATION);
  var hasNotificationData = await notificationCollection
      .where('email', isEqualTo: currentUser.email)
      .where('targetEmail', isEqualTo: email)
      .where('status', isEqualTo: 'pending')
      .where('type', isEqualTo: 'addContact')
      .get();
  // Whether it is added
  var hasAddNotificationData = await notificationCollection
      .where('email', isEqualTo: email)
      .where('targetEmail', isEqualTo: currentUser.email)
      .where('status', isEqualTo: 'pending')
      .where('type', isEqualTo: 'addContact')
      .get();
  if (hasAddNotificationData.docs.isNotEmpty) {
    return showMessage(
        context: navigatorKey.currentState!.context,
        title: 'can only be added one way');
  }
  if (hasNotificationData.docs.isNotEmpty) {
    return showMessage(
        context: navigatorKey.currentState!.context,
        title: 'You have already sent an in invitation!');
  }
  db.collection(NOTIFICATION).add(data).then((value) {
    showMessage(
        context: navigatorKey.currentState!.context,
        title: 'success, please wait');
  }).catchError((err) {
    showMessage(
        context: navigatorKey.currentState!.context, title: err.toString());
    Navigator.pop(context);
  });
}

void newFriendAddChat(String targetUid,
    {String content = 'We are already friends, come chat!'}) {
  var currentUser = getCurrentUser();
  db.collection(ChatsKey).add({
    'messages': [
      {
        'content': content,
        'type': 'text',
        'uid': currentUser.uid,
        'targetUid': targetUid,
        'createTime': DateTime.now().millisecondsSinceEpoch
      }
    ],
    'targetMessages': [
      {
        'content': content,
        'type': 'text',
        'uid': currentUser.uid,
        'targetUid': targetUid,
        'createTime': DateTime.now().millisecondsSinceEpoch
      }
    ],
    'uid': currentUser.uid,
    'targetUid': targetUid,
    'createTime': DateTime.now().millisecondsSinceEpoch,
    'updateTime': DateTime.now().millisecondsSinceEpoch
  }).then((value) {
    updateUserChatsAndChatsId(currentUser.uid, targetUid, value.id);
  });
}

void updateUserChatsAndChatsId(String uid, String targetUid, String chatId) {
  db.collection(UsersDbKey).doc(uid).update({
    'chats': FieldValue.arrayUnion([chatId])
  });
  db.collection(UsersDbKey).doc(targetUid).update({
    'chats': FieldValue.arrayUnion([chatId])
  });
  db.collection(ChatsKey).doc(chatId).update({'id': chatId});
}

Future<String> addNewChat(String targetUid) async {
  var currentUser = getCurrentUser();
  var result = await db.collection(ChatsKey).add({
    'messages': [],
    'targetMessages': [],
    'uid': currentUser.uid,
    'targetUid': targetUid,
    'createTime': DateTime.now().millisecondsSinceEpoch,
    'updateTime': DateTime.now().millisecondsSinceEpoch
  });
  updateUserChatsAndChatsId(currentUser.uid, targetUid, result.id);
  return result.id;
}

Future<QuerySnapshot<Map<String, dynamic>>> searchUserByEmail(
    String email) async {
  return db.collection(UsersDbKey).where('email', isEqualTo: email).get();
}

Future<QuerySnapshot<Map<String, dynamic>>> searchUserByUid(String id) async {
  return db.collection(UsersDbKey).where('uid', isEqualTo: id).get();
}

Future<QuerySnapshot<Map<String, dynamic>>> searchUserByEmails(
    List emails) async {
  return db.collection(UsersDbKey).where('email', whereIn: emails).get();
}

Future<List<QuerySnapshot<Map<String, dynamic>>>> searchBatchUserByEmails(
    List emails) async {
  var listIds = sliceArr(emails);
  List<QuerySnapshot<Map<String, dynamic>>> result = [];
  for (var idList in listIds!) {
    var user =
        await db.collection(UsersDbKey).where('email', whereIn: idList).get();
    result.add(user);
  }
  return result;
}

User getCurrentUser() {
  return FirebaseAuth.instance.currentUser!;
}

var statusMapText = {
  'pending': 'to be verified',
  'success': 'added',
  'rejected': 'rejected'
};
List<Map<String, dynamic>> mapQuerySnapshotData(
    QuerySnapshot<Map<String, dynamic>> data,
    {Map<String, dynamic>? otherValue}) {
  return data.docs.map((e) {
    var baseData = {'id': e.id, ...e.data()};
    if (otherValue != null) {
      baseData = {...baseData, ...otherValue};
    }
    return baseData;
  }).toList();
}

// Create a storage reference from our app
final storageRef = FirebaseStorage.instance.ref();

// chat
Query<Map<String, dynamic>> queryMyChat(String uid, String targetUid) {
  return db
      .collection(ChatsKey)
      .where('uid', isEqualTo: uid)
      .where('targetUid', isEqualTo: targetUid);
}

Query<Map<String, dynamic>> queryTargetMyChat(String uid, String targetUid) {
  return db
      .collection(ChatsKey)
      .where('uid', isEqualTo: targetUid)
      .where('targetUid', isEqualTo: uid);
}

queryChats(List ids) async {
  if (ids.length > 10) {
    var listIds = sliceArr(ids);
    var result = [];
    for (var idList in listIds!) {
      var chats =
          await db.collection(ChatsKey).where('id', whereIn: idList).get();
      var data = await handleChatData(chats);
      result.add(data);
    }
    return result;
  } else {
    var chats = await db.collection(ChatsKey).where('id', whereIn: ids).get();
    return handleChatData(chats);
  }
}

void addMessage(String id, Map message) {
  db.collection(ChatsKey).doc(id).update({
    'messages': FieldValue.arrayUnion([message]),
    'targetMessages': FieldValue.arrayUnion([message]),
    'updateTime': DateTime.now().millisecondsSinceEpoch
  });
}

void addMultipleMessage(String id, List<Map> messages) {
  db.collection(ChatsKey).doc(id).update({
    'messages': FieldValue.arrayUnion(messages),
    'targetMessages': FieldValue.arrayUnion(messages),
    'updateTime': DateTime.now().millisecondsSinceEpoch
  });
}

Future<Map<String, dynamic>> handleChatData(
    QuerySnapshot<Map<String, dynamic>> chats) async {
  var currentUser = getCurrentUser();
  var data = chats.docs[0].data();
  var user = await searchUserByUid(currentUser.uid);
  var targetUser = await searchUserByUid(
      currentUser.uid == data['targetUid'] ? data['uid'] : data['targetUid']);
  var userData = user.docs[0].data();
  var targetUserData = targetUser.docs[0].data();
  data['userName'] = userData['userName'];
  data['chatId'] = chats.docs[0].id;
  data['userPhotoURL'] = userData['photoURL'];
  data['targetUserName'] = targetUserData['userName'];
  data['targetUserPhotoURL'] = targetUserData['photoURL'];
  data['isMyRequest'] = currentUser.uid == data['uid'];
  data['showUpdateTime'] = formatChatDate(data['updateTime']);
  data['replyUid'] = data['isMyRequest'] ? data['targetUid'] : data['uid'];
  // read message

  List messages =
      data['isMyRequest'] ? [...data['messages']] : [...data['targetMessages']];

  data['messageList'] = messages.map((message) {
    bool isMyRequest = currentUser.uid == message['uid'];
    return {
      ...message,
      'isMyRequest': isMyRequest,
      'userName': isMyRequest ? data['userName'] : data['targetUserName'],
      'avatar': isMyRequest ? data['userPhotoURL'] : data['targetUserPhotoURL'],
      'showCreateTime': formatMessageDate(message['createTime'])
    };
  }).toList();
  if (!data['messageList'].isEmpty) {
    var lastMessage = data['messageList'][messages.length - 1];
    data['lastMessage'] =
        lastMessage['type'] == 'pic' ? '[picture]' : lastMessage['content'];
    data['showAvatar'] = lastMessage['avatar'];
    data['showUserName'] = lastMessage['userName'];
  } else {
    data['showAvatar'] =
        data['isMyRequest'] ? data['targetUserPhotoURL'] : data['userPhotoURL'];
    data['showUserName'] =
        data['isMyRequest'] ? data['targetUserName'] : data['userName'];
  }
  data['appbarTitle'] =
      data['isMyRequest'] ? data['targetUserName'] : data['userName'];
  data.remove('messages');
  data.remove('targetMessages');
  return data;
}

Map<String, dynamic> getChatDataById(List<dynamic> data, String chatId) {
  var chatDataIndex = data.indexWhere((element) => element['id'] == chatId);
  return data[chatDataIndex];
}
