import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';

class ImageService {
  FirebaseStorage _firebaseStorage;
  static final _imagePath = 'user.jpg';
  static final ImageService _imageService = ImageService._();

  ImageService._(): _firebaseStorage = FirebaseStorage.instance;

  factory ImageService.getInstance() => _imageService;

  Future uploadImage(File image) async {
    final taskSnapshot = await _firebaseStorage.ref()
        .child(_imagePath)
        .putFile(image)
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