class FarmModel {
  const FarmModel({
    required this.id,
    required this.ownerUserId,
    required this.name,
    this.phone,
    this.email,
    this.location,
    this.region,
    this.country,
    this.farmType,
    this.registrationNo,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUserId;
  final String name;
  final String? phone;
  final String? email;
  final String? location;
  final String? region;
  final String? country;
  final String? farmType;
  final String? registrationNo;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory FarmModel.fromJson(Map<String, dynamic> json) {
    return FarmModel(
      id: json['id'] as String,
      ownerUserId: json['ownerUserId'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      location: json['location'] as String?,
      region: json['region'] as String?,
      country: json['country'] as String?,
      farmType: json['farmType'] as String?,
      registrationNo: json['registrationNo'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
