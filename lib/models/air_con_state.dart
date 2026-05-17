class AirConState {
  bool isPowerOn;
  double targetTemperature;
  double roomTemperature;
  String fanSpeed;
  String operationMode;
  bool isSwingOn;

  AirConState({
    required this.isPowerOn,
    required this.targetTemperature,
    required this.roomTemperature,
    required this.fanSpeed,
    required this.operationMode,
    required this.isSwingOn,
  });
}
