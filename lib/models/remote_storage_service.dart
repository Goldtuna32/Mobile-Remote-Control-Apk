import 'dart:convert';
import 'package:remote_control/models/user_remote.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteStorageService {
  static const String _storageKey = 'user_added_remotes';

  Future<void> saveRemotes(List<UserRemote> remotes) async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> jsonList = remotes
        .map((remote) => jsonEncode(remote.toMap()))
        .toList();

    await prefs.setStringList(_storageKey, jsonList);
  }

  Future<List<UserRemote>> getRemotes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList(_storageKey);

    if (jsonList == null) return [];

    return jsonList
        .map((item) => UserRemote.fromMap(jsonDecode(item)))
        .toList();
  }
}
