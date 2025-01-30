class Serial {
  final int id;
  final String serialNo;
  final String userToken;  // ✅ Store the user token
  final int userId;  // ✅ Store the user id

  final List<RegisteredCompany> registeredCompanies;

  Serial({
    required this.id,
    required this.serialNo,
    required this.userToken,  // ✅ Ensure token is stored
    required this.userId,  // ✅ Ensure id is stored

    required this.registeredCompanies,
  });

  factory Serial.fromJson(Map<String, dynamic> json, {required String userToken, required int userId}) {
    return Serial(
      id: json['id'] ?? 0,
      serialNo: json['serial_no'] ?? '',
      userToken: json['user_token'] ?? userToken,  // ✅ Ensure token is assigned
      userId: json['user_id'] ?? userId,  // ✅ Ensure id is assigned

      registeredCompanies: (json['registered_companies'] as List?)
          ?.map((company) => RegisteredCompany.fromJson(company))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serial_no': serialNo,
      'user_token': userToken,  // ✅ Ensure token is saved
      'user_id': userId,  // ✅ Ensure id is saved
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
