import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageService {
  FirebaseStorage _firebaseStorage;
  static final _imagePath = 'user.jpg';
  static final ImageService _imageService = ImageService._();

  ImageService._(): _firebaseStorage = FirebaseStorage.instance;

  factory ImageService.getInstance() => _imageService;

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
}