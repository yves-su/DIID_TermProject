import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/home_provider.dart';
import '../../models/imu_frame.dart';
import '../ui_layout.dart';
import '../widgets/page_body.dart';

class RecordPage extends StatelessWidget {
  const RecordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Last Prediction Window (40 frames)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
        const SizedBox(height: 24),

        Consumer<HomeProvider>(
          builder: (context, provider, child) {
            final window = provider.lastTriggeredWindow;

            if (window.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.waves,
                      size: 64,
                      color: Color(0xFFE5E7EB),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Waiting for trigger...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Swing the racket to capture data',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              );
            }

            // Find Max G for scale info
            double maxG = 0;
            for (var f in window) {
              if (f.acc[0].abs() > maxG) maxG = f.acc[0].abs();
              if (f.acc[1].abs() > maxG) maxG = f.acc[1].abs();
              if (f.acc[2].abs() > maxG) maxG = f.acc[2].abs();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('Accelerometer', 'Max: ${maxG.toStringAsFixed(1)} G'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: _StaticWindowChart(
                    data: window,
                    minY: -16, // Fixed range to see clipping
                    maxY: 16,
                    horizontalInterval: 4,
                    pickX: (f) => f.acc[0],
                    pickY: (f) => f.acc[1],
                    pickZ: (f) => f.acc[2],
                  ),
                ),
                
                const SizedBox(height: 24),

                _buildSectionTitle('Gyroscope', 'Range: ±2000 dps'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: _StaticWindowChart(
                    data: window,
                    minY: -2000,
                    maxY: 2000,
                    horizontalInterval: 500,
                    pickX: (f) => f.gyro[0],
                    pickY: (f) => f.gyro[1],
                    pickZ: (f) => f.gyro[2],
                  ),
                ),
                const SizedBox(height: 20),
                const _LegendRow(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

class _StaticWindowChart extends StatelessWidget {
  const _StaticWindowChart({
    required this.data,
    required this.minY,
    required this.maxY,
    required this.horizontalInterval,
    required this.pickX,
    required this.pickY,
    required this.pickZ,
  });

  final List<IMUFrame> data;
  final double minY;
  final double maxY;
  final double horizontalInterval;
  final double Function(IMUFrame) pickX;
  final double Function(IMUFrame) pickY;
  final double Function(IMUFrame) pickZ;

  static const Color _cX = Color(0xFF2F80ED); // blue
  static const Color _cY = Color(0xFF00BFA6); // teal
  static const Color _cZ = Color(0xFFF59E0B); // orange (changed from green-teal for better visibility)

  @override
  Widget build(BuildContext context) {
    // Generate spots
    List<FlSpot> spotsX = [];
    List<FlSpot> spotsY = [];
    List<FlSpot> spotsZ = [];

    for (int i = 0; i < data.length; i++) {
        spotsX.add(FlSpot(i.toDouble(), pickX(data[i])));
        spotsY.add(FlSpot(i.toDouble(), pickY(data[i])));
        spotsZ.add(FlSpot(i.toDouble(), pickZ(data[i])));
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 39, // 40 frames (0-39)
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
            show: true, 
            drawVerticalLine: true,
            horizontalInterval: horizontalInterval,
        ),
        lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => Colors.blueGrey.withOpacity(0.8),
                getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((LineBarSpot touchedSpot) {
                        return LineTooltipItem(
                            '${touchedSpot.y.toStringAsFixed(1)}',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                    }).toList();
                }
            )
        ),
        borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true, 
                reservedSize: 40,
                interval: horizontalInterval,
                getTitlesWidget: (value, meta) {
                    return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey));
                }
            ),
          ),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          _line(spotsX, _cX),
          _line(spotsY, _cY),
          _line(spotsZ, _cZ),
        ],
      ),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: false,
      dotData: const FlDotData(show: false),
      barWidth: 2,
      color: color,
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: Color(0xFF2F80ED), text: 'X'),
        SizedBox(width: 16),
        _LegendItem(color: Color(0xFF00BFA6), text: 'Y'),
        SizedBox(width: 16),
        _LegendItem(color: Color(0xFFF59E0B), text: 'Z'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
          ),
        ),
      ],
    );
  }
}
