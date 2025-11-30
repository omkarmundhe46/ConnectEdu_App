class ChartData {
  final String label;
  final double value;

  ChartData({required this.label, required this.value});

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      label: json['label'] ?? '',
      value: (json['value'] as num).toDouble(),
    );
  }
}

class AnalyticsData {
  final List<ChartData> eventsByMonth;
  final List<ChartData> participationByClub;
  final int totalEvents;
  final int totalParticipants;
  final double totalRevenue;

  AnalyticsData({
    required this.eventsByMonth,
    required this.participationByClub,
    required this.totalEvents,
    required this.totalParticipants,
    required this.totalRevenue,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    var eventsList = json['eventsByMonth'] as List? ?? [];
    var clubList = json['participationByClub'] as List? ?? [];

    return AnalyticsData(
      eventsByMonth: eventsList.map((i) => ChartData.fromJson(i)).toList(),
      participationByClub: clubList.map((i) => ChartData.fromJson(i)).toList(),
      totalEvents: json['totalEvents'] ?? 0,
      totalParticipants: json['totalParticipants'] ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}