class Club {
  final int id;
  final String name;
  final String description;
  final int adminId;

  Club({
    required this.id,
    required this.name,
    required this.description,
    required this.adminId,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      adminId: json['adminId'],
    );
  }
}

