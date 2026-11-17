final class UserProfile {
  UserProfile({
    required this.userId,
    required String displayName,
    required this.email,
    required this.createdAt,
  }) : displayName = displayName.trim() {
    if (userId.trim().isEmpty ||
        this.displayName.runes.length < 2 ||
        this.displayName.runes.length > 80 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      throw ArgumentError('Perfil inválido');
    }
  }
  final String userId;
  final String displayName;
  final String email;
  final DateTime createdAt;
}
