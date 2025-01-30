class Serial {
  final int id;
  final String serialNo;
  final String token;
  final List<RegisteredCompany> registeredCompanies;

  Serial({
    required this.id,
    required this.serialNo,
    required this.token,
    required this.registeredCompanies,
  });

  factory Serial.fromJson(Map<String, dynamic> json) {
    return Serial(
      id: json['id'] ?? 0,
      serialNo: json['serial_no'] ?? '',
      token: json['token'] ?? '',
      registeredCompanies: (json['registered_companies'] as List?)
          ?.map((company) => RegisteredCompany.fromJson(company))
          .toList() ??
          [],
    );
  }

  /// ✅ Convert Serial object to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serial_no': serialNo,
      'token': token,
      'registered_companies': registeredCompanies.map((e) => e.toJson()).toList(),
    };
  }
}

class RegisteredCompany {
  final int id;
  final String name;
  final String token;

  RegisteredCompany({
    required this.id,
    required this.name,
    required this.token,
  });

  factory RegisteredCompany.fromJson(Map<String, dynamic> json) {
    return RegisteredCompany(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      token: json['token'] ?? '',
    );
  }

  /// ✅ Convert RegisteredCompany object to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'token': token,
    };
  }
}
