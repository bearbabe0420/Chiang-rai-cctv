import 'package:flutter/material.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const InfoRow({super.key, required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF8A8A8E)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF8A8A8E))),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
        ],
      ),
    );
  }
}

class InfoRowDivider extends StatelessWidget {
  const InfoRowDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      const Divider(color: Color(0xFFF2F2F7), height: 1, thickness: 1);
}