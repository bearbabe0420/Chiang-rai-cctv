import 'package:flutter/material.dart';

/// พื้นหลัง Gradient + รูปภาพฝั่งซ้าย
class LoginBackground extends StatelessWidget {
  final Widget child;

  const LoginBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4B39EF), Color(0xFFEE8B60)],
          stops: [0.0, 1.0],
          begin: AlignmentDirectional(0.87, -1.0),
          end: AlignmentDirectional(-0.87, 1.0),
        ),
      ),
      alignment: AlignmentDirectional(0.0, -1.0),
      child: Stack(
        children: [
          // รูปภาพพื้นหลังฝั่งซ้าย
          Align(
            alignment: AlignmentDirectional(-1.0, 0.0),
            child: Container(
              width: MediaQuery.sizeOf(context).width * 0.8,
              height: MediaQuery.sizeOf(context).height * 1.0,
              decoration: BoxDecoration(
                color: const Color(0xFF6C4343),
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: Image.asset('assets/images/login.jpg').image,
                ),
              ),
            ),
          ),
          // เนื้อหา (Form Card)
          child,
        ],
      ),
    );
  }
}
