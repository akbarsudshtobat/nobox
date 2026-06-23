import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final String url = 'https://id.nobox.ai/Services/Chat/Chatrooms/List';
  final String token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImN0eSI6IkpXVCJ9.eyJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9uYW1lIjoiYWtiYXJyaXlhbmRAZ21haWwuY29tIiwiaHR0cDovL3NjaGVtYXMueG1sc29hcC5vcmcvd3MvMjAwNS8wNS9pZGVudGl0eS9jbGFpbXMvbmFtZWlkZW50aWZpZXIiOiIxOTIwIiwiZXhwIjoxNzgxOTIzMTQyLCJpc3MiOiJodHRwczovL2lkLm5vYm94LmFpLyIsImF1ZCI6Imh0dHBzOi8vaWQubm9ib3guYWkvIn0.eA7iS9_gdYQN-sgxK5Jkw-FmBWM2oeWnYw3iH_W3LcU';

  final payload = {
    "Take": 5,
    "Skip": 0,
    "Criteria": ["AgentId", "=", 1920]
  };

  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(payload),
  );

  print('Criteria test: ${response.statusCode}');
  print('Response: ${response.body}');
}
