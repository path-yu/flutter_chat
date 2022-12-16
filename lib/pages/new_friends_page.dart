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
      List<Map<String, dynamic>> result = [
        ...queryAddMy.docs,
        ...queryMyRequest.docs
      ]
          .map((e) => {
                'id': e.id,
                'isMyRequest': currentUser.email == e.data()['email'],
                ...e.data()
              })
          .toList();
      var userData = await db
          .collection(UsersDbKey)
          .where('email',
              whereIn: result.map((e) {
                if (e['isMyRequest'] != true) {
                  return e['email'];
                } else {
                  return e['targetEmail'];
                }
              }).toList())
          .get();
      result = result.asMap().entries.map((entry) {
        int index = entry.key;
        var data = {...entry.value};
        if (data['isMyRequest']) {
          data['userName'] = getCurrentUser().displayName;
          data['photoURL'] = getCurrentUser().photoURL;
        } else {
          data['userName'] = userData.docs[index].data()['userName'];
          data['photoURL'] = userData.docs[index].data()['photoURL'];
        }
        return data;
      }).toList();
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
                      child: listData.value.isEmpty
                          ? buildBaseEmptyWidget('no data')
                          : ListView.separated(
                              itemBuilder: (context, index) {
                                var item = listData.value[index];
                                var isMyRequest = item['isMyRequest'];
                                var photoURL = item['photoURL'];
                                var userName = item['userName'];

                                var remarks = item['remarks'];
                                String status = item['status'];
                                return ListTile(
                                    onTap: () {},
                                    leading: ClipRect(
                                      child: OctoImage(
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        image: CachedNetworkImageProvider(
                                            photoURL),
                                      ),
                                    ),
                                    title: buildOneLineText(
                                      userName,
                                    ),
                                    subtitle: buildOneLineText(
                                      remarks,
                                    ),
                                    trailing: isMyRequest
                                        ? status == 'success'
                                            ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.done),
                                                  SizedBox(
                                                    width: ScreenUtil()
                                                        .setWidth(5),
                                                  ),
                                                  Text(statusMapText[status]!,
                                                      style: subtitleTextStyle)
                                                ],
                                              )
                                            : Text(statusMapText[status]!)
                                        : status == 'pending'
                                            ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  TextButton(
                                                      onPressed: () =>
                                                          handleAgreeClick(
                                                              index),
                                                      child:
                                                          const Text('agree')),
                                                  TextButton(
                                                      onPressed: () =>
                                                          handleRejectClick(
                                                              index),
                                                      child:
                                                          const Text('reject'))
                                                ],
                                              )
                                            : Text(statusMapText[status]!));
                              },
                              separatorBuilder:
                                  (BuildContext context, int index) {
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
