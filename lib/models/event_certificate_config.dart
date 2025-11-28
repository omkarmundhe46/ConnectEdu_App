class EventCertificateConfig {
  final int? id;
  final int eventId;
  final String templateType;
  final String? authorityName1;
  final String? signatureUrl1;
  final String? authorityName2;
  final String? signatureUrl2;
  // Add more if you support 4 signatures

  EventCertificateConfig({
    this.id,
    required this.eventId,
    required this.templateType,
    this.authorityName1,
    this.signatureUrl1,
    this.authorityName2,
    this.signatureUrl2,
  });

  factory EventCertificateConfig.fromJson(Map<String, dynamic> json) {
    return EventCertificateConfig(
      id: json['id'],
      eventId: json['eventId'],
      templateType: json['templateType'],
      authorityName1: json['authorityName1'],
      signatureUrl1: json['signatureUrl1'],
      authorityName2: json['authorityName2'],
      signatureUrl2: json['signatureUrl2'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'templateType': templateType,
      'authorityName1': authorityName1,
      'signatureUrl1': signatureUrl1,
      'authorityName2': authorityName2,
      'signatureUrl2': signatureUrl2,
    };
  }
}