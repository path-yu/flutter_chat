import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/components/base_text_form_filed.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/components/hide_key_bord.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:octo_image/octo_image.dart';

class NewFriendsPage extends HookWidget {
  const NewFriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final listData = useState([]);
    final loading = useState(true);
    var currentUser = getCurrentUser();

    void initData() async {
      final queryAddMy = await db
          .collection(NOTIFICATION)
          .where('targetEmail', isEqualTo: currentUser.email)
          .where('type', isEqualTo: 'addContact')
          .get();
      final queryMyRequest = await db
          .collection(NOTIFICATION)
          .where('email', isEqualTo: currentUser.email)
          .get();
      var result = [...queryAddMy.docs, ...queryMyRequest.docs]
          .map((e) => {'id': e.id, ...e.data()})
          .toList();
      listData.value = result;
      loading.value = false;
    }

    useEffect(() {
      initData();
      return null;
    }, []);
    void handleAgreeClick(int index) {
      var newData = [...listData.value];
      newData[index]['status'] = 'success';
      listData.value = newData;
      var listDataItem = listData.value[index];
      db
          .collection(NOTIFICATION)
          .doc(listDataItem['id'])
          .update({'status': 'success'}).then((value) {
        showMessage(context: context, title: 'Success');
        db
            .collection(UsersDbKey)
            .doc(
              currentUser.uid,
            )
            .update({
          'contacts': FieldValue.arrayUnion([listDataItem['email']])
        });
        db
            .collection(UsersDbKey)
            .doc(
              listDataItem['uid'],
            )
            .update({
          'contacts': FieldValue.arrayUnion([currentUser.email])
        });
      });
    }

    void handleRejectClick(int index) {
      var newData = [...listData.value];
      newData[index]['status'] = 'rejected';
      listData.value = newData;
      var listDataItem = listData.value[index];
      db
          .collection(NOTIFICATION)
          .doc(listDataItem['id'])
          .update({'status': 'rejected'}).then((value) {});
    }

    return HideKeyboard(
      child: Scaffold(
        appBar: buildAppBar('New friends', context),
        body: loading.value
            ? baseLoading
            : Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(ScreenUtil().setWidth(10)),
                    child: const BaseTextFormFiled(
                      hintText: 'email',
                      prefixIcon: Icons.search,
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  Expanded(
                      child: ListView.separated(
                    itemBuilder: (context, index) {
                      var item = listData.value[index];
                      var isMyRequest = currentUser.email == item['email'];
                      var photoURL = isMyRequest
                          ? item['targetUserPhotoURL']
                          : item['photoURL'];
                      var userName = isMyRequest
                          ? item['targetUserName']
                          : item['userName'];
                      var remarks = item['remarks'];
                      String status = item['status'];
                      return ListTile(
                          onTap: () {},
                          leading: ClipRect(
                            child: OctoImage(
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              image: CachedNetworkImageProvider(photoURL),
                            ),
                          ),
                          title: Text(userName),
                          subtitle: Text(
                            remarks,
                            maxLines: 1,
                            style: const TextStyle(
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          trailing: isMyRequest
                              ? Text(
                                  statusMapText[status]!,
                                  style: subtitleTextStyle,
                                )
                              : status == 'pending'
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextButton(
                                            onPressed: () =>
                                                handleAgreeClick(index),
                                            child: const Text('agree')),
                                        TextButton(
                                            onPressed: () =>
                                                handleRejectClick(index),
                                            child: const Text('reject'))
                                      ],
                                    )
                                  : Text(statusMapText[status]!,
                                      style: subtitleTextStyle));
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return baseDivider;
                    },
                    itemCount: listData.value.length,
                  ))
                ],
              ),
      ),
    );
  }
}
