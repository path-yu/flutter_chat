import 'package:flutter/material.dart';
import 'package:flutter_chat/components/color.dart';
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
    {double size = 16}) {
  return IconButton(
    icon: Icon(
      icon,
      size: size,
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

showMessage(
    {required BuildContext context,
    required String title,
    String type = 'success'}) {
  Color color = baseThemeMap[type]!;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
        content: Row(
          children: [
            Icon(
              iconMap[type],
              color: Colors.white,
              size: ScreenUtil().setSp(18),
            ),
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
        backgroundColor: color),
  );
}

TextStyle subtitleTextStyle = const TextStyle(color: Color(0xff737373));
