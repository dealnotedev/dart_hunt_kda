class Constants {
  static final profileId = _profileId();

  static int? _profileId() {
    const value = String.fromEnvironment('profile_id');
    return value.isNotEmpty ? int.parse(value) : null;
  }
}
