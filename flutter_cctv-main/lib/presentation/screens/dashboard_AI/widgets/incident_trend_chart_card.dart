import 'dart:math' as math;

import 'package:flutter/material.dart';
import '/core/i18n/i18n.dart';

import 'dashboard_card.dart';

class IncidentTrendChartCard extends StatelessWidget {
  final String monthLabel;
  final List<double> licenseSeries;
  final List<double> accidentSeries;
  final List<double> fightingSeries;

  const IncidentTrendChartCard({
    super.key,
    this.monthLabel = 'This Month',
    this.licenseSeries = const [8, 12, 10, 15, 11, 18, 14],
    this.accidentSeries = const [2, 4, 3, 5, 4, 6, 5],
    this.fightingSeries = const [1, 2, 1, 3, 2, 2, 1],
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: Color(0xFF334155),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        'dashboard_ai.chart.title',
                        fallback: 'Detection Trend',
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      monthLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _LegendPill(
                label: 'License Plate',
                color: Color(0xFF2563EB),
              ),
              _LegendPill(
                label: 'Accident',
                color: Color(0xFFDC2626),
              ),
              _LegendPill(
                label: 'Fighting',
                color: Color(0xFFF59E0B),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 220,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: CustomPaint(
                    painter: _TrendChartPainter(
                      licenseSeries: licenseSeries,
                      accidentSeries: accidentSeries,
                      fightingSeries: fightingSeries,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _AxisLabel(text: 'W1'),
                    _AxisLabel(text: 'W2'),
                    _AxisLabel(text: 'W3'),
                    _AxisLabel(text: 'W4'),
                    _AxisLabel(text: 'W5'),
                    _AxisLabel(text: 'W6'),
                    _AxisLabel(text: 'W7'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}

class _AxisLabel extends StatelessWidget {
  final String text;

  const _AxisLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xFF9CA3AF),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<double> licenseSeries;
  final List<double> accidentSeries;
  final List<double> fightingSeries;

  const _TrendChartPainter({
    required this.licenseSeries,
    required this.accidentSeries,
    required this.fightingSeries,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final all = [...licenseSeries, ...accidentSeries, ...fightingSeries];
    final maxValue = all.isEmpty ? 1.0 : math.max(1.0, all.reduce(math.max));

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    _drawSeries(
      canvas,
      size,
      licenseSeries,
      const Color(0xFF2563EB),
      maxValue,
    );
    _drawSeries(
      canvas,
      size,
      accidentSeries,
      const Color(0xFFDC2626),
      maxValue,
    );
    _drawSeries(
      canvas,
      size,
      fightingSeries,
      const Color(0xFFF59E0B),
      maxValue,
    );
  }

  void _drawSeries(
    Canvas canvas,
    Size size,
    List<double> series,
    Color color,
    double maxValue,
  ) {
    if (series.length < 2) return;

    final path = Path();
    final dx = size.width / (series.length - 1);

    for (int i = 0; i < series.length; i++) {
      final x = dx * i;
      final y = size.height - (series[i] / maxValue) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = color;
    for (int i = 0; i < series.length; i++) {
      final x = dx * i;
      final y = size.height - (series[i] / maxValue) * size.height;
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.licenseSeries != licenseSeries ||
        oldDelegate.accidentSeries != accidentSeries ||
        oldDelegate.fightingSeries != fightingSeries;
  }
}
