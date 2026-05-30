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
          height: size,
          width: size * 2.2,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size * 0.15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: size * 0.28,
                offset: Offset(0, size * 0.1),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.all(size * 0.08),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        if (showTagline) ...[
          SizedBox(height: size * 0.14),
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
