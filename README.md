# jeefo_pitch_detector

IOS and Android cross platform native C microphone pitch detector using FFT 
analyse.

<div align="center">
  <img src="https://github.com/je3f0o/flutter-jeefo-pitch-detector/blob/master/screenshot2.jpg" width="30%" alt="Screenshot">
</div>

## Installation
```
dependencies:
  ...
  jeefo_pitch_detector:
    git:
      url: https://github.com/je3f0o/flutter-jeefo-pitch-detector.git
      ref: master
```

## Getting started
### Android
On Android you should change `minSdkVersion` to `21` in 
`android/app/build.gradle` file.  Default `minSdkVersion` is `16` which has 
problem with linking Math library when building C codes.
```
android {
  ...
  defaultConfig {
    minSdkVersion 21
    ...
  }
  ...
}
```

### IOS
You need to add `Privacy - Microphone Usage Description` in `info.plist`.

### Example Code
```dart
import 'package:jeefo_pitch_detector/jeefo_pitch_detector.dart';

// ...

class _MyHomePageState extends State<MyHomePage> {
  String _note  = "Unknown";
  double _pitch = 0.0;

  @override
  void initState() {
    super.initState();
    _activateMicrophone().then((_) {
      _updatePitch();
    });
  }

  Future<void> _activateMicrophone() async {
    await JeefoPitchDetector.activate();
  }

  Future<void> _updatePitch() async {
    List<double> values = await JeefoPitchDetector.getValues(_amplitudeThreshold);
    double pitch     = values[0];
    double amplitude = values[1];
    if (pitch > 0) {
      setState(() {
        _pitch = pitch;
        _note = JeefoPitchDetector.pitchToNoteName(pitch);
      });
    }
    // Schedule the next update
    Future.delayed(const Duration(milliseconds: 14)).then((_) => _updatePitch());
    // do your thing...
  }
}
```

## API Docs

#### JeefoPitchDetector.activate() -> boolean
It will request platform specific microphone usage if user hasn't already 
decided yet then activate Audio Engine and start recording samples to analyse.
```dart
await JeefoPitchDetector.activate();
```

#### JeefoPitchDetector.deactivate() -> boolean
```dart
await JeefoPitchDetector.deactivate();
```

### JeefoPitchDetector.getValues(double amplitudeThreshold) -> List<double>
It will retrieve currently analysed FFT pitch and amplitude values from 
background thread.
```dart
double pitch = await JeefoPitchDetector.getValues(0.05);
```

### JeefoPitchDetector.pitchToNoteName(double) -> String
It will return a String representing closest musical note for given pitch.
```dart
String note = JeefoPitchDetector.pitchToNoteName(pitch);
```

#### More configuration and API will be added next updates...

## License
**MIT**