import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImN0eSI6IkpXVCJ9.eyJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9uYW1lIjoiYWtiYXJyaXlhbmRAZ21haWwuY29tIiwiaHR0cDovL3NjaGVtYXMueG1sc29hcC5vcmcvd3MvMjAwNS8wNS9pZGVudGl0eS9jbGFpbXMvbmFtZWlkZW50aWZpZXIiOiIxOTIwIiwiZXhwIjoxNzc5Nzg2NTE2LCJpc3MiOiJodHRwczovL2lkLm5vYm94LmFpLyIsImF1ZCI6Imh0dHBzOi8vaWQubm9ib3guYWkvIn0.IIrHiYRKsVmzJFPuCpohJJO8uk7xtqwukt_uaS2XEo8";
  
  final Map<String, dynamic> bodyTest = {
    "Body": "hello",
    "BodyType": 1,
    "CtId": 807686061867013,
    "ChannelId": 2,
    "AccountIds": "807236570021893",
    "Attachment": ""
  };
  
  try {
    print("Testing Inbox/Send with CtId...");
    final res = await http.post(
      Uri.parse('https://id.nobox.ai/Inbox/Send?Id=807686061948933'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode(bodyTest),
    );
    print("Status: ${res.statusCode}");
    print("Body: ${res.body}");
  } catch (e) {
    print("Error: $e");
  }
}
