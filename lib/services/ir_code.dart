class IrCode {
  final String action;
  final int frequency;
  final List<int> pattern;

  const IrCode({
    required this.action,
    required this.frequency,
    required this.pattern,
  });

  factory IrCode.fromJson(Map<String, dynamic> json) => IrCode(
    action: json['action'],
    frequency: json['frequency'],
    pattern: List<int>.from(json['pattern']),
  );

  Map<String, dynamic> toJson() => {
    'action': action,
    'frequency': frequency,
    'pattern': pattern,
  };
}
