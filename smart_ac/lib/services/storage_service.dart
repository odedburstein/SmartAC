import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:flutter_image_compress/flutter_image_compress.dart';

class StorageService {
  FirebaseStorage _firebaseStorage;
  static final _imagePath = 'user.jpg';
  static final _distancePath = 'distance.txt';
  static final StorageService _instance = StorageService._();

  StorageService._(): _firebaseStorage = FirebaseStorage.instance;

  factory StorageService.getInstance() => _instance;

  Future uploadImage(File image) async {
    final dir = await path_provider.getTemporaryDirectory();
    final targetPath = '${dir.absolute.path}/$_imagePath';

    final compressedImage = await FlutterImageCompress.compressAndGetFile(
      image.absolute.path, targetPath, minHeight: 240, minWidth: 320
    );

    final taskSnapshot = await _firebaseStorage.ref()
        .child(_imagePath)
        .putFile(compressedImage)
        .whenComplete(() {});
    return taskSnapshot.ref.getDownloadURL();
  }

  Future<String> getImageURL() async {
    var url;

    try {
      url = await _firebaseStorage.ref()
          .child(_imagePath)
          .getDownloadURL();
    } catch (_) {
      url = null;
    }

    return url;
  }

  Future<void> updateDistance(int distance) async {
    final dir = await path_provider.getTemporaryDirectory();
    final file = File('${dir.absolute.path}/$_distancePath');
    await file.writeAsString('$distance');

    await _firebaseStorage.ref()
        .child(_distancePath)
        .putFile(file)
        .whenComplete(() {});
  }
}