import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImN0eSI6IkpXVCJ9.eyJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9uYW1lIjoiYWtiYXJyaXlhbmRAZ21haWwuY29tIiwiaHR0cDovL3NjaGVtYXMueG1sc29hcC5vcmcvd3MvMjAwNS8wNS9pZGVudGl0eS9jbGFpbXMvbmFtZWlkZW50aWZpZXIiOiIxOTIwIiwiZXhwIjoxNzc5Nzg2NTE2LCJpc3MiOiJodHRwczovL2lkLm5vYm94LmFpLyIsImF1ZCI6Imh0dHBzOi8vaWQubm9ib3guYWkvIn0.IIrHiYRKsVmzJFPuCpohJJO8uk7xtqwukt_uaS2XEo8";
  
  final Map<String, dynamic> bodyWithExtId = {
    "Body": "hello from test",
    "BodyType": 1,
    "ExtId": "6912143766",
    "ChannelId": 2,
    "AccountIds": "807236570021893",
    "Attachment": ""
  };

  final Map<String, dynamic> bodyWithIdExternal = {
    "Body": "hello from test",
    "BodyType": 1,
    "IdExternal": "6912143766",
    "ChannelId": 2,
    "AccountIds": "807236570021893",
    "Attachment": ""
  };
  
  try {
    print("Testing Inbox/Send with ExtId...");
    final res1 = await http.post(
      Uri.parse('https://id.nobox.ai/Inbox/Send?Id=807686061948933'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode(bodyWithExtId),
    );
    print("Status: ${res1.statusCode}");
    print("Body: ${res1.body}");

    if (res1.body.contains("must have value") || res1.body.contains("does not contain a definition")) {
      print("\nTesting Inbox/Send with IdExternal...");
      final res2 = await http.post(
        Uri.parse('https://id.nobox.ai/Inbox/Send?Id=807686061948933'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(bodyWithIdExternal),
      );
      print("Status: ${res2.statusCode}");
      print("Body: ${res2.body}");
    }
  } catch (e) {
    print("Error: $e");
  }
}
