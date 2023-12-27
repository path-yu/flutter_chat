// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:js';
import 'dart:typed_data';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_chat/common/firebase.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'package:image_cropper/image_cropper.dart';

pickerImgAndUpload(Function(String) successCallback,
    {bool cropped = true, required BuildContext context}) async {
  final ImagePicker picker = ImagePicker();
  CroppedFile? croppedFile;
  Uint8List? fileBytes;
  String? filePath;
  // Pick an image
  final XFile? result = await picker.pickImage(source: ImageSource.gallery);
  var currentUser = getCurrentUser();
  if (result != null && cropped == true) {
    croppedFile = await ImageCropper().cropImage(
      sourcePath: result.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
      ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cropper',
        ),
        IOSUiSettings(
          title: 'Cropper',
        ),
        WebUiSettings(
          context: context,
          enableResize: true,
        ),
      ],
    );
  }
  if (croppedFile != null) {
    fileBytes = await croppedFile.readAsBytes();
    filePath = croppedFile.path;
  } else {
    if (result != null) {
      fileBytes = await result.readAsBytes();
      filePath = result.path;
    }
  }
  if (fileBytes == null) return;
  final mountainsRef = FirebaseStorage.instance
      .ref('uploads/${currentUser.uid}_avatar${path.extension(filePath!)}');
  mountainsRef.putData(fileBytes).snapshotEvents.listen((taskSnapshot) async {
    switch (taskSnapshot.state) {
      case TaskState.running:
        EasyLoading.show(status: 'uploading...');
        break;
      case TaskState.paused:
        break;
      case TaskState.canceled:
        break;
      case TaskState.error:
        print('error');
        // Handle unsuccessful uploads
        break;
      case TaskState.success:
        EasyLoading.dismiss();
        var res = await taskSnapshot.ref.getDownloadURL();
        successCallback(res);
        break;
    }
  });
}

Future<List<String>> uploadAssetsImage(List<AssetEntity> list) async {
  List<String> result = [];
  EasyLoading.show(status: 'upload...');
  for (var entity in list) {
    var file = await entity.originFile;
    // final String path = file!.path;
    String fileName = file!.uri.pathSegments.last;
    final mountainsRef = FirebaseStorage.instance.ref('messageImg/$fileName');
    Uint8List fileBytes = await file.readAsBytes();
    await mountainsRef.putData(fileBytes);
    var url = await mountainsRef.getDownloadURL();
    result.add(url);
  }
  EasyLoading.dismiss();
  return result;
}

Future<String> uploadFile(File file, BuildContext context) async {
  EasyLoading.show(status: 'upload...');
  String fileName = file.uri.pathSegments.last;
  final mountainsRef = FirebaseStorage.instance.ref('messageVoice/$fileName');
  try {
    Uint8List fileBytes = await file.readAsBytes();
    await mountainsRef.putData(fileBytes);
    var url = await mountainsRef.getDownloadURL();
    return url;
  } on FirebaseException catch (e) {
    showOkAlertDialog(context: context, message: e.message!);
    return ''; // 或者抛出异常，具体取决于你的
  } finally {
    EasyLoading.dismiss();
  }
}

Future<String> uploadFileByStream(
    Uint8List stream, BuildContext context, String fileName) async {
  EasyLoading.show(status: 'upload...');
  final mountainsRef = FirebaseStorage.instance.ref('messageVoice/$fileName');

  try {
    await mountainsRef.putData(stream);
    var url = await mountainsRef.getDownloadURL();
    return url;
  } on FirebaseException catch (e) {
    showOkAlertDialog(context: context, message: e.message!);
    return ''; // 或者抛出异常，具体取决于你的需求
  } finally {
    EasyLoading.dismiss();
  }
}
