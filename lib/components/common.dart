import 'package:flutter/material.dart';
import 'package:flutter_chat/main.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

double baseSize = ScreenUtil().setSp(16);
PreferredSizeWidget buildAppBar(String title, BuildContext context,
    {centerTitle = true,
    showBackButton = true,
    List<Widget>? actions,
    double? leadingWidth,
    Widget? leading}) {
  return AppBar(
    leading: leading ?? (showBackButton ? const BackButton() : Container()),
    title: Text(
      title,
      style: TextStyle(fontSize: baseSize),
    ),
    centerTitle: centerTitle,
    actions: actions,
    leadingWidth: leadingWidth,
  );
}

Widget buildIcon(IconData icon) {
  return Icon(
    icon,
    size: baseSize,
  );
}

Widget buildIconButton(IconData icon, Function()? onPressed,
    {double size = 16, Color? iconColor}) {
  return IconButton(
    icon: Icon(
      icon,
      size: size,
      color: iconColor,
    ),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    onPressed: onPressed,
  );
}

Widget buildClearInputIcon(Function()? onPressed) {
  return IconButton(
      onPressed: onPressed,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      icon: Icon(
        Icons.highlight_off_rounded,
        size: baseSize,
      ));
}

Transform buttonLoading = Transform.scale(
  scale: 0.4,
  child: const CircularProgressIndicator(),
);

showMessage({
  required BuildContext context,
  required String title,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      elevation: 6,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      padding: const EdgeInsets.all(10),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(5))),
      content: Row(
        children: [
          SizedBox(
            width: ScreenUtil().setWidth(5),
          ),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              style: const TextStyle(overflow: TextOverflow.ellipsis),
            ),
          )
        ],
      ),
    ),
  );
}

TextStyle subtitleTextStyle = const TextStyle(color: Color(0xff737373));

Future<bool?> showBaseAlertDialog(
    {required Widget contentWidget,
    required String title,
    bool? showCancel = true,
    required Function? onConfirm,
    Function? onClose}) {
  onConfirm ??= () {};
  onClose ??= () {};
  return showDialog(
      context: navigatorKey.currentState!.context,
      builder: (context) {
        List<Widget> actions = [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop();
              onClose!();
            },
          ),
          TextButton(
            child: const Text("Confirm"),
            onPressed: () {
              onConfirm!();
              onClose!();
            },
          )
        ];
        if (!showCancel!) {
          actions.removeAt(0);
        }
        return AlertDialog(
          content: contentWidget,
          actionsAlignment: MainAxisAlignment.center,
          title: Text(
            title,
            textAlign: TextAlign.center,
          ),
          actions: actions,
        );
      });
}

var baseDivider = Divider(
  color: Colors.grey,
  height: ScreenUtil().setHeight(1),
  indent: ScreenUtil().setWidth(65),
);

var baseLoading = const SizedBox(
  width: double.infinity,
  height: double.infinity,
  child: Center(
    child: CircularProgressIndicator(),
  ),
);
Widget buildOneLineText(text) {
  return Text(
    text,
    maxLines: 1,
    style: const TextStyle(
      overflow: TextOverflow.ellipsis,
    ),
  );
}

Widget buildBaseEmptyWidget(String message) {
  return SizedBox(
    width: double.infinity,
    height: double.infinity,
    child: Center(
      child: Opacity(opacity: 0.6, child: Text(message)),
    ),
  );
}

Widget buildSpace(width) {
  return SizedBox(
    width: width,
    child: Container(),
  );
}
