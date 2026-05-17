class HomeEnvironment {
  final String homeId;
  final String userId;
  String homeName;
  List<String> roomIds;

  HomeEnvironment({
    required this.homeId,
    required this.userId,
    required this.homeName,
    required this.roomIds,
  });
}

class RoomData {
  final String roomId;
  final String homeId;
  String roomName;
  String iconType;

  RoomData({
    required this.roomId,
    required this.homeId,
    required this.roomName,
    required this.iconType,
  });
}
