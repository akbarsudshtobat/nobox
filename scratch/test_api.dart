import 'dart:convert';
import 'dart:io';

void main() async {
  final token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImN0eSI6IkpXVCJ9.eyJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9uYW1lIjoiYWtiYXJyaXlhbmRAZ21haWwuY29tIiwiaHR0cDovL3NjaGVtYXMueG1sc29hcC5vcmcvd3MvMjAwNS8wNS9pZGVudGl0eS9jbGFpbXMvbmFtZWlkZW50aWZpZXIiOiIxOTIwIiwiZXhwIjoxNzgyMTMyNTE2LCJpc3MiOiJodHRwczovL2lkLm5vYm94LmFpLyIsImF1ZCI6Imh0dHBzOi8vaWQubm9ib3guYWkvIn0.YcPaN7aaBtSbLUYM8Kn_jW6pcnWxtupcA4TXQ3EwP78';
  final url = Uri.parse('https://id.nobox.ai/Services/Administration/User/List');
  
  final payloads = [
    {'EqualityFilter': {'Roles': [6]}, 'IncludeColumns': ['DisplayName', 'UserId'], 'Take': 10},
    {'EqualityFilter': {'Roles': 6}, 'IncludeColumns': ['DisplayName', 'UserId'], 'Take': 10},
    {'EqualityFilter': {'Role': 6}, 'IncludeColumns': ['DisplayName', 'UserId'], 'Take': 10},
    {'IncludeColumns': ['DisplayName', 'UserId', 'Roles', 'Role'], 'Take': 10},
  ];

  for (var payload in payloads) {
    print('Testing payload: $payload');
    final request = await HttpClient().postUrl(url);
    request.headers.set('Authorization', 'Bearer $token');
    request.headers.set('Content-Type', 'application/json');
    request.write(jsonEncode(payload));
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    print('Response: $responseBody\n');
  }
}
