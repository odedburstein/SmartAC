import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_ac/image_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  File _image;
  String _imageUrl;
  final ImagePicker picker = ImagePicker();
  final ImageService _imageService = ImageService.getInstance();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Scrollbar(child: ListView(padding: EdgeInsets.all(15), children: [
        _UserThumbnail(
          url: _imageUrl,
          loading: _imageUrl == null && _image != null,
        ),
        Container(height: 15),
        OutlinedButton.icon(
            onPressed: () => _uploadImage(ImageSource.camera),
            icon: Icon(Icons.camera_alt_rounded),
            label: Text('Upload from camera')
        ),
        OutlinedButton.icon(
            onPressed: () => _uploadImage(ImageSource.gallery),
            icon: Icon(Icons.collections_rounded),
            label: Text('Upload from gallery')
        ),
      ])),
    );
  }

  Future<void> _uploadImage(ImageSource source) async {
    final pickedFile = await picker.getImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _imageUrl = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No image selected')));
      return;
    }

    final imageUrl = await _imageService.uploadImage(_image);
    setState(() {
      _image = null;
      _imageUrl = imageUrl;
    });
  }
}

class _UserThumbnail extends StatelessWidget {
  final String url;
  final bool loading;

  const _UserThumbnail({
    this.url,
    this.loading = false,
    Key key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return FutureBuilder(
        future: ImageService.getInstance().getImageURL(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return thumbnail(url: snapshot.data);
          }

          return thumbnail(loading: true);
        },
      );
    }

    return thumbnail(url: url, loading: loading);
  }

  Widget thumbnail({ String url, bool loading = false }) {
    final radius = 50.0;
    if (loading) {
      return Container(
        height: radius * 2,
        width: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blueGrey[200],
        ),
        child: Center(
          child: CircularProgressIndicator()
        ),
      );
    }

    if (url == null || url == '') {
      return Container(
        height: radius * 2,
        width: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blueGrey[200],
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(url),
      backgroundColor: Colors.transparent,
    );
  }
}

