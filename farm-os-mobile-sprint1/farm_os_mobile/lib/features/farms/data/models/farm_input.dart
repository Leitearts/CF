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

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      if (_normalized(phone) != null) 'phone': _normalized(phone),
      if (_normalized(email) != null) 'email': _normalized(email),
      if (_normalized(location) != null) 'location': _normalized(location),
      if (_normalized(region) != null) 'region': _normalized(region),
      if (_normalized(country) != null) 'country': _normalized(country),
      if (_normalized(farmType) != null) 'farmType': _normalized(farmType),
      if (_normalized(registrationNo) != null) 'registrationNo': _normalized(registrationNo),
    };
  }
}

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

  Map<String, dynamic> toJson() {
    return {
      if (_normalized(name) != null) 'name': _normalized(name),
      if (_normalized(phone) != null) 'phone': _normalized(phone),
      if (_normalized(email) != null) 'email': _normalized(email),
      if (_normalized(location) != null) 'location': _normalized(location),
      if (_normalized(region) != null) 'region': _normalized(region),
      if (_normalized(country) != null) 'country': _normalized(country),
      if (_normalized(farmType) != null) 'farmType': _normalized(farmType),
      if (_normalized(registrationNo) != null) 'registrationNo': _normalized(registrationNo),
    };
  }
}

String? _normalized(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
