class UserModel {
  final int id;
  final String nameArabic;
  final String nameEnglish;
  final String phone;
  final String? email;
  final String? governorate;
  final String? evaluation;
  final double? balance;
  final String? address;
  final String userType;

  UserModel({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.phone,
    this.email,
    this.governorate,
    this.evaluation,
    this.balance,
    this.address,
    required this.userType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['userId'] ?? 0,
      nameArabic: json['nameArabic'] ?? '',
      nameEnglish: json['nameEnglish'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      governorate: json['governorate'],
      evaluation: json['evaluation'],
      balance: (json['balance'] as num?)?.toDouble(),
      address: json['address'],
      userType: json['userType'] ?? 'customer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'nameArabic': nameArabic,
      'nameEnglish': nameEnglish,
      'phone': phone,
      'email': email,
      'governorate': governorate,
      'evaluation': evaluation,
      'balance': balance,
      'address': address,
      'userType': userType,
    };
  }
}
