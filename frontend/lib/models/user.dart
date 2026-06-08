class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? fcmToken;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.fcmToken,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String,
        fcmToken: json['fcm_token'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        if (fcmToken != null) 'fcm_token': fcmToken,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}
