// add contacts
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/main.dart';

var db = FirebaseFirestore.instance;
const UsersDbKey = 'Users';
const NOTIFICATION = "notification";
addContactsNotification(String email, String remarks) async {
  // if not logged in
  if (FirebaseAuth.instance.currentUser == null) return;
  var currentUser = FirebaseAuth.instance.currentUser!;
  var userCollection = db.collection(UsersDbKey);

  if (email == currentUser.email) {
    return showMessage(
        context: navigatorKey.currentState!.context,
        type: 'warning',
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
    'targetUserPhotoURL': '',
    'targetUserName': ''
  };

  // Does the user exist
  final query = await searchUserByEmail(email);
  if (query.docs.isEmpty) {
    return showMessage(
        context: navigatorKey.currentState!.context,
        type: 'warning',
        title: 'User does not exist');
  } else {
    data['targetUserName'] = query.docs[0].data()['displayName'];
    data['targetUserPhotoURL'] = query.docs[0].data()['photoURL'];
  }
  // Is already a friend
  final queryContact = await userCollection
      .where('email', isEqualTo: currentUser.email)
      .where('contacts', arrayContains: email)
      .get();

  if (queryContact.docs.isNotEmpty) {
    return showMessage(
        context: navigatorKey.currentState!.context,
        type: 'warning',
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
        type: 'warning',
        title: 'can only be added one way');
  }
  if (hasNotificationData.docs.isNotEmpty) {
    return showMessage(
        context: navigatorKey.currentState!.context,
        type: 'warning',
        title: 'You have already sent an in invitation!');
  }
  db.collection(NOTIFICATION).add(data).then((value) {
    showMessage(
        context: navigatorKey.currentState!.context,
        title: 'success, please wait');
  }).catchError((err) {
    showMessage(
        context: navigatorKey.currentState!.context,
        type: 'danger',
        title: err.toString());
  });
}

Future<QuerySnapshot<Map<String, dynamic>>> searchUserByEmail(
    String email) async {
  return db.collection(UsersDbKey).where('email', isEqualTo: email).get();
}

User getCurrentUser() {
  return FirebaseAuth.instance.currentUser!;
}

var statusMapText = {
  'pending': 'to be verified',
  'success': 'added',
  'rejected': 'rejected'
};
