class CertificateTemplate {
  final String name; // e.g. "CODING_CLUB_TEMP1"
  final String displayName; // e.g. "Coding Club Modern"
  final String previewUrl; // URL to the image

  CertificateTemplate({
    required this.name,
    required this.displayName,
    required this.previewUrl,
  });

  factory CertificateTemplate.fromJson(Map<String, dynamic> json) {
    return CertificateTemplate(
      name: json['name'] ?? '', // Enum constant name (used as ID)
      displayName: json['displayName'] ?? '',
      previewUrl: json['previewUrl'] ?? '',
    );
  }
}