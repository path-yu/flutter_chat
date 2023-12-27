// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:flutter_chat/components/base_text_form_filed.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/components/hide_key_bord.dart';
import 'package:flutter_chat/main.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:octo_image/octo_image.dart';

class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final formKey = GlobalKey<FormState>();
  String email = '';
  String remarks = '';
  String photoUrl = '';

  checkUserContain(_) async {
    if (email == FirebaseAuth.instance.currentUser!.email) {
      return showMessage(
          context: navigatorKey.currentState!.context,
          title: 'cannot add itself');
    }
    // search user
    var query = await searchUserByEmail(email);
    if (query.docs.isEmpty && context.mounted) {
      showMessage(context: context, title: 'User does not exist');
    } else {
      var user = query.docs[0].data();
      setState(() {
        photoUrl = user['photoURL'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return HideKeyboard(
      child: Scaffold(
        appBar: buildAppBar('Add contacts', context),
        body: Container(
          padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(25)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  if (photoUrl.isNotEmpty)
                    OctoImage.fromSet(
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      image: CachedNetworkImageProvider(photoUrl),
                      octoSet: OctoSet.circleAvatar(
                        backgroundColor: Colors.white54,
                        text: const Text(""),
                      ),
                    )
                  else
                    ClipOval(
                      child: Container(
                        width: 40,
                        height: 40,
                        color: Colors.blue,
                      ),
                    ),
                  SizedBox(
                    width: ScreenUtil().setWidth(20),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Form(
                          key: formKey,
                          child: Column(
                            children: [
                              BaseTextFormFiled(
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Please enter user email';
                                  }
                                  return null;
                                },
                                onEditingComplete: checkUserContain,
                                onChanged: (String? value) {
                                  email = value!;
                                },
                                hintText: 'Email',
                                prefixIcon: Icons.email,
                                textInputAction: TextInputAction.search,
                              ),
                              BaseTextFormFiled(
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Please enter remarks';
                                  }
                                  return null;
                                },
                                onChanged: (String? value) {
                                  remarks = value!;
                                },
                                hintText: 'Remarks',
                                prefixIcon: Icons.info,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              SizedBox(
                height: ScreenUtil().setHeight(20),
              ),
              FractionallySizedBox(
                widthFactor: 1,
                child: ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        await addContactsNotification(email, remarks, context);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('confirm')),
              )
            ],
          ),
        ),
      ),
    );
  }
}
