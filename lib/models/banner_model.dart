class BannerModel {
  final int id;
  final String title;
  final String imageUrl;
  final String? linkUrl;
  final int? clubId;
  final bool active;

  BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.linkUrl,
    this.clubId,
    required this.active,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'],
      title: json['title'],
      imageUrl: json['imageUrl'],
      linkUrl: json['linkUrl'],
      clubId: json['clubId'],
      active: json['active'] ?? true,
    );
  }
}