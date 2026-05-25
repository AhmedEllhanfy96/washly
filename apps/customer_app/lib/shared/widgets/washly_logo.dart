import 'package:flutter/material.dart';

class WashlyLogo extends StatelessWidget {
  final double size;
  final bool showTagline;
  final Color textColor;

  const WashlyLogo({
    super.key,
    this.size = 80,
    this.showTagline = false,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF00ACC1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D47A1).withOpacity(0.45),
                blurRadius: size * 0.35,
                offset: Offset(0, size * 0.12),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Large faint water drop — gives depth
              Icon(
                Icons.water_drop,
                color: Colors.white.withOpacity(0.12),
                size: size * 0.78,
              ),
              // Main car icon
              Padding(
                padding: EdgeInsets.only(top: size * 0.05),
                child: Icon(
                  Icons.directions_car,
                  color: Colors.white,
                  size: size * 0.44,
                ),
              ),
              // Accent drop top-right
              Positioned(
                top: size * 0.14,
                right: size * 0.14,
                child: Icon(
                  Icons.water_drop,
                  color: const Color(0xFF80DEEA),
                  size: size * 0.19,
                ),
              ),
              // Accent drop top-left smaller
              Positioned(
                top: size * 0.18,
                left: size * 0.18,
                child: Icon(
                  Icons.water_drop,
                  color: Colors.white.withOpacity(0.5),
                  size: size * 0.12,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: size * 0.13),
        Text(
          'WASHLY',
          style: TextStyle(
            color: textColor,
            fontSize: size * 0.27,
            fontWeight: FontWeight.w900,
            letterSpacing: size * 0.065,
          ),
        ),
        if (showTagline) ...[
          SizedBox(height: size * 0.05),
          Text(
            'Your car, sparkled clean',
            style: TextStyle(
              color: textColor.withOpacity(0.65),
              fontSize: size * 0.12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}
