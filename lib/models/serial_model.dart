class RegisteredCompany {
  final int id;
  final String name;
  final String token;
  final String tokenExpiry;
  final String baseurl;
  final String adminurl;
  final String licenseExpiry;
  final List<dynamic> permissions;
  final String roleName;
  final int userId;
  final String userEmail;
  final String userName;
  final bool isAdmin;
  final bool isActive;
  final int allowedUsersPerCompany;

  RegisteredCompany({
    required this.id,
    required this.name,
    required this.token,
    required this.allowedUsersPerCompany, // ✅ NEW FIELD
    required this.tokenExpiry,
    required this.baseurl,
    required this.adminurl,
    required this.licenseExpiry,
    required this.permissions,
    required this.roleName,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.isAdmin,
    required this.isActive,
  });

  factory RegisteredCompany.fromJson(Map<String, dynamic> json) {
    return RegisteredCompany(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      token: json['token'] ?? '',
      tokenExpiry: json['token_expiry'] ?? '',
      baseurl: json['baseurl'] ?? '',
      adminurl: json['adminurl'] ?? '',
      licenseExpiry: json['license_expiry'] ?? '',
      permissions: json['permissions'] ?? [],
      roleName: json['role_name'] ?? '',
      userId: json['user_id'] ?? 0,
      userEmail: json['user_email'] ?? '',
      userName: json['user_name'] ?? '',
      isAdmin: json['is_admin'] ?? false,
      isActive: json['is_active'] ?? false,
      allowedUsersPerCompany: json['allowed_users_per_company'] ?? 0,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'token': token,
      'token_expiry': tokenExpiry,
      'baseurl': baseurl,
      'adminurl': adminurl,
      'license_expiry': licenseExpiry,
      'permissions': permissions,
      'role_name': roleName,
      'user_id': userId,
      'user_email': userEmail,
      'user_name': userName,
      'is_admin': isAdmin,
      'is_active': isActive,
    };
  }

}