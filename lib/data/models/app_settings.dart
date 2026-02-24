class AppSettings {
  const AppSettings({
    required this.darkMode,
    required this.periodReminders,
    required this.ovulationReminders,
    required this.dailyLogReminder,
    required this.pinEnabled,
    required this.pinCode,
    required this.biometricEnabled,
  });

  final bool darkMode;
  final bool periodReminders;
  final bool ovulationReminders;
  final bool dailyLogReminder;
  final bool pinEnabled;
  final String pinCode;
  final bool biometricEnabled;

  factory AppSettings.defaults() {
    return const AppSettings(
      darkMode: false,
      periodReminders: true,
      ovulationReminders: true,
      dailyLogReminder: false,
      pinEnabled: false,
      pinCode: '',
      biometricEnabled: false,
    );
  }

  AppSettings copyWith({
    bool? darkMode,
    bool? periodReminders,
    bool? ovulationReminders,
    bool? dailyLogReminder,
    bool? pinEnabled,
    String? pinCode,
    bool? biometricEnabled,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      periodReminders: periodReminders ?? this.periodReminders,
      ovulationReminders: ovulationReminders ?? this.ovulationReminders,
      dailyLogReminder: dailyLogReminder ?? this.dailyLogReminder,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      pinCode: pinCode ?? this.pinCode,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'darkMode': darkMode,
      'periodReminders': periodReminders,
      'ovulationReminders': ovulationReminders,
      'dailyLogReminder': dailyLogReminder,
      'pinEnabled': pinEnabled,
      'pinCode': pinCode,
      'biometricEnabled': biometricEnabled,
    };
  }

  factory AppSettings.fromMap(Map<dynamic, dynamic> map) {
    return AppSettings(
      darkMode: map['darkMode'] as bool? ?? false,
      periodReminders: map['periodReminders'] as bool? ?? true,
      ovulationReminders: map['ovulationReminders'] as bool? ?? true,
      dailyLogReminder: map['dailyLogReminder'] as bool? ?? false,
      pinEnabled: map['pinEnabled'] as bool? ?? false,
      pinCode: map['pinCode'] as String? ?? '',
      biometricEnabled: map['biometricEnabled'] as bool? ?? false,
    );
  }
}
