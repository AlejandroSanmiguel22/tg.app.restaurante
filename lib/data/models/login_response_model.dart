class LoginResponseModel {
  final String token;
  final UserModel user;
  final String message;

  LoginResponseModel({required this.token, required this.user, required this.message});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      token: json['token'],
      user: UserModel.fromJson(json['user']),
      message: json['message'],
    );
  }
}

class UserModel {
  final String id;
  final String userName;
  final String role;
  final bool isActive;
  final bool isWaiter;

  UserModel({required this.id, required this.userName, required this.role, required this.isActive, required this.isWaiter});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      userName: json['userName'],
      role: json['role'],
      isActive: json['isActive'],
      isWaiter: json['isWaiter'],
    );
  }
} 