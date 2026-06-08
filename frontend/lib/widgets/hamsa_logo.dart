import 'package:flutter/material.dart';
import '../core/theme.dart';

class HamsaLogo extends StatelessWidget {
  final double size;

  const HamsaLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Container(
          color: HamsaColors.cream,
          child: Transform.scale(
            scale: 2.8,
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
