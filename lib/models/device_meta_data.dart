class DeviceMetaData {
  final String deviceId;
  final String homeId;
  String roomId;
  String customName;

  DeviceMetaData({
    required this.deviceId,
    required this.homeId,
    required this.roomId,
    required this.customName,
  });
}
