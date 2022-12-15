import 'package:flutter/material.dart';
import 'package:flutter_chat/components/base_text_form_filed.dart';
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
  @override
  Widget build(BuildContext context) {
    return HideKeyboard(
      child: Scaffold(
        appBar: buildAppBar('Edit user info', context, actions: [
          buildIconButton(Icons.done, () {}, size: ScreenUtil().setSp(20))
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
                      Stack(children: [
                        Positioned(
                            child: SizedBox(
                          width: ScreenUtil().setWidth(60),
                          height: ScreenUtil().setHeight(60),
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(
                                context.watch<CurrentUser>().value!.photoURL),
                          ),
                        )),
                        Positioned(
                            child: SizedBox(
                          width: ScreenUtil().setWidth(60),
                          height: ScreenUtil().setHeight(60),
                          child: CircleAvatar(
                            backgroundColor: Color.fromRGBO(0, 0, 0, .5),
                            child: Center(
                              child: GestureDetector(
                                child: Icon(Icons.camera_alt_outlined),
                                onTap: () {},
                              ),
                            ),
                          ),
                        ))
                      ])
                    ],
                  )),
              BaseTextFormFiled(
                labelText: 'User nickname',
              ),
              BaseTextFormFiled(
                labelText: 'suggest',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
