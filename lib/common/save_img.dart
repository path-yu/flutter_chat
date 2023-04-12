import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

saveImg(String url) async {
  var response =
      await Dio().get(url, options: Options(responseType: ResponseType.bytes));
  Directory? externalStorageDirectory = await getExternalStorageDirectory();
  File file =
      File(path.join(externalStorageDirectory!.path, path.basename(url)));
  file
      .writeAsBytes(response.data)
      .then((value) {}); // This is a sync operation on a rea
}
