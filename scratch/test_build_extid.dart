import 'dart:convert';

void main() {
  String _buildTelegramExtId(String rawExtId, String? username, String? accessHash) {
    if (rawExtId.isEmpty) return rawExtId;
    
    bool isJson = false;
    Map<String, dynamic> existingJson = {};
    try {
      final decoded = jsonDecode(rawExtId);
      if (decoded is Map) {
        isJson = true;
        existingJson = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    final extIdMap = <String, dynamic>{};
    if (isJson) {
      extIdMap.addAll(existingJson);
      if (username != null && username.isNotEmpty) extIdMap['Username'] = username;
      if (accessHash != null && accessHash.isNotEmpty) extIdMap['AccessHash'] = accessHash;
    } else {
      extIdMap['ExtId'] = rawExtId;
      if (username != null && username.isNotEmpty) extIdMap['Username'] = username;
      if (accessHash != null && accessHash.isNotEmpty) extIdMap['AccessHash'] = accessHash;
    }
    return jsonEncode(extIdMap);
  }

  print("Test 1 (Raw ID): " + _buildTelegramExtId("6912143766", null, null));
  print("Test 2 (JSON String from backend): " + _buildTelegramExtId('{"ExtId":"6912143766","Username":"foo"}', null, null));
  print("Test 3 (JSON String with updates): " + _buildTelegramExtId('{"ExtId":"6912143766"}', "bar", "hash123"));
}
