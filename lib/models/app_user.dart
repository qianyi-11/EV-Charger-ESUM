enum AppRole {
  user,
  admin;

  String get label => this == AppRole.admin ? 'Admin' : 'User';

  String get firestoreValue => name;

  static AppRole fromString(String? value) {
    if (value == 'admin') return AppRole.admin;
    return AppRole.user;
  }
}

enum LoginPortal {
  customer,
  admin;

  String get label => this == LoginPortal.admin ? 'Admin' : 'Customer';
}

class AppUserProfile {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final AppRole role;

  const AppUserProfile({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.role,
  });

  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isEmpty ? email : full;
  }

  factory AppUserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    return AppUserProfile(
      uid: uid,
      email: data['email'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: AppRole.fromString(data['role'] as String?),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'role': role.firestoreValue,
      };
}
