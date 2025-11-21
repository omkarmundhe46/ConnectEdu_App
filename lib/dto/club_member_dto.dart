class ClubMemberDto {
  final int id;
  final int userId;
  final int clubId;
  final String role;
  final String joinedAt;
  final String userName;

  ClubMemberDto({
    required this.id,
    required this.userId,
    required this.clubId,
    required this.role,
    required this.joinedAt,
    required this.userName,
  });

  factory ClubMemberDto.fromJson(Map<String, dynamic> json) {
    return ClubMemberDto(
      id: json['id'],
      userId: json['userId'],
      clubId: json['clubId'],
      role: json['role'],
      joinedAt: json['joinedAt'] ?? '',
      userName: json['userName'] ?? 'Unknown User',
    );
  }
}