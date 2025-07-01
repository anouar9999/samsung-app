import 'dart:math';
import 'package:flutter/material.dart';

class ArrowView extends StatelessWidget {
  final double? size;
  final List<Color>? gradientColors;
  final double? angle;
  final double? shadowBlur;
  final Color? shadowColor;

  const ArrowView({
    Key? key,
    this.size,
    this.gradientColors,
    this.angle,
    this.shadowBlur,
    this.shadowColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive size based on parent constraints
        final arrowSize = size ?? (constraints.maxWidth * 0.05).clamp(20.0, 40.0);
        
        return Transform.rotate(
          angle: angle ?? pi / 2,
          child: ClipPath(
            clipper: _ArrowClipper(),
            child: Container(
              height: arrowSize,
              width: arrowSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors ?? [
                    const Color(0xFFFF0000).withOpacity(0.7),
                    const Color(0xFFDD0000),
                  ],
                  stops: const [0.2, 0.9],
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor ?? Colors.black38,
                    blurRadius: shadowBlur ?? (arrowSize * 0.2),
                    offset: Offset(0, arrowSize * 0.1),
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

class _ArrowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final center = size.center(Offset.zero);
    
    return Path()
      ..moveTo(0, 0)
      ..lineTo(center.dx, size.height)
      ..lineTo(size.width, 0)
      ..lineTo(center.dx, size.height * 0.25)
      ..close();
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}