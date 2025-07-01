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

  Widget _buildValue(Fortune fortune) {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Get the shortest side of the screen for more consistent sizing
      final screenSize = MediaQuery.of(context).size;
      final shortestSide = screenSize.shortestSide;
      
      // Calculate dynamic size based on screen dimensions
      final dynamicSize = size * (shortestSide / 400); // 400 is a baseline width
      
      // Calculate responsive font sizes
      final minFontSize = (shortestSide * 0.03).clamp(12.0, 24.0);
      final maxFontSize = (shortestSide * 0.05).clamp(24.0, 48.0);
      
      // Calculate responsive padding and spacing
      final topPadding = (dynamicSize * 0.15).clamp(10.0, 40.0);
      final contentWidth = (dynamicSize * 0.4).clamp(80.0, 300.0);
      
      return Container(
        height: dynamicSize,
        width: dynamicSize,
        alignment: Alignment.topCenter,
        padding: EdgeInsets.only(top: topPadding),
        child: ConstrainedBox(
          constraints: BoxConstraints.expand(
            height: dynamicSize / 2.5,
            width: contentWidth,
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (fortune.titleName != null)
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: (dynamicSize * 0.02).clamp(4.0, 12.0),
                        horizontal: (dynamicSize * 0.02).clamp(4.0, 12.0),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AutoSizeText(
                          fortune.titleName!,
                          style: fortune.textStyle?.copyWith(
                            fontSize: maxFontSize,
                          ) ?? TextStyle(
                            color: fortune.FontColor ?? Colors.white,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SamsungSharpSans',
                            fontSize: maxFontSize,
                            letterSpacing: (shortestSide * 0.001).clamp(0.5, 1.5),
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          minFontSize: minFontSize,
                          maxFontSize: maxFontSize,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                if (fortune.icon != null)
                  Padding(
                    padding: EdgeInsets.all(
                      fortune.titleName == null
                          ? (dynamicSize * 0.02).clamp(4.0, 12.0)
                          : (dynamicSize * 0.01).clamp(2.0, 6.0),
                    ),
                    child: SizedBox(
                      width: (dynamicSize * 0.2).clamp(24.0, 80.0),
                      height: (dynamicSize * 0.2).clamp(24.0, 80.0),
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
      ..color = const Color.fromARGB(255, 76, 4, 4) ////color of the dots
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
