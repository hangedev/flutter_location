import 'dart:io';
import 'package:flutter/material.dart';
import 'package:location/location.dart';

class ChangeSettings extends StatefulWidget {
  const ChangeSettings({super.key});

  @override
  _ChangeSettingsState createState() => _ChangeSettingsState();
}

class _ChangeSettingsState extends State<ChangeSettings> {
  final Location _location = Location();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _intervalController = TextEditingController(
    text: '5000',
  );
  final TextEditingController _distanceFilterController = TextEditingController(
    text: '0',
  );
  final TextEditingController _distanceIntervalController =
      TextEditingController(
    text: '0',
  );
  LocationAccuracy _locationAccuracy = LocationAccuracy.high;
  LocationScenario _locationScenario = LocationScenario.unset;

  // Display values that update only when Change button is pressed
  String _displayInterval = '5000';
  String _displayDistanceFilter = '0';
  String _displayDistanceInterval = '0';
  LocationAccuracy _displayAccuracy = LocationAccuracy.high;
  LocationScenario _displayScenario = LocationScenario.unset;

  @override
  void dispose() {
    _intervalController.dispose();
    _distanceFilterController.dispose();
    super.dispose();
  }

  List<Widget> widgetsOthers() {
    return [
      Text(
        'Change settings',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 4),
      TextFormField(
        keyboardType: TextInputType.number,
        controller: _intervalController,
        decoration: const InputDecoration(
          labelText: 'Interval',
        ),
      ),
      const SizedBox(height: 4),
      TextFormField(
        keyboardType: TextInputType.number,
        controller: _distanceFilterController,
        decoration: const InputDecoration(
          labelText: 'DistanceFilter',
        ),
      ),
      const SizedBox(height: 4),
      DropdownButtonFormField<LocationAccuracy>(
        value: _locationAccuracy,
        onChanged: (value) {
          if (value == null) {
            return;
          }
          setState(() {
            _locationAccuracy = value;
          });
        },
        items: const <DropdownMenuItem<LocationAccuracy>>[
          DropdownMenuItem(
            value: LocationAccuracy.high,
            child: Text('High'),
          ),
          DropdownMenuItem(
            value: LocationAccuracy.balanced,
            child: Text('Balanced'),
          ),
          DropdownMenuItem(
            value: LocationAccuracy.low,
            child: Text('Low'),
          ),
          DropdownMenuItem(
            value: LocationAccuracy.powerSave,
            child: Text('Powersave'),
          ),
        ],
      ),
      const SizedBox(height: 4),
      ElevatedButton(
        onPressed: () {
          _location.changeSettings(
            accuracy: _locationAccuracy,
            interval: int.parse(_intervalController.text),
            distanceFilter: double.parse(_distanceFilterController.text),
          );
        },
        child: const Text('Change'),
      ),
    ];
  }

  List<Widget> widgetsOhos() {
    return [
      Text(
        'Change settings',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 4),
       Text(
        'Interval: $_displayInterval',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      Text(
        'DistanceFilter: $_displayDistanceFilter',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      Text(
        'DistanceInterval: $_displayDistanceInterval',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      Text(
        'Priority: $_displayAccuracy',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      Text(
        'Scenario: $_displayScenario',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 4),
      TextFormField(
        keyboardType: TextInputType.number,
        controller: _intervalController,
        decoration: const InputDecoration(
          labelText: 'Interval',
        ),
      ),
      const SizedBox(height: 4),
      TextFormField(
        keyboardType: TextInputType.number,
        controller: _distanceFilterController,
        decoration: const InputDecoration(
          labelText: 'DistanceFilter',
        ),
      ),
      const SizedBox(height: 4),
      TextFormField(
        keyboardType: TextInputType.number,
        controller: _distanceIntervalController,
        decoration: const InputDecoration(
          labelText: 'DistanceInterval',
        ),
      ),
      const SizedBox(height: 4),
      DropdownButtonFormField<LocationAccuracy>(
        value: _locationAccuracy,
        onChanged: (value) {
          if (value == null) {
            return;
          }
          setState(() {
            _locationAccuracy = value;
            _displayAccuracy = value;
          });
        },
        items: const <DropdownMenuItem<LocationAccuracy>>[
          DropdownMenuItem(
            value: LocationAccuracy.high,
            child: Text('High'),
          ),
          DropdownMenuItem(
            value: LocationAccuracy.low,
            child: Text('Low'),
          ),
          DropdownMenuItem(
            value: LocationAccuracy.powerSave,
            child: Text('Powersave'),
          ),
          DropdownMenuItem(
            value: LocationAccuracy.unset,
            child: Text('Unset'),
          ),
        ],
      ),
      const SizedBox(height: 4),
      DropdownButtonFormField<LocationScenario>(
        value: _locationScenario,
        onChanged: (value) {
          if (value == null) {
            return;
          }
          setState(() {
            _locationScenario = value;
            _displayScenario = value;
          });
        },
        items: const <DropdownMenuItem<LocationScenario>>[
          DropdownMenuItem(
            value: LocationScenario.unset,
            child: Text('Unset'),
          ),
          DropdownMenuItem(
            value: LocationScenario.navigation,
            child: Text('Navigation'),
          ),
          DropdownMenuItem(
            value: LocationScenario.trajectoryTracking,
            child: Text('TrajectoryTracking'),
          ),
          DropdownMenuItem(
            value: LocationScenario.carHailing,
            child: Text('CarHailing'),
          ),
          DropdownMenuItem(
            value: LocationScenario.dailyLifeService,
            child: Text('DailyLifeService'),
          ),
          DropdownMenuItem(
            value: LocationScenario.noPower,
            child: Text('NoPower'),
          ),
        ],
      ),
      const SizedBox(height: 4),
      ElevatedButton(
        onPressed: () {
          _location.changeSettings(
            accuracy: _locationAccuracy,
            scenario: _locationScenario,
            interval: int.parse(_intervalController.text),
            distanceFilter: double.parse(_distanceFilterController.text),
            distanceInterval: double.parse(_distanceIntervalController.text),
          );
          setState(() {
            _displayInterval = _intervalController.text;
            _displayDistanceFilter = _distanceFilterController.text;
            _displayDistanceInterval = _distanceIntervalController.text;
            _displayAccuracy = _locationAccuracy;
            _displayScenario = _locationScenario;
          });
        },
        child: const Text('Change'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: Platform.operatingSystem =='ohos'  ? widgetsOhos() : widgetsOthers()
      )
    );
  }
}
