class AppSettings {
  const AppSettings({
    this.opacity = 0.94,
    this.fontScale = 1.0,
    this.windowWidth = 760,
    this.windowHeight = 600,
    this.alwaysOnTop = true,
    this.mousePassthrough = false,
    this.remindersEnabled = true,
    this.launchAtStartup = false,
  });

  final double opacity;
  final double fontScale;
  final double windowWidth;
  final double windowHeight;
  final bool alwaysOnTop;
  final bool mousePassthrough;
  final bool remindersEnabled;
  final bool launchAtStartup;

  AppSettings copyWith({
    double? opacity,
    double? fontScale,
    double? windowWidth,
    double? windowHeight,
    bool? alwaysOnTop,
    bool? mousePassthrough,
    bool? remindersEnabled,
    bool? launchAtStartup,
  }) => AppSettings(
    opacity: opacity ?? this.opacity,
    fontScale: fontScale ?? this.fontScale,
    windowWidth: windowWidth ?? this.windowWidth,
    windowHeight: windowHeight ?? this.windowHeight,
    alwaysOnTop: alwaysOnTop ?? this.alwaysOnTop,
    mousePassthrough: mousePassthrough ?? this.mousePassthrough,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    launchAtStartup: launchAtStartup ?? this.launchAtStartup,
  );

  factory AppSettings.fromJson(Map<String, dynamic>? json) => AppSettings(
    opacity: (json?['opacity'] as num?)?.toDouble() ?? 0.94,
    fontScale: (json?['fontScale'] as num?)?.toDouble() ?? 1.0,
    windowWidth: (json?['windowWidth'] as num?)?.toDouble() ?? 760,
    windowHeight: (json?['windowHeight'] as num?)?.toDouble() ?? 600,
    alwaysOnTop: json?['alwaysOnTop'] as bool? ?? true,
    mousePassthrough: json?['mousePassthrough'] as bool? ?? false,
    remindersEnabled: json?['remindersEnabled'] as bool? ?? true,
    launchAtStartup: json?['launchAtStartup'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'opacity': opacity,
    'fontScale': fontScale,
    'windowWidth': windowWidth,
    'windowHeight': windowHeight,
    'alwaysOnTop': alwaysOnTop,
    'mousePassthrough': mousePassthrough,
    'remindersEnabled': remindersEnabled,
    'launchAtStartup': launchAtStartup,
  };
}
