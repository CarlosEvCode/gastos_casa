class UserModel {
  final String uid;
  final String email;
  final String role; // 'admin' or 'viewer'

  UserModel({required this.uid, required this.email, required this.role});

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      email: data['email'] ?? '',
      role: data['role'] ?? 'viewer',
    );
  }

  Map<String, dynamic> toMap() {
    return {'email': email, 'role': role};
  }

  bool get isAdmin => role == 'admin';
  bool get isViewer => role == 'viewer';
}
