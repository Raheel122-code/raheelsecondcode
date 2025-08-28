import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';
import '../storage/shared_prefs.dart';
import 'package:path/path.dart' as path;

class ApiClient {
  final http.Client _client;
  final SharedPreferencesHelper _prefs;
  String? _authToken;

  ApiClient({http.Client? client, SharedPreferencesHelper? prefs})
    : _client = client ?? http.Client(),
      _prefs = prefs ?? SharedPreferencesHelper();

  Future<void> _initToken() async {
    _authToken = await _prefs.getToken();
  }

  Future<void> initialize() async {
    await _initToken();
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  Future<Map<String, String>> _getHeaders([bool isMultipart = false]) async {
    if (_authToken == null) {
      await _initToken();
    }

    final headers = <String, String>{
      if (!isMultipart) 'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };

    return headers;
  }

  Future<T> get<T>(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      final uri = Uri.parse(
        ApiConstants.baseUrl + endpoint,
      ).replace(queryParameters: queryParams);

      print('GET Request to: $uri');
      final headers = await _getHeaders();
      print('Headers: $headers');

      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: ApiConstants.timeoutSeconds));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      return _handleResponse<T>(response);
    } on SocketException {
      throw ApiException(
        code: 503,
        message: 'No Internet connection',
        type: 'NetworkError',
      );
    } on TimeoutException {
      throw ApiException(
        code: 504,
        message: 'Request timeout',
        type: 'NetworkError',
      );
    } catch (e) {
      throw ApiException(
        code: 500,
        message: 'GET request failed: ${e.toString()}',
        type: 'ServerError',
      );
    }
  }

  Future<T> post<T>(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? formData,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.baseUrl + endpoint);
      print('POST Request to: $uri');

      late http.Response response;

      if (formData != null) {
        // Handle multipart form data
        final request = http.MultipartRequest('POST', uri);

        // Add headers including auth token
        final headers = await _getHeaders(true);
        request.headers.addAll(headers);

        print('Headers: ${request.headers}');

        // Add fields and files
        for (var entry in formData.entries) {
          if (entry.value is File ||
              (entry.value is String && File(entry.value).existsSync())) {
            // Handle file upload
            final filePath =
                entry.value is File ? entry.value.path : entry.value;
            final file = File(filePath);
            final filename = path.basename(filePath);
            final mimeType = _getMimeType(filename);

            print(
              'Adding file ${entry.key}: $filename (${mimeType.toString()})',
            );

            final multipartFile = await http.MultipartFile.fromPath(
              entry.key,
              file.path,
              contentType: mimeType,
            );
            request.files.add(multipartFile);
          } else {
            // Handle regular field
            print('Adding field ${entry.key}: ${entry.value}');
            request.fields[entry.key] = entry.value.toString();
          }
        }

        // Send the request
        print('Sending multipart request...');
        final streamedResponse = await request.send().timeout(
          Duration(seconds: ApiConstants.timeoutSeconds),
        );
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Handle regular JSON request
        final headers = await _getHeaders();
        print('Headers: $headers');
        print('Body: ${body != null ? json.encode(body) : 'null'}');

        response = await _client
            .post(
              uri,
              headers: headers,
              body: body != null ? json.encode(body) : null,
            )
            .timeout(Duration(seconds: ApiConstants.timeoutSeconds));
      }

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      return _handleResponse<T>(response);
    } on SocketException {
      throw ApiException(
        code: 503,
        message: 'No Internet connection',
        type: 'NetworkError',
      );
    } on TimeoutException {
      throw ApiException(
        code: 504,
        message: 'Request timeout',
        type: 'NetworkError',
      );
    } catch (e) {
      throw ApiException(
        code: 500,
        message: 'POST request failed: ${e.toString()}',
        type: 'ServerError',
      );
    }
  }

  MediaType _getMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'gif':
        return MediaType('image', 'gif');
      case 'mp4':
        return MediaType('video', 'mp4');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  T _handleResponse<T>(http.Response response) {
    try {
      final body = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body as T;
      } else {
        final message = body['message'] ?? 'Unknown error occurred';
        final type = body['error'] ?? 'ServerError';

        if (response.statusCode == 401) {
          _authToken = null;
          _prefs.clearAll();
        }

        throw ApiException(
          code: response.statusCode,
          message: message,
          type: type,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        code: response.statusCode,
        message: 'Failed to process response: ${e.toString()}',
        type: 'ParseError',
      );
    }
  }
}
