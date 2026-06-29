import 'dart:convert';
import 'dart:io';

/// Diagnostic script to analyze Telegram send message flow.
/// Compares what our app sends vs what nobox.ai web sends.
void main() async {
  final token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImN0eSI6IkpXVCJ9.eyJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9uYW1lIjoiYWtiYXJyaXlhbmRAZ21haWwuY29tIiwiaHR0cDovL3NjaGVtYXMueG1sc29hcC5vcmcvd3MvMjAwNS8wNS9pZGVudGl0eS9jbGFpbXMvbmFtZWlkZW50aWZpZXIiOiIxOTIwIiwiZXhwIjoxNzgyNTMzMDA2LCJpc3MiOiJodHRwczovL2lkLm5vYm94LmFpLyIsImF1ZCI6Imh0dHBzOi8vaWQubm9ib3guYWkvIn0.OxkRc8vCjHSHzFrunyvJOoki9IPetP_HSbq-ppeg3Bk";

  final headers = {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  // Step 1: Get a Telegram room from Chatrooms/List
  print("=== Step 1: Find Telegram rooms (ChId=2) ===");
  final listPayload = {
    'Take': 10,
    'Skip': 0,
    'Sort': ['TimeMsg DESC'],
    'IncludeColumns': ['Id', 'CtId', 'CtRealId', 'CtRealNm', 'ChId', 'AccId', 'AccNm', 'LinkTmp', 'CtTmp'],
    'ColumnSelection': 1,
    'EqualityFilter': {
      'ChId': [2]  // Telegram only
    },
  };

  final listReq = await HttpClient().postUrl(Uri.parse('https://id.nobox.ai/Services/Chat/Chatrooms/List'));
  listReq.headers.set('Authorization', 'Bearer $token');
  listReq.headers.set('Content-Type', 'application/json');
  listReq.write(jsonEncode(listPayload));
  final listResp = await listReq.close();
  final listBody = await listResp.transform(utf8.decoder).join();
  final listData = jsonDecode(listBody);
  
  final entities = listData['Entities'] ?? listData['Values'] ?? [];
  if (entities.isEmpty) {
    print("No Telegram rooms found!");
    return;
  }

  // Pick the first Telegram room
  final room = entities[0];
  final roomId = room['Id']?.toString() ?? '';
  final ctId = room['CtId']?.toString() ?? '';
  final ctRealId = room['CtRealId']?.toString() ?? '';
  final accId = room['AccId']?.toString() ?? '';
  
  print("Room: Id=$roomId, CtId=$ctId, CtRealId=$ctRealId, AccId=$accId");
  print("Name: ${room['CtRealNm'] ?? room['CtTmp']}");
  print("Full room data: ${jsonEncode(room)}");
  print("");

  // Step 2: Retrieve the contact's ExtId via Chatlinkcontacts/Retrieve
  print("=== Step 2: Retrieve contact ExtId (CtId=$ctId) ===");
  final retrieveReq = await HttpClient().postUrl(Uri.parse('https://id.nobox.ai/Services/Chat/Chatlinkcontacts/Retrieve'));
  retrieveReq.headers.set('Authorization', 'Bearer $token');
  retrieveReq.headers.set('Content-Type', 'application/json');
  retrieveReq.write(jsonEncode({'EntityId': ctId}));
  final retrieveResp = await retrieveReq.close();
  final retrieveBody = await retrieveResp.transform(utf8.decoder).join();
  final retrieveData = jsonDecode(retrieveBody);

  final entity = retrieveData['Entity'];
  if (entity != null) {
    final idExt = entity['IdExt']?.toString() ?? '';
    final extraRaw = entity['Extra'];
    print("Entity.IdExt = $idExt");
    print("Entity.Extra (raw) = $extraRaw");
    
    if (extraRaw != null) {
      try {
        final extraMap = extraRaw is String ? jsonDecode(extraRaw) : extraRaw;
        print("Entity.Extra (parsed) = ${jsonEncode(extraMap)}");
        print("  ExtId = ${extraMap['ExtId']}");
        print("  Username = ${extraMap['Username']}");
        print("  AccessHash = ${extraMap['AccessHash']}");
      } catch (e) {
        print("Failed to parse Extra: $e");
      }
    }
    
    // Show ALL entity keys for reference
    print("Entity all keys: ${(entity as Map).keys.toList()}");
    print("Entity full: ${jsonEncode(entity)}");
  }
  print("");

  // Step 3: Show what OUR app would send
  String extId = '';
  String? telegramUsername;
  String? telegramAccessHash;
  
  if (entity != null) {
    final extraRaw = entity['Extra'];
    if (extraRaw != null) {
      try {
        final extraMap = extraRaw is String ? jsonDecode(extraRaw) : extraRaw;
        if (extraMap is Map) {
          extId = extraMap['ExtId']?.toString() ?? '';
          telegramUsername = extraMap['Username']?.toString();
          telegramAccessHash = extraMap['AccessHash']?.toString();
        }
      } catch (_) {}
    }
    final idExt = entity['IdExt']?.toString() ?? '';
    if (idExt.isNotEmpty) extId = idExt;  // For Telegram, prefer IdExt
  }
  
  // Build the ExtId JSON (what our app does)
  final extIdMap = <String, dynamic>{'ExtId': extId};
  if (telegramUsername != null && telegramUsername.isNotEmpty) extIdMap['Username'] = telegramUsername;
  if (telegramAccessHash != null && telegramAccessHash.isNotEmpty) extIdMap['AccessHash'] = telegramAccessHash;
  final finalExtId = jsonEncode(extIdMap);
  
  print("=== Step 3: What OUR APP sends ===");
  final ourPayload = {
    'Body': 'test_from_diagnostic',
    'BodyType': 1,
    'ExtId': finalExtId,
    'ChannelId': 2,
    'AccountIds': accId,
    'Attachment': '',
  };
  print("URL: https://id.nobox.ai/Inbox/Send?Id=$roomId");
  print("Payload: ${jsonEncode(ourPayload)}");
  print("");
  
  // Step 4: What the web probably sends (with LinkId)
  print("=== Step 4: What NOBOX.AI WEB probably sends ===");
  final webPayload = {
    'Body': 'test_from_diagnostic',
    'BodyType': 1,
    'ExtId': finalExtId,
    'ChannelId': 2,
    'AccountIds': accId,
    'LinkId': int.tryParse(ctId) ?? ctId,
    'Attachment': '',
  };
  print("URL: https://id.nobox.ai/Inbox/Send?Id=$roomId");
  print("Payload: ${jsonEncode(webPayload)}");
  print("");
  
  // Step 5: Also test - what if we send just the plain ExtId (no JSON wrapping)?
  print("=== Step 5: Plain ExtId (no JSON wrapping) ===");
  final plainPayload = {
    'Body': 'test_from_diagnostic',
    'BodyType': 1,
    'ExtId': extId,  // Just the raw number string, not JSON
    'ChannelId': 2,
    'AccountIds': accId,
    'Attachment': '',
  };
  print("URL: https://id.nobox.ai/Inbox/Send?Id=$roomId");
  print("Payload: ${jsonEncode(plainPayload)}");
}
