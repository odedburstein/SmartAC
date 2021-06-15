import 'package:flutter/material.dart';
import 'package:smart_ac/services/configurations_service.dart';

class DistanceSlider extends StatelessWidget {
  final ValueChanged<int> onChanged;

  const DistanceSlider({
    @required this.onChanged,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ConfigurationsService.instance().getFanDistance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(child: CircularProgressIndicator());
        }

        return _DistanceSliderView(onChanged: onChanged, value: snapshot.data);
      },
    );
  }
}

class _DistanceSliderView extends StatefulWidget {
  final ValueChanged<int> onChanged;
  final int value;

  const _DistanceSliderView({
    @required this.onChanged,
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
      label: value < 100 && value > -100 ? '$value cm' : '${value / 100} m',
      onChanged: (value) {
        final roundValue = value.round();
        setState(() {
          this.value = value;
        });

        widget.onChanged(roundValue);
      },
      onChangeEnd: (value) {
        ConfigurationsService.instance().setFanDistance(value.round());
      },
    );
  }
}

