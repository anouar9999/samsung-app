import 'dart:async';
import 'dart:math';
// import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:flutter_fortune_wheel_example/common/constants.dart';
import 'package:flutter_fortune_wheel_example/common/theme.dart';
import 'package:flutter_fortune_wheel_example/pages/fortune_wheel_history_page.dart';
import 'package:flutter_fortune_wheel_example/widgets/fortune_wheel_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const MyApp(),
      title: 'Wheel of Fortune',
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final StreamController<Fortune> _resultWheelController =
      StreamController<Fortune>.broadcast();

  final StreamController<bool> _fortuneWheelController =
      StreamController<bool>.broadcast();

  final BackgroundPainterController _painterController =
      BackgroundPainterController();

  TextEditingController IpController2 = TextEditingController();
  TextEditingController StockController1 = TextEditingController();
  TextEditingController StockController2 = TextEditingController();

  TextEditingController StockController3 = TextEditingController();

  TextEditingController StockController4 = TextEditingController();

  late ConfettiController _confettiController;

  Wheel _wheel = Wheel(
    items: Constants.loveOrNotLove,
    isSpinByPriority: false,
    duration: const Duration(seconds: 10),
  );
// Save the IP
  Future<void> saveIP(String ip) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('ip', ip);
  }

// Load the IP
  Future<String?> loadIP() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('ip');
  }

  Future<void> loadIp() async {
    String? ip = await loadIP();
    if (ip != null) {
      setState(() {
        IpController.text = ip;
      });
    }
  }

  @override
  void initState() {
    loadIp();
    super.initState();
    _painterController.playAnimation();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 10));
  }

  @override
  void dispose() {
    super.dispose();
    _resultWheelController.close();
    _fortuneWheelController.close();
    _confettiController.dispose();
  }

@override
Widget build(BuildContext context) {
  final screenSize = MediaQuery.of(context).size;
  final leftImageWidth = (screenSize.width * 0.35).clamp(200.0, 300.0);
  final rightImageWidth = (screenSize.width * 0.35).clamp(200.0, 300.0);
  
  return Scaffold(
    backgroundColor: Colors.white,
    body: Stack(
      children: [
        // Background with wheel
        FortuneWheelBackground(
          painterController: _painterController,
          
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "SPIN TO WIN",
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'SamsungSharpSans',
                    fontSize: 50,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 40),
                _buildFortuneWheel(),
              ],
            ),
          ),
        ),

        // Left image (with StreamBuilder)
        StreamBuilder<Fortune>(
          stream: _resultWheelController.stream,
          builder: (context, snapshot) {
            return Positioned(
              left: -leftImageWidth * 0.1, // Adjust this value to move image left/right
              top: -leftImageWidth * 0.1,  // Adjust this value to move image up/down
              child: GestureDetector(
                onTap: () => setState(() => isWin = true),
                child: SizedBox(
                  width: leftImageWidth,
                  child: Image.asset(
                    'assets/icons/669x1153-removebg.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            );
          },
        ),

        // Right image
        Positioned(
          right: -rightImageWidth * 0.1, // Adjust this value to move image left/right
          bottom: -rightImageWidth * 0.1, // Adjust this value to move image up/down
          child: GestureDetector(
            onTap: () => setState(() => isWin = true),
            child: SizedBox(
              width: rightImageWidth,
              child: Image.asset(
                'assets/icons/856x1486_s25_s25+__page-0001-removebg-preview.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        // Confetti overlay
        _buildConfettiOverlay(),
      ],
    ),
  );
}


  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step),
          halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }

  Widget _buildHeader() {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.only(right: 8, left: 16),
        child: Row(
          children: [
            SizedBox(width: 16),
            Text(
              '',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            Spacer(),
            // IconButton(
            //   splashRadius: 28,
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => FortuneWheelHistoryPage(
            //           resultsHistory: _resultsHistory,
            //         ),
            //       ),
            //     );
            //   },
            //   icon: const Icon(Icons.bar_chart, color: Colors.white),
            // ),
          ],
        ),
      ),
    );
  }

Widget _buildFortuneWheel() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final wheelSize = constraints.maxWidth * 0.8;
      return Center(
        child: StreamBuilder<bool>(
          stream: _fortuneWheelController.stream,
          builder: (context, snapshot) {
            if (snapshot.data == false) {
              return const SizedBox.shrink();
            }
            return SizedBox(
              width: wheelSize,
              height: wheelSize,
              child: FortuneWheel(
                key: const ValueKey<String>('ValueKeyFortunerWheel'),
                wheel: _wheel,
                onChanged: (Fortune item) {
                  _resultWheelController.sink.add(item);
                },
                onResult: _onResult,
              ),
            );
          },
        ),
      );
    },
  );
}

// Modified Confetti overlay
Widget _buildConfettiOverlay() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final particleCount = (constraints.maxWidth / 20).round(); // Responsive particle count
      return ConfettiWidget(
        confettiController: _confettiController,
        blastDirectionality: BlastDirectionality.explosive,
        shouldLoop: false,
        maxBlastForce: constraints.maxWidth * 0.05, // Responsive blast force
        minBlastForce: constraints.maxWidth * 0.02,
        particleDrag: 0.05,
        emissionFrequency: 0.08,
        numberOfParticles: particleCount,
        gravity: 0.2,
        colors: const [
          Colors.green,
          Colors.blue,
          Colors.pink,
          Colors.orange,
          Colors.purple,
          Colors.yellow,
        ],
        createParticlePath: drawStar,
      );
    },
  );
}
  Future<void> _onResult(Fortune item) async {
    // Play the confetti when result is shown
    _confettiController.play();

    // Stop the confetti after 5 seconds
    await Future.delayed(const Duration(seconds: 5));
    _confettiController.stop();
  }
Widget _buildResultIsChange() {
  return StreamBuilder<Fortune>(
    stream: _resultWheelController.stream,
    builder: (context, snapshot) {
      return Positioned(
        left: 0,
        top: 0,
        child: GestureDetector(
          onTap: () {
            setState(() {
              isWin = true;
            });
          },
          child: Image.asset(
            'assets/icons/669x1153-removebg.png',
            width: 300,
            fit: BoxFit.contain,
          ),
        ),
      );
    },
  );
}
//confetti widget

  /// A custom Path to paint stars.
  Path _drawStar(Size size) {
    // Method to convert degree to radians
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step),
          halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }
}
