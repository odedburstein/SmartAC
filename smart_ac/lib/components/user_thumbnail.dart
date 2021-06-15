import 'package:flutter/material.dart';
import 'package:smart_ac/services/image_service.dart';

class UserThumbnail extends StatelessWidget {
  final String url;
  final bool loading;

  const UserThumbnail({
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
    final radius = 100.0;
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