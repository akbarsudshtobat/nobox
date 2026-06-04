import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImN0eSI6IkpXVCJ9.eyJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9uYW1lIjoiYWtiYXJyaXlhbmRAZ21haWwuY29tIiwiaHR0cDovL3NjaGVtYXMueG1sc29hcC5vcmcvd3MvMjAwNS8wNS9pZGVudGl0eS9jbGFpbXMvbmFtZWlkZW50aWZpZXIiOiIxOTIwIiwiZXhwIjoxNzc5Nzg2NTE2LCJpc3MiOiJodHRwczovL2lkLm5vYm94LmFpLyIsImF1ZCI6Imh0dHBzOi8vaWQubm9ib3guYWkvIn0.IIrHiYRKsVmzJFPuCpohJJO8uk7xtqwukt_uaS2XEo8";
  
  final Map<String, dynamic> body1 = {"CtId": 807686061867013};
  final Map<String, dynamic> body2 = {"EntityId": 807686061867013};
  
  try {
    print("Testing POST with CtId...");
    final res1 = await http.post(
      Uri.parse('https://id.nobox.ai/Services/Chat/Chatlinkcontacts/Retrieve'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode(body1),
    );
    print("Status: ${res1.statusCode}");
    print("Body: ${res1.body}");
    
    if (res1.statusCode == 500 && res1.body.contains("Could not find member")) {
      print("\nTesting POST with EntityId...");
      final res2 = await http.post(
        Uri.parse('https://id.nobox.ai/Services/Chat/Chatlinkcontacts/Retrieve'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(body2),
      );
      print("Status: ${res2.statusCode}");
      print("Body: ${res2.body}");
    }
  } catch (e) {
    print("Error: $e");
  }
}
