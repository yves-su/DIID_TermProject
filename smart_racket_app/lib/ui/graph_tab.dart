import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import '../models/imu_frame.dart';

class GraphTab extends StatelessWidget {
  const GraphTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        final frames = provider.recentFrames;
        
        // Prepare data for Acceleration
        final accSpotsX = _getSpots(frames, (f) => f.acc[0]);
        final accSpotsY = _getSpots(frames, (f) => f.acc[1]);
        final accSpotsZ = _getSpots(frames, (f) => f.acc[2]);

        // Prepare data for Gyroscope
        final gyroSpotsX = _getSpots(frames, (f) => f.gyro[0]);
        final gyroSpotsY = _getSpots(frames, (f) => f.gyro[1]);
        final gyroSpotsZ = _getSpots(frames, (f) => f.gyro[2]);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text("Acceleration (G)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: _buildChart(accSpotsX, accSpotsY, accSpotsZ, -4, 4),
            ),
            const SizedBox(height: 24),
            const Text("Gyroscope (deg/s)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: _buildChart(gyroSpotsX, gyroSpotsY, gyroSpotsZ, -2000, 2000),
            ),
          ],
        );
      },
    );
  }

  List<FlSpot> _getSpots(List<IMUFrame> frames, double Function(IMUFrame) selector) {
    return frames.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), selector(e.value));
    }).toList();
  }

  Widget _buildChart(List<FlSpot> x, List<FlSpot> y, List<FlSpot> z, double min, double max) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          _line(x, Colors.red),
          _line(y, Colors.green),
          _line(z, Colors.blue),
        ],
        minY: min,
        maxY: max,
      ),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: false,
      color: color,
      dotData: FlDotData(show: false),
      barWidth: 2,
    );
  }
}
