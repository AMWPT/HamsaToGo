class UserModel {
  final String id;
  final String phone;
  final String fullName;
  final String? fcmToken;
  final String? lang;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.phone,
    required this.fullName,
    this.fcmToken,
    this.lang,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        phone: (json['phone'] as String?) ?? '',
        fullName: json['full_name'] as String,
        fcmToken: json['fcm_token'] as String?,
        lang: json['lang'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'full_name': fullName,
        if (fcmToken != null) 'fcm_token': fcmToken,
        if (lang != null) 'lang': lang,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}
