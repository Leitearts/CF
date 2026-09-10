/// Matches the backend's UpdateFarmDto (farms/dto/update-farm.dto.ts =
/// PartialType(CreateFarmDto)): the same fields as CreateFarmInput, all
/// optional. Deliberately does NOT expose `id`, `ownerUserId`, `createdAt`,
/// or `version` for editing -- those are backend-managed/immutable from the
/// client's perspective (per section 7: "do not expose immutable fields").
class UpdateFarmInput {
  const UpdateFarmInput({
    this.name,
    this.phone,
    this.email,
    this.location,
    this.region,
    this.country,
    this.farmType,
    this.registrationNo,
  });

  final String? name;
  final String? phone;
  final String? email;
  final String? location;
  final String? region;
  final String? country;
  final String? farmType;
  final String? registrationNo;

  /// Only sends fields that changed/are set -- PUT with a partial body is
  /// exactly what PartialType(CreateFarmDto) on the backend expects.
  Map<String, dynamic> toJson() => {
        if (name != null && name!.isNotEmpty) 'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (location != null) 'location': location,
        if (region != null) 'region': region,
        if (country != null) 'country': country,
        if (farmType != null) 'farmType': farmType,
        if (registrationNo != null) 'registrationNo': registrationNo,
      };
}
