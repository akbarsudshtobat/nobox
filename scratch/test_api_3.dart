import 'dart:convert';
import 'dart:io';

void main() async {
  final token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImN0eSI6IkpXVCJ9.eyJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9uYW1lIjoiYWtiYXJyaXlhbmRAZ21haWwuY29tIiwiaHR0cDovL3NjaGVtYXMueG1sc29hcC5vcmcvd3MvMjAwNS8wNS9pZGVudGl0eS9jbGFpbXMvbmFtZWlkZW50aWZpZXIiOiIxOTIwIiwiZXhwIjoxNzgyMTMyNTE2LCJpc3MiOiJodHRwczovL2lkLm5vYm94LmFpLyIsImF1ZCI6Imh0dHBzOi8vaWQubm9ib3guYWkvIn0.YcPaN7aaBtSbLUYM8Kn_jW6pcnWxtupcA4TXQ3EwP78';
  final url = Uri.parse('https://id.nobox.ai/Services/Administration/User/ListAgent');
  
  final payload = {
    'IncludeColumns': ['Id', 'UserId', 'DisplayName', 'Username', 'Name', 'Nm'],
    'ColumnSelection': 1,
    'Take': 100,
    'Skip': 0,
  };

  print('Testing payload ListAgent');
  final request = await HttpClient().postUrl(url);
  request.headers.set('Authorization', 'Bearer $token');
  request.headers.set('Content-Type', 'application/json');
  request.write(jsonEncode(payload));
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  print('Response: $responseBody\n');
}
