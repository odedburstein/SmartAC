import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_ac/components/debug_mode_switch.dart';
import 'package:smart_ac/components/distance_slider.dart';
import 'package:smart_ac/components/user_thumbnail.dart';
import 'package:smart_ac/enums/bluetooth_status.dart';
import 'package:smart_ac/repositories/bluetooth_repository.dart';
import 'package:smart_ac/services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  File _image;
  String _imageUrl;
  final ImagePicker picker = ImagePicker();
  final StorageService _imageService = StorageService.getInstance();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Scrollbar(child: ListView(padding: EdgeInsets.all(30), children: [
        Text('User photo', style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontSize: 20,
        )),
        Container(height: 8),
        Text('Upload a clear photo of your face for optimal face detection when using the fan.', style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.black54,
          fontSize: 16,
        )),
        Container(height: 15),
        Center(
          child: UserThumbnail(
            url: _imageUrl,
            loading: _imageUrl == null && _image != null,
          ),
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
        Container(height: 30),
        Text('Fan distance', style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontSize: 20,
        )),
        Container(height: 8),
        Text('Measure the distance from the camera to the fan.', style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.black54,
          fontSize: 16,
        )),
        Container(height: 15),
        DistanceSlider(),
        Container(height: 30),
        Text('Developer settings', style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontSize: 20,
        )),
        Container(height: 8),
        DebugModeSwitch(),
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

    final bluetoothRepository = Provider.of<BluetoothRepository>(context, listen: false);
    if (bluetoothRepository.status == BluetoothStatus.connected) {
      bluetoothRepository.sendRefreshUserPicture();
    }
  }
}
