import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/components/base_text_form_filed.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/components/hide_key_bord.dart';
import 'package:flutter_chat/provider/current_user.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class EditUserPage extends StatefulWidget {
  const EditUserPage({Key? key}) : super(key: key);

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  String avatar = '';
  String userName = '';
  String suggest = '';
  @override
  void initState() {
    super.initState();
    setState(() {
      avatar = getCurrentUser().photoURL!;
    });
  }

  void handleOpenFilePickerClick() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      Uint8List fileBytes = result.files.first.bytes!;
      String fileName = result.files.first.name;

      final mountainsRef = FirebaseStorage.instance.ref('uploads/$fileName');

      mountainsRef
          .putData(fileBytes)
          .snapshotEvents
          .listen((taskSnapshot) async {
        switch (taskSnapshot.state) {
          case TaskState.running:
            EasyLoading.show(status: 'uploading...');
            break;
          case TaskState.paused:
            print("Upload is paused.");
            break;
          case TaskState.canceled:
            print("Upload was canceled");
            break;
          case TaskState.error:
            // Handle unsuccessful uploads
            break;
          case TaskState.success:
            EasyLoading.dismiss();
            var res = await taskSnapshot.ref.getDownloadURL();
            setState(() {
              avatar = res;
            });
            break;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userName.isEmpty) {
      userName = context.read<CurrentUser>().value!.userName;
    }
    if (suggest.isEmpty) {
      suggest = context.read<CurrentUser>().value!.suggest;
    }
    return HideKeyboard(
      child: Scaffold(
        appBar: buildAppBar('Edit user info', context, actions: [
          buildIconButton(Icons.done, () {
            if (userName.isEmpty) {
              return showMessage(context: context, title: 'Can not be empty!');
            }
            var currentUser = FirebaseAuth.instance.currentUser!;
            currentUser.updatePhotoURL(avatar);
            currentUser.updateDisplayName(userName);
            db.collection(UsersDbKey).doc(currentUser.uid).update({
              'userName': userName,
              'suggest': suggest,
              'photoURL': avatar
            }).then((value) {
              showMessage(context: context, title: 'update completed');
            });
          }, size: ScreenUtil().setSp(20))
        ]),
        body: Padding(
          padding: EdgeInsets.all(ScreenUtil().setWidth(15)),
          child: Column(
            children: [
              SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: handleOpenFilePickerClick,
                        child: Stack(children: [
                          Positioned(
                              child: SizedBox(
                            width: ScreenUtil().setWidth(60),
                            height: ScreenUtil().setHeight(60),
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(avatar),
                            ),
                          )),
                          Positioned(
                              child: SizedBox(
                            width: ScreenUtil().setWidth(60),
                            height: ScreenUtil().setHeight(60),
                            child: CircleAvatar(
                              backgroundColor: Color.fromRGBO(0, 0, 0, .5),
                              child: Center(
                                child: const Icon(Icons.camera_alt_outlined),
                              ),
                            ),
                          ))
                        ]),
                      )
                    ],
                  )),
              BaseTextFormFiled(
                labelText: 'User nickname',
                initialValue: context.read<CurrentUser>().value!.userName,
                onChanged: (value) {
                  userName = value!;
                },
              ),
              BaseTextFormFiled(
                labelText: 'suggest',
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                initialValue: context.read<CurrentUser>().value!.suggest,
                onChanged: (value) {
                  suggest = value!;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
