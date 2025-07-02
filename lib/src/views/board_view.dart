import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/src/helpers/helpers.dart';
import 'package:flutter_fortune_wheel/src/models/models.dart';
import 'package:auto_size_text/auto_size_text.dart';

///UI Wheel
class BoardView extends StatelessWidget {
  const BoardView({
    Key? key,
    required this.items,
    required this.size,
  }) : super(key: key);

  ///List of values for the wheel elements
  final List<Fortune> items;

  ///Size of the wheel
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(
          items.length,
          (index) => _buildSlicedCircle(items[index]),
        ),
      ),
    );
  }

  Widget _buildSlicedCircle(Fortune fortune) {
    double _rotate = getRotateOfItem(
      items.length,
      items.indexOf(fortune),
    );
    return Transform.rotate(
      angle: _rotate,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildCard(fortune),
          _buildValue(fortune),
        ],
      ),
    );
  }

  Widget _buildCard(Fortune fortune) {
    double _angle = 2 * math.pi / items.length;
    return CustomPaint(
      painter: _BorderPainter(_angle),
      child: ClipPath(
        clipper: _SlicesPath(_angle),
        child: Container(
          height: size,
          width: size,
          color: fortune.backgroundColor,
        ),
      ),
    );
  }

// Improved responsive _buildValue method
Widget _buildValue(Fortune fortune) {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Get screen dimensions for better responsiveness
      final screenSize = MediaQuery.of(context).size;
      final shortestSide = screenSize.shortestSide;
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final orientation = MediaQuery.of(context).orientation;
      
      // Enhanced dynamic size calculation
      double baselineWidth = 400.0;
      if (orientation == Orientation.landscape) {
        baselineWidth = 500.0; // Adjust for landscape
      }
      
      final dynamicSize = size * (shortestSide / baselineWidth);
      
      // Improved responsive font sizing with device density consideration
      double fontSizeMultiplier = 1.0;
      if (devicePixelRatio > 2.5) {
        fontSizeMultiplier = 1.1; // Slightly larger on high-density screens
      }
      
      // Calculate responsive font sizes with smaller fonts for small phones
      double minFontSize, maxFontSize, optimalFontSize;
      
      if (shortestSide < 360) {
        // Very small phones - significantly smaller fonts
        minFontSize = (shortestSide * 0.025 * fontSizeMultiplier).clamp(8.0, 14.0);
        maxFontSize = (shortestSide * 0.04 * fontSizeMultiplier).clamp(12.0, 20.0);
        optimalFontSize = (14.0 * fontSizeMultiplier).clamp(minFontSize, maxFontSize);
      } else if (shortestSide < 400) {
        // Small phones - smaller fonts
        minFontSize = (shortestSide * 0.028 * fontSizeMultiplier).clamp(9.0, 16.0);
        maxFontSize = (shortestSide * 0.045 * fontSizeMultiplier).clamp(14.0, 24.0);
        optimalFontSize = (16.0 * fontSizeMultiplier).clamp(minFontSize, maxFontSize);
      } else {
        // Normal and larger phones - original sizing
        minFontSize = (shortestSide * 0.035 * fontSizeMultiplier).clamp(12.0, 22.0);
        maxFontSize = (shortestSide * 0.055 * fontSizeMultiplier).clamp(18.0, 42.0);
        optimalFontSize = (19.0 * fontSizeMultiplier).clamp(minFontSize, maxFontSize);
      }
      
      // Enhanced responsive spacing calculations with smaller spacing for small phones
      double topPadding, contentWidth, containerHeight, iconSize, iconPadding;
      
      if (shortestSide < 360) {
        // Very small phones - compact spacing
        topPadding = (dynamicSize * 0.08).clamp(4.0, 20.0);
        contentWidth = (dynamicSize * 0.5).clamp(60.0, 200.0);
        containerHeight = (dynamicSize / 2.8).clamp(35.0, 120.0);
        iconSize = (dynamicSize * 0.15).clamp(16.0, 45.0);
      } else if (shortestSide < 400) {
        // Small phones - reduced spacing
        topPadding = (dynamicSize * 0.1).clamp(6.0, 25.0);
        contentWidth = (dynamicSize * 0.48).clamp(65.0, 220.0);
        containerHeight = (dynamicSize / 2.5).clamp(40.0, 150.0);
        iconSize = (dynamicSize * 0.16).clamp(18.0, 55.0);
      } else if (shortestSide < 600) {
        // Normal phones - standard spacing with more top padding
        topPadding = (dynamicSize * 0.16).clamp(12.0, 45.0);
        contentWidth = (dynamicSize * 0.45).clamp(70.0, 280.0);
        containerHeight = (dynamicSize / 2.3).clamp(50.0, 200.0);
        iconSize = (dynamicSize * 0.18).clamp(20.0, 70.0);
      } else {
        // Large phones and tablets - even more top padding
        topPadding = (dynamicSize * 0.16).clamp(12.0, 45.0);
        contentWidth = (dynamicSize * 0.42).clamp(80.0, 300.0);
        containerHeight = (dynamicSize / 2.2).clamp(60.0, 220.0);
        iconSize = (dynamicSize * 0.17).clamp(22.0, 75.0);
      }
      
      iconPadding = fortune.titleName == null 
          ? (dynamicSize * 0.015).clamp(3.0, 10.0)
          : (dynamicSize * 0.008).clamp(1.5, 5.0);
      
      return Container(
        height: dynamicSize,
        width: dynamicSize,
        alignment: Alignment.topCenter,
        padding: EdgeInsets.only(top: topPadding),
        child: ConstrainedBox(
          constraints: BoxConstraints.expand(
            height: containerHeight,
            width: contentWidth,
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Enhanced text rendering
                if (fortune.titleName != null)
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: minFontSize * 1.2,
                        maxHeight: containerHeight * 0.6,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: AutoSizeText(
                          fortune.titleName!,
                          style: fortune.textStyle?.copyWith(
                            fontSize: optimalFontSize,
                            height: 1.1, // Better line height for readability
                            letterSpacing: 0.5, // Improved letter spacing
                          ) ?? TextStyle(
                            color: fortune.FontColor ?? Colors.white,
                            fontFamily: 'SamsungSharpSans-medium',
                            fontSize: optimalFontSize,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                            letterSpacing: 0.5,
                            shadows: [
                              // Add text shadow for better readability
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          minFontSize: minFontSize,
                          maxFontSize: maxFontSize,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          presetFontSizes: [
                            maxFontSize,
                            optimalFontSize,
                            minFontSize,
                          ],
                        ),
                      ),
                    ),
                  ),
                
                // Enhanced icon rendering
                if (fortune.icon != null)
                  Padding(
                    padding: EdgeInsets.all(iconPadding),
                    child: Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        // Optional: Add background for better icon visibility
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            offset: Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black.withOpacity(0.1),
                          ),
                        ],
                      ),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: fortune.icon!,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
}

///Wheel frame painter
class _BorderPainter extends CustomPainter {
  final double angle;

  _BorderPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    const double radiusDot = 3;
    double radius = size.width / 2;
    Offset center = size.center(Offset.zero);

    //Inner shadow gradient
    Paint innerShadow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent, // Fade to transparent towards center
                    Colors.black.withOpacity(0.05), // Dark shadow at the edge

        ],
        stops: [0.0, 1.0], // Shadow starts at 85% of the radius
        center: Alignment.center,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    // Draw inner shadow circle
    canvas.drawCircle(center, radius - 12.5, innerShadow); // Adjust radius to fit inside the border

    //Outer border
    Paint outlineBrush = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25.0
      ..color = Color.fromRGBO(255, 255, 255, 0.875); ////border of the wheel
    Rect rect = Rect.fromCircle(center: center, radius: size.width / 2);
    Path pathFirst = Path()
      ..arcTo(rect, -math.pi / 2 - angle / 2, angle, false);

    //Second frame with white background
    Paint outlineBrushSecond = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..color = Colors.white;
    Rect rectSecond =
        Rect.fromCircle(center: center, radius: size.width / 2 - 6);
    Path pathSecond = Path()
      ..arcTo(rectSecond, -math.pi / 2 - angle / 2, angle, false);

    //LED lights
    Paint centerDot = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color.fromARGB(255, 255, 255, 255) ////color of the dots
      ..strokeWidth = 100.0;

    Paint secondaryDot = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white
      ..strokeWidth = 7.0;

    //Coordinates of the center of the circle
    Offset centerSlice = Offset(radius, 0);

    //Coordinate difference coefficient between two ends of the circular arc
    double dxFactor = math.sin(angle / 2) * radius;
    double dyFactor = math.cos(angle / 2) * radius;

    Offset rightSlice = Offset(radius - dxFactor, radius - dyFactor);
    Offset leftSlice = Offset(radius + dxFactor, radius - dyFactor);

    canvas.drawPath(pathFirst, outlineBrush);
    canvas.drawPath(pathSecond, outlineBrushSecond);
    canvas.drawCircle(centerSlice, radiusDot, centerDot);
    canvas.drawCircle(rightSlice, radiusDot, secondaryDot);
    canvas.drawCircle(leftSlice, radiusDot, secondaryDot);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}


class _SlicesPath extends CustomClipper<Path> {
  final double angle;

  _SlicesPath(this.angle);

  @override
  Path getClip(Size size) {
    Offset center = size.center(Offset.zero);
    Rect rect = Rect.fromCircle(center: center, radius: size.width / 2 - 7);
    Path path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, -math.pi / 2 - angle / 2, angle, false)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(_SlicesPath oldClipper) {
    return angle != oldClipper.angle;
  }
}
