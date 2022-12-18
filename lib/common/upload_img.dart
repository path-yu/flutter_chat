import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';

pickerImgAndUpload(Function(String) successCallback) async {
  final ImagePicker picker = ImagePicker();
  // Pick an image
  final XFile? result = await picker.pickImage(source: ImageSource.gallery);

  if (result != null) {
    Uint8List fileBytes = await result.readAsBytes();
    String fileName = result.name;

    final mountainsRef = FirebaseStorage.instance.ref('uploads/$fileName');

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
