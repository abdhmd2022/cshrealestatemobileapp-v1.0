class RegisteredCompany {
  final int id;
  final String name;
  final String token;
  final String baseurl;
  final String adminurl;
  final String license_expiry;

  RegisteredCompany({
    required this.id,
    required this.name,
    required this.token,
    required this.baseurl,
    required this.adminurl,
    required this.license_expiry,
  });

  factory RegisteredCompany.fromJson(Map<String, dynamic> json) {
    return RegisteredCompany(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      token: json['token'] ?? '',
      baseurl: json['baseurl'] ?? '',
      adminurl: json['adminurl'] ?? '',
      license_expiry: json['license_expiry'] ?? '',
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
