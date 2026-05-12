// lib/models/user_model.dart

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final List<String> favoriteRecipeIds;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.favoriteRecipeIds = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      favoriteRecipeIds: List<String>.from(map['favoriteRecipeIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'favoriteRecipeIds': favoriteRecipeIds,
    };
  }
}
