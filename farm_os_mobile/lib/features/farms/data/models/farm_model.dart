/// Mirrors the Farm object as actually returned by the Stage 3 backend
/// (FarmsService.create/findAllForUser/findOne/update -- plain Prisma `Farm`
/// rows, no nested `owner` object is included in any current response).
///
/// Backend fields (prisma/schema.prisma `Farm` model + farms.controller.ts):
/// id, ownerUserId, name, phone, email, location, region, country,
/// farmType, registrationNo, createdAt, updatedAt, deletedAt, version.
///
/// `deletedAt` is included for completeness (soft-delete field) but the
/// backend already filters deleted farms out of every response, so it
/// should always be null here in practice.
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
    this.deletedAt,
    required this.version,
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
  final DateTime? deletedAt;
  final int version;

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
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt'] as String) : null,
      version: json['version'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerUserId': ownerUserId,
        'name': name,
        'phone': phone,
        'email': email,
        'location': location,
        'region': region,
        'country': country,
        'farmType': farmType,
        'registrationNo': registrationNo,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'version': version,
      };

  /// A short line of identifying info for list/card UI, e.g. "Kabarak, Nakuru".
  /// Falls back gracefully when location fields are missing rather than
  /// showing "null, null".
  String get locationSummary {
    final parts = [location, region, country].where((p) => p != null && p.isNotEmpty);
    return parts.isEmpty ? '' : parts.join(', ');
  }
}
