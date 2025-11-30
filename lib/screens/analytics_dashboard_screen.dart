import 'package:connectedu_app/models/analytics_models.dart';
import 'package:connectedu_app/models/user.dart';
import 'package:connectedu_app/repositories/analytics_repository.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math'; // For generating random colors

class AnalyticsDashboardScreen extends StatefulWidget {
  final User user;
  const AnalyticsDashboardScreen({super.key, required this.user});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  late Future<AnalyticsData> _analyticsFuture;
  int _touchedIndex = -1; // For Pie Chart animation

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final repo = context.read<AnalyticsRepository>();
    if (widget.user.role == 'COLLEGE_ADMIN') {
      _analyticsFuture = repo.getGlobalAnalytics();
    } else {
      _analyticsFuture = repo.getClubAnalytics(widget.user.managedClubId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Slight grey background for contrast
      appBar: AppBar(
        title: const Text("Analytics Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<AnalyticsData>(
        future: _analyticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final data = snapshot.data!;
          final isCollegeAdmin = widget.user.role == 'COLLEGE_ADMIN';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. STAT CARDS ROW
                Row(
                  children: [
                    if (isCollegeAdmin) ...[
                      _buildStatCard("Total Events", data.totalEvents.toString(), Colors.blue, Icons.event),
                      const SizedBox(width: 12),
                      _buildStatCard("Participants", data.totalParticipants.toString(), Colors.orange, Icons.people),
                      const SizedBox(width: 12),
                    ],
                    _buildStatCard("Revenue", "₹${data.totalRevenue.toStringAsFixed(0)}", Colors.green, Icons.attach_money),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. BAR CHART CARD
                _buildSectionTitle(isCollegeAdmin ? "Monthly Events Overview" : "Recent Event Performance"),
                const SizedBox(height: 12),
                _buildBarChartCard(data.eventsByMonth),

                // 3. DONUT CHART CARD (Only for College Admin)
                if (isCollegeAdmin && data.participationByClub.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  _buildSectionTitle("Participation by Club"),
                  const SizedBox(height: 12),
                  _buildDonutChartCard(data.participationByClub),
                ],
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard(List<ChartData> data) {
    if (data.isEmpty) return const SizedBox(height: 200, child: Center(child: Text("No data available")));

    return Container(
      height: 320,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.map((e) => e.value).reduce(max) * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.blueAccent,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${data[group.x.toInt()].label}\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  children: <TextSpan>[
                    TextSpan(
                      text: (rod.toY - 1).toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.length) {
                    String label = data[value.toInt()].label;
                    // Shorten label if too long
                    if (label.length > 6) label = '${label.substring(0, 6)}..';
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Transform.rotate(
                        angle: -0.5, // Rotate labels for better fit
                        child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 40, // Space for rotated labels
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
          ),
          barGroups: data.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  gradient: const LinearGradient(
                    colors: [Colors.lightBlueAccent, Colors.blue],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDonutChartCard(List<ChartData> data) {
    // Generate distinct colors for the chart
    final List<Color> colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.pink
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2, // Space between slices
                centerSpaceRadius: 40, // DONUT HOLE
                sections: data.asMap().entries.map((entry) {
                  final isTouched = entry.key == _touchedIndex;
                  final fontSize = isTouched ? 18.0 : 12.0;
                  final radius = isTouched ? 60.0 : 50.0;
                  final color = colors[entry.key % colors.length];

                  return PieChartSectionData(
                    color: color,
                    value: entry.value.value,
                    title: '${entry.value.value.toInt()}',
                    radius: radius,
                    titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // --- LEGEND ---
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: data.asMap().entries.map((entry) {
              final color = colors[entry.key % colors.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(
                    entry.value.label,
                    style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: entry.key == _touchedIndex ? FontWeight.bold : FontWeight.normal
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}