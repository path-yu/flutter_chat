import 'package:flutter_chat/common/upload.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/components/base_text_form_filed.dart';
import 'package:flutter_chat/components/build_base_image.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/components/hide_key_bord.dart';
import 'package:flutter_chat/provider/current_user.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class EditUserPage extends StatefulWidget {
  const EditUserPage({Key? key}) : super(key: key);

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  String avatar = '';
  String userName = '';
  String suggest = '';
  bool saveLoading = true;

  @override
  void initState() {
    super.initState();
  }

  void handleOpenFilePickerClick() async {
    pickerImgAndUpload((url) {
      setState(() {
        avatar = url;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userName.isEmpty) {
      userName = context.read<CurrentUser>().value['userName'];
    }
    if (suggest.isEmpty) {
      suggest = context.read<CurrentUser>().value['suggest'];
    }
    if (avatar.isEmpty) {
      avatar = context.read<CurrentUser>().value['photoURL'];
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
              Navigator.pop(context);
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
                            child: ClipOval(
                              child: buildBaseImage(
                                  width: ScreenUtil().setWidth(60),
                                  height: ScreenUtil().setHeight(60),
                                  url: avatar),
                            ),
                          ),
                          Positioned(
                              child: SizedBox(
                            width: ScreenUtil().setWidth(60),
                            height: ScreenUtil().setHeight(60),
                            child: const CircleAvatar(
                              backgroundColor: Color.fromRGBO(0, 0, 0, .5),
                              child: Center(
                                child: Icon(Icons.camera_alt_outlined),
                              ),
                            ),
                          ))
                        ]),
                      )
                    ],
                  )),
              BaseTextFormFiled(
                labelText: 'User nickname',
                initialValue: context.read<CurrentUser>().value['userName'],
                onChanged: (value) {
                  userName = value!;
                },
              ),
              BaseTextFormFiled(
                labelText: 'suggest',
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                initialValue: context.read<CurrentUser>().value['suggest'],
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
