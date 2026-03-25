import 'package:flutter/material.dart';

/// พื้นหลัง Gradient + รูปภาพฝั่งซ้าย
class LoginBackground extends StatelessWidget {
  final Widget child;

  const LoginBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/IMG_0017.JPG',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to a known bundled image if this asset is unavailable.
              return Image.asset(
                'assets/images/login.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              );
            },
          ),
          child,
        ],
      ),
    );
  }
}
