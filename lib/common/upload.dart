import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_chat/common/firebase.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

pickerImgAndUpload(Function(String) successCallback) async {
  final ImagePicker picker = ImagePicker();
  // Pick an image
  final XFile? result = await picker.pickImage(source: ImageSource.gallery);
  var currentUser = getCurrentUser();
  if (result != null) {
    Uint8List fileBytes = await result.readAsBytes();
    final mountainsRef = FirebaseStorage.instance
        .ref('uploads/${currentUser.uid}_avatar${path.extension(result.path)}');

    mountainsRef.putData(fileBytes).snapshotEvents.listen((taskSnapshot) async {
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
          successCallback(res);
          break;
      }
    });
  }
}

Future<List<String>> uploadAssetsImage(List<AssetEntity> list) async {
  List<String> result = [];
  EasyLoading.show(status: 'upload...');
  for (var entity in list) {
    var file = await entity.originFile;
    final String path = file!.path;
    String fileName = file.uri.pathSegments.last;
    final mountainsRef = FirebaseStorage.instance.ref('messageImg/$fileName');
    Uint8List fileBytes = await file.readAsBytes();
    await mountainsRef.putData(fileBytes);
    var url = await mountainsRef.getDownloadURL();
    result.add(url);
  }
  EasyLoading.dismiss();
  return result;
}

Future<String> uploadFile(File file) async {
  EasyLoading.show(status: 'upload...');
  final String path = file.path;
  String fileName = file.uri.pathSegments.last;
  final mountainsRef = FirebaseStorage.instance.ref('messageVoice/$fileName');
  Uint8List fileBytes = await file.readAsBytes();
  await mountainsRef.putData(fileBytes);
  var url = await mountainsRef.getDownloadURL();
  EasyLoading.dismiss();
  return url;
}
