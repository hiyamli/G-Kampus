class ProfileEditResult {
  const ProfileEditResult({
    required this.bio,
    required this.avatarIndex,
    this.avatarPath,
  });

  final String bio;
  final int avatarIndex;
  final String? avatarPath;
}
