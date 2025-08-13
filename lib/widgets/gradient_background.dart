import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final LinearGradient? gradient;
  final bool showCpcLogo;
  final bool useStandardBackground;

  const GradientBackground({
    super.key,
    required this.child,
    this.backgroundColor,
    this.gradient,
    this.showCpcLogo = false,
    this.useStandardBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: useStandardBackground 
            ? (backgroundColor ?? AppColors.primaryBackground)
            : null,
        gradient: useStandardBackground 
            ? null 
            : (gradient ?? AppColors.backgroundGradient),
      ),
      child: Stack(
        children: [
          // CPC Logo watermark
          if (showCpcLogo)
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: 0.03,
                  child: Transform.scale(
                    scale: 2.5,
                    child: Image.asset(
                      'assets/cpc.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          // Main content
          child,
        ],
      ),
    );
  }
}
