import 'package:flutter/material.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/components/drawer.dart';
import 'package:flutter_chat/main.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeContacts extends StatefulWidget {
  const HomeContacts({super.key});

  @override
  State<HomeContacts> createState() => _HomeContactsState();
}

class _HomeContactsState extends State<HomeContacts> {
  void handleAddContactClick() {
    final formKey = GlobalKey<FormState>();
    var email = '';
    var remarks = '';
    // 显示对话框的代码
    showDialog(
        context: context,
        builder: (BuildContext scaffoldContext) => AlertDialog(
              title: const Text('Add contacts'),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () {},
                ),
                TextButton(
                  child: const Text("Confirm"),
                  onPressed: () {
                    const snackbar = SnackBar(
                      content: Text(
                        'Hello, SnackBar!',
                      ),
                    );

                    showMessage(
                        context: navigatorKey.currentState!.context,
                        type: 'warning',
                        title: 'User does not exist');
                    if (formKey.currentState!.validate()) {}
                  },
                )
              ],
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          onChanged: (value) => email = value,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter user email';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                              hintText: 'Email',
                              prefixIcon: buildIcon(Icons.email)),
                        ),
                        TextFormField(
                          obscureText: true,
                          onChanged: (value) => remarks = value,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter remarks';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                              hintText: 'Remarks',
                              prefixIcon: buildIcon(Icons.info)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    print('build');
    return Scaffold(
      drawer: const DrawerHead(),
      appBar: buildAppBar('Contacts', context,
          showBackButton: false,
          actions: [
            buildIconButton(Icons.search, (() {
              Navigator.pushNamed(context, '/search');
            }), size: ScreenUtil().setSp(20)),
            buildIconButton(Icons.add, handleAddContactClick,
                size: ScreenUtil().setSp(20))
          ],
          leadingWidth: ScreenUtil().setWidth(30),
          leading: GestureDetector(
            onTap: () {
              Scaffold.of(context).openDrawer();
            },
            child: Padding(
              padding: EdgeInsets.only(left: ScreenUtil().setWidth(5)),
              child: const Image(
                image: NetworkImage(
                    'https://avatars.githubusercontent.com/u/59117479?v=4'),
              ),
            ),
          )),
      body: Column(
        children: [
          ListTile(
            onTap: () {},
            leading: Icon(
              Icons.person_add,
              size: ScreenUtil().setSp(25),
            ),
            title: const Text('new friends'),
          ),
          ListTile(
            onTap: () {},
            leading: Icon(
              Icons.groups,
              size: ScreenUtil().setSp(25),
            ),
            title: const Text('group chat'),
          )
        ],
      ),
    );
  }
}
