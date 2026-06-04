import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImN0eSI6IkpXVCJ9.eyJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9uYW1lIjoiYWtiYXJyaXlhbmRAZ21haWwuY29tIiwiaHR0cDovL3NjaGVtYXMueG1sc29hcC5vcmcvd3MvMjAwNS8wNS9pZGVudGl0eS9jbGFpbXMvbmFtZWlkZW50aWZpZXIiOiIxOTIwIiwiZXhwIjoxNzc5Nzg2NTE2LCJpc3MiOiJodHRwczovL2lkLm5vYm94LmFpLyIsImF1ZCI6Imh0dHBzOi8vaWQubm9ib3guYWkvIn0.IIrHiYRKsVmzJFPuCpohJJO8uk7xtqwukt_uaS2XEo8";

  // Test 1: ExtId only (string), NO LinkId
  print("=== Test 1: ExtId only (string) ===");
  final res1 = await http.post(
    Uri.parse('https://id.nobox.ai/Inbox/Send?Id=807686061948933'),
    headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    body: jsonEncode({
      "Body": "test1",
      "BodyType": 1,
      "ExtId": "6912143766",
      "ChannelId": 2,
      "AccountIds": "807236570021893",
      "Attachment": ""
    }),
  );
  print("Status: ${res1.statusCode}");
  print("Body: ${res1.body}\n");

  // Test 2: LinkId only (long number), NO ExtId
  print("=== Test 2: LinkId only (long) ===");
  final res2 = await http.post(
    Uri.parse('https://id.nobox.ai/Inbox/Send?Id=807686061948933'),
    headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    body: jsonEncode({
      "Body": "test2",
      "BodyType": 1,
      "LinkId": 807686061867013,
      "ChannelId": 2,
      "AccountIds": "807236570021893",
      "Attachment": ""
    }),
  );
  print("Status: ${res2.statusCode}");
  print("Body: ${res2.body}\n");

  // Test 3: Both with correct types
  print("=== Test 3: Both LinkId (long) + ExtId (string) ===");
  final res3 = await http.post(
    Uri.parse('https://id.nobox.ai/Inbox/Send?Id=807686061948933'),
    headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    body: jsonEncode({
      "Body": "test3",
      "BodyType": 1,
      "LinkId": 807686061867013,
      "ExtId": "6912143766",
      "ChannelId": 2,
      "AccountIds": "807236570021893",
      "Attachment": ""
    }),
  );
  print("Status: ${res3.statusCode}");
  print("Body: ${res3.body}\n");
}
