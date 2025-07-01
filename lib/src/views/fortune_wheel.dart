import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_fortune_wheel/src/helpers/constant.dart';
import 'package:flutter_fortune_wheel/src/models/models.dart';
import 'package:flutter_fortune_wheel/src/pages/soufleur.dart';
import 'package:flutter_fortune_wheel/src/pages/your_gain.dart';
import 'package:flutter_fortune_wheel/src/views/arrow_view.dart';
import 'package:flutter_fortune_wheel/src/views/board_view.dart';

import '../core/core.dart';
import 'package:confetti/confetti.dart';

class FortuneWheel extends StatefulWidget {
  const FortuneWheel({
    Key? key,
    required this.wheel,
    required this.onChanged,
    required this.onResult,
    this.onAnimationStart,
    this.onAnimationEnd,
  }) : super(key: key);

  ///Configure wheel
  final Wheel wheel;

  ///Handling updates of changed values while spinning
  final Function(Fortune item) onChanged;

  ///Handling returning the result of the spin
  final Function(Fortune item) onResult;

  ///Handling when starting to spin
  final VoidCallback? onAnimationStart;

  ///Handling when spinning ends
  final VoidCallback? onAnimationEnd;

  @override
  _FortuneWheelState createState() => _FortuneWheelState();
}

class _FortuneWheelState extends State<FortuneWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _wheelAnimationController;
  late Animation _wheelAnimation;
  late ConfettiController _confettiController;

  ///Wheel rotation angle
  ///Default value [_angle] = 0
  double _angle = 0;

  ///Current rotation angle of the wheel after spinning
  ///Default value [_currentAngle]=0
  double _currentAngle = 0;

  ///Index of the current position of the prize value on wheel
  int _currentIndex = 0;
  int? nino;

  ///Index of the result after spinning the wheel
  int _indexResult = 0;

  double get wheelSize =>
      widget.wheel.size ??
      MediaQuery.of(context as BuildContext).size.shortestSide * 0.8;
  Future<void> _initializeSpinData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
  }

  @override
  void initState() {
    super.initState();
    _initializeSpinData();
    _wheelAnimationController =
        AnimationController(vsync: this, duration: widget.wheel.duration);
    _wheelAnimation = CurvedAnimation(
      parent: _wheelAnimationController,
      curve: Curves.fastLinearToSlowEaseIn,
    );
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));
  }

  @override
  void dispose() {
    super.dispose();
    _confettiController.dispose(); // Add this line to dispose the controller

    _wheelAnimationController.dispose();
  }

  List<int> winCountsPerPeriod = [0, 0, 0, 0];
  List<int> stocksPerPeriod = [stock1, stock2, stock3, stock4];
  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final meanSize = (deviceSize.width + deviceSize.height) / 2;
    final panFactor = 6 / meanSize;
    return PanAwareBuilder(
      physics: CircularPanPhysics(),
      onFling: _handleSpinByRandomPressed,
      builder: (BuildContext context, PanState panState) {
        final panAngle = panState.distance * panFactor;
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            AnimatedBuilder(
              animation: _wheelAnimation,
              child: Container(
                child: BoardView(
                  items: widget.wheel.items,
                  size: wheelSize,
                ),
              ),
              builder: (context, child) {
                ///Rotation angle of the wheel
                final angle = _wheelAnimation.value * _angle;
                if (_wheelAnimationController.isAnimating) {
                  _indexResult = _getIndexFortune(angle + _currentAngle);
                  widget.onChanged.call(widget.wheel.items[_indexResult]);
                }
                final rotationAngle =
                    2 * pi * widget.wheel.rotationCount * _wheelAnimation.value;

                ///Current angle position of the standing wheel
                final current = _currentAngle + rotationAngle + panAngle;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: angle + current,
                      child: child,
                    ),
                    _buildCenterOfWheel(),
                    // _buildButtonSpin(),
                  ],
                );
              },
            ),
            SizedBox(
              height: wheelSize,
              width: wheelSize,
              child: Align(
                alignment: const Alignment(1.08, 0),
                child:   ArrowView(),
              ),
            ),
          ],
        );
      },
    );
  }

  ///UI Wheel center
Widget _buildCenterOfWheel() {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Get the screen size
      final screenSize = MediaQuery.of(context).size;
      final shortestSide = screenSize.shortestSide;
      
      // Calculate responsive dimensions
      final baseSize = (shortestSide * 0.25).clamp(100.0, 200.0);
      final marginSize = (baseSize * 0.053).clamp(4.0, 12.0);
      final borderWidth = (baseSize * 0.013).clamp(1.0, 3.0);
      final paddingSize = (baseSize * 0.1).clamp(10.0, 20.0);
      
      // Calculate responsive shadow values
      final blurRadius = (baseSize * 0.1).clamp(10.0, 20.0);
      final spreadRadius = (baseSize * 0.007).clamp(0.5, 2.0);
      final shadowOffset = (baseSize * 0.033).clamp(3.0, 8.0);

      return Container(
        width: baseSize,
        height: baseSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[300]!,
              Colors.white,
              Colors.grey[100]!,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            // Outer shadow
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: blurRadius,
              offset: Offset(0, shadowOffset),
              spreadRadius: spreadRadius,
            ),
            // Inner highlight
            BoxShadow(
              color: Colors.white.withOpacity(0.9),
              blurRadius: blurRadius,
              offset: Offset(-shadowOffset, -shadowOffset),
              spreadRadius: spreadRadius,
            ),
          ],
        ),
        child: Container(
          margin: EdgeInsets.all(marginSize),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: borderWidth,
            ),
            gradient: RadialGradient(
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.grey[100]!.withOpacity(0.8),
                Colors.grey[300]!.withOpacity(0.5),
              ],
              stops: const [0.2, 0.6, 1.0],
            ),
          ),
          child: Container(
            margin: EdgeInsets.all(marginSize * 0.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey[300]!,
                width: borderWidth * 0.5,
              ),
            ),
            child: ClipOval(
              child: Container(
                padding: EdgeInsets.all(paddingSize),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: blurRadius * 0.33,
                        spreadRadius: spreadRadius,
                        offset: Offset(0, shadowOffset * 0.4),
                      ),
                    ],
                  ),
                  child: Container(), // Placeholder for image
                  // Uncomment below when ready to use image
                  // child: Image.asset(
                  //   "assets/icons/Layer 1.png",
                  //   fit: BoxFit.contain,
                  // ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
  ///UI Button Spin
Widget _buildButtonSpin() {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Calculate responsive sizes
      final buttonWidth = (constraints.maxWidth * 0.3).clamp(120.0, 200.0);
      final buttonHeight = (buttonWidth * 0.4).clamp(48.0, 64.0);
      final fontSize = (buttonWidth * 0.15).clamp(14.0, 24.0);
      
      return Visibility(
        visible: !_wheelAnimationController.isAnimating,
        child: widget.wheel.action ?? 
        Container(
          width: buttonWidth,
          height: buttonHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(buttonHeight / 2),
           
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextButton(
            onPressed: _handleSpinByRandomPressed,
            style: widget.wheel.spinButtonStyle ??
            TextButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(buttonHeight / 2),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: buttonWidth * 0.1,
                vertical: buttonHeight * 0.1,
              ),
            ),
            child: widget.wheel.childSpinButton ??
            Container()
          ),
        ),
      );
    },
  );
}
  ///Handling mode random spinning
Future<void> _handleSpinByRandomPressed() async {
  if (_wheelAnimationController.isAnimating) return;

  try {
    final random = Random();
    
    // First, decide the winning index
    final winningIndex = random.nextInt(widget.wheel.items.length);
    
    // Calculate required angle to land on this index
    final baseAngle = (2 * pi / widget.wheel.items.length) * winningIndex;
    final fullRotations = widget.wheel.rotationCount * 2 * pi;
    final fineAdjustment = random.nextDouble() * (2 * pi / widget.wheel.items.length / 2);
    
    // Final angle combines full rotations and position for winning index
    _angle = fullRotations + baseAngle + fineAdjustment;

    // Start animation
    await Future.microtask(() => widget.onAnimationStart?.call());
    await _wheelAnimationController.forward(from: 0.0);

    // Update current angle
    final factor = (_currentAngle / (2 * pi) + _angle / (2 * pi)) % 1;
    _currentAngle = factor * 2 * pi;
    
    // Get winning item using the predetermined index
    final winningItem = widget.wheel.items[winningIndex];
    widget.onResult.call(winningItem);
    
    _wheelAnimationController.reset();

    // Show winner dialog
    await _showWinnerDialog(context, winningItem);
    
    await Future.microtask(() => widget.onAnimationEnd?.call());
    
  } catch (error) {
    debugPrint('Error during spin: $error');
  }
}

Future<void> _showWinnerDialog(BuildContext context, Fortune winningItem) async {
  final Size screenSize = MediaQuery.of(context).size;
  final double dialogWidth = screenSize.width < 600 ? screenSize.width * 0.85 : 400.0;

  showGeneralDialog(
    context: context,
    pageBuilder: (context, animation1, animation2) {
      return Stack(
        children: [
          // Backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ),

          // Dialog Content
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  // Center Dialog
                  Center(
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 400),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + (0.2 * value),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: GestureDetector(
                        onTap: () {}, // Prevents tap from propagating
                        child: Container(
                          width: dialogWidth,
                          decoration: BoxDecoration(
                            color: const Color(0xFF171717),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Close Button
                              Align(
                                alignment: Alignment.topRight,
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              
                              // Content
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'CONGRATULATIONS!',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Color(0xFF0098FF),
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    const Text(
                                      "You've won",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    // Enhanced Prize Display
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 28,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2A2A2A),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        children: [
                                          // Prize Icon if available
                                          if (winningItem.icon != null) ...[
                                            SizedBox(
                                              height: 64,
                                              child: winningItem.icon,
                                            ),
                                            const SizedBox(height: 20),
                                          ],
                                          
                                          // Prize Name
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              winningItem.titleName?.toUpperCase() ?? '',
                                              style: const TextStyle(
                                                fontSize: 44,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.5,
                                                height: 1.2,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 32),
                                    
                                    // Claim Button
                                ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Confetti Layer
                  ...List.generate(3, (index) {
                    Alignment alignment;
                    double? blastDirection;
                    List<Color> colors = const [
                      Color(0xFF0098FF),
                      Color(0xFFFFD700),
                      Color(0xFF00C754),
                      Color(0xFFFF2D55),
                      Colors.white,
                    ];

                    switch (index) {
                      case 0:
                        alignment = Alignment.topCenter;
                        break;
                      case 1:
                        alignment = const Alignment(-0.8, -0.8);
                        blastDirection = pi / 4;
                        break;
                      default:
                        alignment = const Alignment(0.8, -0.8);
                        blastDirection = 3 * pi / 4;
                        break;
                    }

                    return Align(
                      alignment: alignment,
                      child: ConfettiWidget(
                        confettiController: _confettiController,
                        blastDirectionality: blastDirection == null 
                            ? BlastDirectionality.explosive 
                            : BlastDirectionality.directional,
                        particleDrag: 0.05,
                        emissionFrequency: 0.03,
                        numberOfParticles: index == 0 ? 50 : 25,
                        maxBlastForce: 25,
                        minBlastForce: 15,
                        gravity: 0.2,
                        colors: colors,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      );
    },
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: child,
      );
    },
  );

  // Start confetti after dialog is shown
  _confettiController.play();
}

Widget _buildConfettiOverlay() {
  return Stack(
    children: [
      // Center burst
      Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          particleDrag: 0.05,
          emissionFrequency: 0.08,
          numberOfParticles: 30,
          maxBlastForce: 20,
          minBlastForce: 10,
          gravity: 0.2,
          colors: const [
            Color(0xFF0098FF),  // Electric Blue
            Color(0xFFFFD700),  // Sunny Yellow
            Color(0xFF008754),  // Sprite Green
            Colors.white,
          ],
        ),
      ),
      // Left burst
      Align(
        alignment: const Alignment(-0.8, -0.8),
        child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirection: pi / 4,
          particleDrag: 0.05,
          emissionFrequency: 0.08,
          numberOfParticles: 15,
          colors: const [
            Color(0xFF0098FF),
            Color(0xFFFFD700),
          ],
        ),
      ),
      // Right burst
      Align(
        alignment: const Alignment(0.8, -0.8),
        child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirection: 3 * pi / 4,
          particleDrag: 0.05,
          emissionFrequency: 0.08,
          numberOfParticles: 15,
          colors: const [
            Color(0xFF008754),
            Colors.white,
          ],
        ),
      ),
    ],
  );
}

Widget _buildPrizeDescriptionBox(Fortune prize) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    decoration: BoxDecoration(
      color: const Color(0xFF2A2A2A),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        if (prize.icon != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SizedBox(
              height: 64,
              child: prize.icon,
            ),
          ),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'You\'ve won\n',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              TextSpan(
                text: '${prize.titleName}\n',
                style: const TextStyle(
                  fontSize: 24,
                  color: Color(0xFF0098FF),
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildClaimButton(BuildContext context) {
  return Container(
    width: double.infinity,
    height: 56,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0098FF), Color(0xFF008754)],
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0098FF).withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: MaterialButton(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      onPressed: () => Navigator.of(context).pop(),
      child: const Text(
        'CLAIM YOUR PRIZE',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    ),
  );
}

Widget _buildCloseButton(BuildContext context) {
  return Align(
    alignment: Alignment.topRight,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: () => Navigator.of(context).pop(),
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Icons.close, color: Color(0xFFC0C0C0), size: 24),
        ),
      ),
    ),
  );
}

Widget _buildCongratulationsText() {
  return ShaderMask(
    shaderCallback: (Rect bounds) {
      return const LinearGradient(
        colors: [Color(0xFF0098FF), Color(0xFFFFD700)],
      ).createShader(bounds);
    },
    child: const Text(
      'CONGRATULATIONS!',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1.5,
      ),
    ),
  );
}

Widget _buildPrizeName(String prizeName) {
  return Text(
    prizeName,
    textAlign: TextAlign.center,
    style: const TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      letterSpacing: 2,
    ),
  );
}



Widget _buildTermsLink() {
  return InkWell(
    onTap: () {
      // Handle terms click
    },
    child: const Text(
      'View Terms & Conditions',
      style: TextStyle(
        fontSize: 14,
        color: Color(0xFFC0C0C0),
        decoration: TextDecoration.underline,
        decorationColor: Color(0xFF0098FF),
      ),
    ),
  );
}


Widget _buildConfettiEffects() {
  return Stack(
    children: [
      Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          particleDrag: 0.05,
          emissionFrequency: 0.08,
          numberOfParticles: 30,
          maxBlastForce: 20,
          minBlastForce: 10,
          gravity: 0.2,
          colors: const [
            Color(0xFF0098FF),  // Electric Blue
            Color(0xFFFFD700),  // Sunny Yellow
            Color(0xFF008754),  // Sprite Green
            Colors.white,
          ],
        ),
      ),
      Align(
        alignment: const Alignment(-0.8, -0.8),
        child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirection: pi / 4,
          particleDrag: 0.05,
          emissionFrequency: 0.08,
          numberOfParticles: 15,
          colors: const [
            Color(0xFF0098FF),
            Color(0xFFFFD700),
          ],
        ),
      ),
      Align(
        alignment: const Alignment(0.8, -0.8),
        child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirection: 3 * pi / 4,
          particleDrag: 0.05,
          emissionFrequency: 0.08,
          numberOfParticles: 15,
          colors: const [
            Color(0xFF008754),
            Colors.white,
          ],
        ),
      ),
    ],
  );
}
  ///Handling the calculation of the index value of the element while spinning
  int _getIndexFortune(double value) {
    int itemCount = widget.wheel.items.length;

    double rightOffset = value - (pi / itemCount);
    return (itemCount - rightOffset / (2 * pi) * itemCount).floor() % itemCount;
  }

  ///Handling mode spinning based on prioritized winning values
  // Future<void> _handleSpinByPriorityPressed() async {
  //   if (!_wheelAnimationController.isAnimating) {
  //     int spinCount = 0;
  //     totalSpins++;

  //     final winningValues = [1, 3, 5, 7];
  //     final losingValues = [0, 2, 4, 6];
  //     List<int> targetValues = losingValues;
  //     if (isWin) {
  //       targetValues = winningValues;
  //     }

  //     final index = targetValues[Random().nextInt(targetValues.length)];
  //     spinCount++;

  //     final itemCount = widget.wheel.items.length;
  //     final angleFactor = _currentIndex > index
  //         ? _currentIndex - index
  //         : itemCount - (index - _currentIndex);
  //     _angle = (2 * pi / itemCount) * angleFactor +
  //         widget.wheel.rotationCount * 2 * pi;

  //     await Future.microtask(() => widget.onAnimationStart?.call());
  //     await _wheelAnimationController.forward(from: 0.0).then((_) {
  //       double factor = _currentAngle / (2 * pi);
  //       factor += (_angle / (2 * pi));
  //       factor %= 1;
  //       _currentAngle = factor * 2 * pi;
  //       _wheelAnimationController.reset();
  //       _currentIndex = index;
  //       widget.onResult.call(widget.wheel.items[_currentIndex]);
  //     });
  //     await Future.microtask(() => widget.onAnimationEnd?.call());

  //     print("Current index: $_currentIndex");

  //     if (winningValues.contains(_currentIndex)) {
  //       totalWins++;
  //       sendDataTrue();
  //       navigateToSecondRouteAfterDelay(true);
  //     } else {
  //       totalLosses++;
  //       // controlMotor();
  //       navigateToSecondRouteAfterDelay(false);
  //     }

  //     // _saveData();
  //     Fortune _fortuneItem = widget.wheel.items[_currentIndex];
  //     _fortuneItem = _fortuneItem.copyWith(priority: 0);
  //     widget.onChanged.call(_fortuneItem);
  //   }
  // }

  Future<void> sendDataTrue() async {
    final String url = 'http://192.168.${IpController.text}:5000/motor';

    try {
      // Create a JSON payload

      // Send a POST request to the Jetson Nano
      var response = await http.post(Uri.parse(url), body: {'data': 'True'});

      if (response.statusCode == 200) {
        // Data sent successfully

        print('Data sent successfully!');
      } else {
        // Failed to send data
        print('Failed to send data. Error code: ${response.statusCode}');
      }
    } catch (e) {
      // Error occurred while sending data
      print('Error occurred while sending data: $e');
    }
  }

  Future navigateToSecondRouteAfterDelay(bool value) async {
    if (value == true) {
      Navigator.push(
        context as BuildContext,
        MaterialPageRoute(builder: (context) => ImageFramePage()),
      );
    } else {
      Navigator.push(
        context as BuildContext,
        MaterialPageRoute(builder: (context) => soufleurPage()),
      );
    }
  }

  // void controlMotor() async {
  //   final response = await http.post(
  //     Uri.parse('http://192.168.${IpController.text}:5000/blower'),
  //     body: {'data': 'True'},
  //   );

  //   if (response.statusCode == 200) {
  //     // If the server returns a 200 OK response, then parse the JSON.
  //     print('Motor control successful');
  //   } else {
  //     // If the server returns an unexpected response, then throw an exception.
  //     throw Exception('Failed to control motor');
  //   }
  // }

// _saveData() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('totalSpins', totalSpins);
//     await prefs.setInt('totalWins', totalWins);
//     await prefs.setInt('totalLosses', totalLosses);

//     DateTime now = DateTime.now();
//     if (now.hour == 21) {
//         // Store data to Firestore every day at 21:00
//         // Use a timestamp to create a unique document ID
//         await FirebaseFirestore.instance.collection('stats').doc('${now.toIso8601String()}').set({
//             'totalSpins': totalSpins,
//             'totalWins': totalWins,
//             'totalLosses': totalLosses,
//             'day': now.day,
//             'hour': now.hour,
//         });

//         // Reset the values
//         totalSpins = 0;
//         totalWins = 0;
//         totalLosses = 0;
//         await prefs.setInt('totalSpins', totalSpins);
//         await prefs.setInt('totalWins', totalWins);
//         await prefs.setInt('totalLosses', totalLosses);
//     }
// }

// Future<void> saveValues() async {
//   // You should get the actual values of totalSpins, totalWins and totalLosses
//   SharedPreferences prefs = await SharedPreferences.getInstance();

//   // Store the actual values to SharedPreferences
//   await prefs.setInt('totalSpins', totalSpins);
//   await prefs.setInt('totalWins', totalWins);
//   await prefs.setInt('totalLosses', totalLosses);

//   // Save the timestamp as a String
//   String timestamp = DateTime.now().toIso8601String();
//   await prefs.setString('ValuesSavedAt', timestamp);

//   // Save to SQLite Database

//   print('Values saved at $timestamp');
// }
}
