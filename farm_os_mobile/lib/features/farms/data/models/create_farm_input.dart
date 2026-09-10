/// Matches the backend's CreateFarmDto exactly (farms/dto/create-farm.dto.ts):
/// name is required (min length 2), everything else is optional. Do not add
/// fields the backend doesn't accept -- CreateFarmDto has no others.
class CreateFarmInput {
  const CreateFarmInput({
    required this.name,
    this.phone,
    this.email,
    this.location,
    this.region,
    this.country,
    this.farmType,
    this.registrationNo,
  });

  final String name;
  final String? phone;
  final String? email;
  final String? location;
  final String? region;
  final String? country;
  final String? farmType;
  final String? registrationNo;

  /// Only includes fields that were actually provided -- avoids sending
  /// `"phone": null` for optional fields the farmer left blank, keeping the
  /// request body minimal and matching what @IsOptional fields expect.
  Map<String, dynamic> toJson() => {
        'name': name,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (location != null && location!.isNotEmpty) 'location': location,
        if (region != null && region!.isNotEmpty) 'region': region,
        if (country != null && country!.isNotEmpty) 'country': country,
        if (farmType != null && farmType!.isNotEmpty) 'farmType': farmType,
        if (registrationNo != null && registrationNo!.isNotEmpty)
          'registrationNo': registrationNo,
      };
}
