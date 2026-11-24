class SettingsState {
  final int hijriOffset;
  final String languageCode;
  final String themeMode;
  final bool notificationsEnabled;
  final bool adhanEnabled;
  final bool vibrationEnabled;
  final bool use24Hour;
  final bool darkHeader;
  final bool isLoaded;

  const SettingsState({
    this.hijriOffset          = 0,
    this.languageCode         = 'en',
    this.themeMode            = 'dark',
    this.notificationsEnabled = true,
    this.adhanEnabled         = true,
    this.vibrationEnabled     = true,
    this.use24Hour            = false,
    this.darkHeader           = true,
    this.isLoaded             = false,
  });

  SettingsState copyWith({
    int? hijriOffset,
    String? languageCode,
    String? themeMode,
    bool? notificationsEnabled,
    bool? adhanEnabled,
    bool? vibrationEnabled,
    bool? use24Hour,
    bool? darkHeader,
    bool? isLoaded,
  }) {
    return SettingsState(
      hijriOffset:          hijriOffset          ?? this.hijriOffset,
      languageCode:         languageCode         ?? this.languageCode,
      themeMode:            themeMode            ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      adhanEnabled:         adhanEnabled         ?? this.adhanEnabled,
      vibrationEnabled:     vibrationEnabled     ?? this.vibrationEnabled,
      use24Hour:            use24Hour            ?? this.use24Hour,
      darkHeader:           darkHeader           ?? this.darkHeader,
      isLoaded:             isLoaded             ?? this.isLoaded,
    );
  }
}