class SmartTvState {
  bool isPowerOn;
  int currentValue;
  bool isMuted;
  String currentInput;
  String connectionStatus;

  SmartTvState({
    required this.isPowerOn,
    required this.currentValue,
    required this.isMuted,
    required this.currentInput,
    required this.connectionStatus,
  });
}
