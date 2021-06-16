import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_ac/repositories/bluetooth_repository.dart';
import 'package:smart_ac/services/configurations_service.dart';

class DistanceSlider extends StatelessWidget {
  const DistanceSlider({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ConfigurationsService.instance().getFanDistance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(child: CircularProgressIndicator());
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
      divisions: 20,
      label: value == 0 ? '0' : value < 100 && value > -100
          ? (value.round() == value ? '${value.toInt()} cm' : '$value cm')
          : '${value / 100} m',
      onChanged: (value) {
        setState(() {
          this.value = value;
        });
      },
      onChangeEnd: (value) async {
        await ConfigurationsService.instance().setFanDistance(value.round());
        final bluetoothRepository = Provider.of<BluetoothRepository>(context, listen: false);
        bluetoothRepository.sendRefreshPosition();
      },
    );
  }
}

