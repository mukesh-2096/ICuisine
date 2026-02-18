import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final bool showBackground;

  const AppLogo({
    super.key,
    this.size = 100,
    this.backgroundColor,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBackground) {
      return Image.asset(
        'images/white_logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.15),
      child: ClipOval(
        child: Image.asset(
          'images/white_logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
