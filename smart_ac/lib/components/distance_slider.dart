import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_ac/repositories/bluetooth_repository.dart';
import 'package:smart_ac/services/configurations_service.dart';
import 'package:smart_ac/services/storage_service.dart';

class DistanceSlider extends StatelessWidget {
  const DistanceSlider({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ConfigurationsService.instance().getFanDistance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(child: Container(
            padding: EdgeInsets.only(top: 21, bottom: 21),
            margin: EdgeInsets.symmetric(horizontal: 22),
            child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(5)),
                child: LinearProgressIndicator(minHeight: 6)
            ),
          ));
        }

        return _DistanceSliderView(value: snapshot.data);
      },
    );
  }
}

class _DistanceSliderView extends StatefulWidget {
  final int value;

  const _DistanceSliderView({
    @required this.value,
    Key key
  }) : super(key: key);

  @override
  _DistanceSliderViewState createState() => _DistanceSliderViewState();
}

class _DistanceSliderViewState extends State<_DistanceSliderView> {
  double value;

  @override
  void initState() {
    super.initState();
    value = widget.value.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: value,
      min: -150,
      max: 150,
      divisions: 60,
      label: () {
        final shortValue = double.parse(value.toStringAsFixed(2));
        return shortValue == 0 ? '0' : shortValue < 100 && shortValue > -100
            ? (shortValue.round() == shortValue
                ? '${shortValue.toInt()} cm'
                : '$shortValue cm')
            : '${shortValue / 100} m';
      }(),
      onChanged: (value) {
        setState(() {
          this.value = value;
        });
      },
      onChangeEnd: (value) async {
        await ConfigurationsService.instance().setFanDistance(value.round());
        await StorageService.getInstance().updateDistance(value.round());
        final bluetoothRepository = Provider.of<BluetoothRepository>(context, listen: false);
        bluetoothRepository.sendRefreshPosition();
      },
    );
  }
}

