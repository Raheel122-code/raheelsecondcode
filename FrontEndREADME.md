# TikTok Clone - Frontend Implementation Guide

> **Important**: Please read this documentation carefully before starting implementation. This guide follows clean architecture principles, MVVM pattern, and feature-based structure to match the backend's organization.

## Architecture Overview

### 1. Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── api_constants.dart
│   │   └── storage_constants.dart
│   ├── errors/
│   │   ├── api_exception.dart
│   │   └── network_exception.dart
│   ├── network/
│   │   └── api_client.dart
│   ├── storage/
│   │   └── shared_prefs.dart
│   └── utils/
│       ├── validators.dart
│       └── file_helper.dart
├── features/
│   ├── auth/
│   │   ├── models/
│   │   │   └── user_model.dart
│   │   ├── services/
│   │   │   └── auth_service.dart
│   │   └── views/
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   └── register_screen.dart
│   │       └── widgets/
│   │           ├── auth_button.dart
│   │           └── custom_text_field.dart
│   ├── feed/
│   │   ├── models/
│   │   │   ├── media_model.dart
│   │   │   ├── comment_model.dart
│   │   │   └── rating_model.dart
│   │   ├── services/
│   │   │   └── feed_service.dart
│   │   └── views/
│   │       ├── screens/
│   │       │   ├── feed_screen.dart
│   │       │   └── video_detail_screen.dart
│   │       └── widgets/
│   │           ├── video_player_widget.dart
│   │           ├── video_info_widget.dart
│   │           ├── comments_list.dart
│   │           └── rating_widget.dart
│   └── creator/
│       ├── models/
│       │   └── creator_stats_model.dart
│       ├── services/
│       │   └── creator_service.dart
│       └── views/
│           ├── screens/
│           │   ├── creator_profile_screen.dart
│           │   └── upload_video_screen.dart
│           └── widgets/
│               ├── profile_header.dart
│               ├── video_grid.dart
│               ├── upload_form.dart
│               └── stats_card.dart
├── providers/
│   ├── auth_provider.dart
│   ├── feed_provider.dart
│   └── creator_provider.dart
└── main.dart
```

Each feature module (auth, feed, creator) follows a consistent structure:

1. **models/** - Data models and their transformations

   ```dart
   // Example: features/feed/models/media_model.dart
   class MediaModel {
       final String id;
       final String title;
       final String videoUrl;
       final String thumbnailUrl;
       final UserModel uploader;
       final double averageRating;
       final int commentsCount;

       MediaModel.fromJson(Map<String, dynamic> json);
       Map<String, dynamic> toJson();
   }
   ```

2. **services/** - API integration and business logic

   ```dart
   // Example: features/feed/services/feed_service.dart
   class FeedService {
       final ApiClient _apiClient;

       Future<List<MediaModel>> getFeed(int page, int limit);
       Future<void> addComment(String mediaId, String comment);
       Future<void> addRating(String mediaId, int rating);
   }
   ```

3. **views/screens/** - Full page UI components

   ```dart
   // Example: features/feed/views/screens/feed_screen.dart
   class FeedScreen extends StatelessWidget {
       @override
       Widget build(BuildContext context) {
           return Consumer<FeedProvider>(
               builder: (context, provider, _) => ...
           );
       }
   }
   ```

4. **views/widgets/** - Reusable UI components

   ```dart
   // Example: features/feed/views/widgets/video_player_widget.dart
   class VideoPlayerWidget extends StatefulWidget {
       final MediaModel media;
       final bool autoplay;

       @override
       State<VideoPlayerWidget> createState();
   }
   ```

This structure provides several benefits:

1. Clear separation of concerns
2. Easy to locate related code
3. Better code organization
4. Reusable components
5. Feature isolation

```
lib/
├── core/
│   ├── constants/
│   │   ├── api_constants.dart
│   ├── errors/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── network/
│   │   ├── http_client.dart
│   │   └── api_client.dart
│   └── utils/
│       └── shared_preferences_helper.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   ├── datasources/
│   │   │   │   └── auth_remote_datasource.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── login.dart
│   │   │       └── register.dart
│   │   ├── presentation/
│   │   │   ├── viewmodels/
│   │   │   │   └── auth_viewmodel.dart
│   │   │   └── pages/
│   │   │       ├── login_page.dart
│   │   │       └── register_page.dart
│   ├── feed/
│   │   └── [similar structure]
│   └── creator/
│       └── [similar structure]
└── main.dart
```

### 2. MVVM Architecture Pattern

```dart
// 1. Model (Data Layer)
class UserModel extends User {
    final String token;

    factory UserModel.fromJson(Map<String, dynamic> json) {
        return UserModel(
            id: json['_id'],
            username: json['username'],
            // ... other fields
        );
    }
}

// 2. Repository (Domain Layer)
abstract class AuthRepository {
    Future<Either<Failure, User>> login(String email, String password);
}

// 3. ViewModel (Presentation Layer)
class AuthViewModel extends ChangeNotifier {
    final Login _loginUseCase;

    Future<void> login(String email, String password) async {
        state = ViewState.loading;
        final result = await _loginUseCase(LoginParams(email, password));
        result.fold(
            (failure) => state = ViewState.error(failure),
            (user) => state = ViewState.loaded(user)
        );
    }
}

// 4. View (Presentation Layer)
class LoginPage extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return ChangeNotifierProvider(
            create: (context) => getIt<AuthViewModel>(),
            child: LoginView(),
        );
    }
}
```

### 3. HTTP Client Implementation (Instead of Dio)

```dart
// core/network/http_client.dart
class HttpClient {
    final http.Client _client = http.Client();
    final String baseUrl;

    Future<T> get<T>(
        String path, {
        Map<String, String>? headers,
        Map<String, dynamic>? queryParameters,
    }) async {
        try {
            final uri = Uri.parse(baseUrl + path).replace(
                queryParameters: queryParameters
            );
            final response = await _client.get(
                uri,
                headers: {
                    'Content-Type': 'application/json',
                    ...?headers,
                },
            );
            return _handleResponse<T>(response);
        } catch (e) {
            throw NetworkException(e.toString());
        }
    }

    Future<T> post<T>(
        String path, {
        dynamic body,
        Map<String, String>? headers,
    }) async {
        try {
            final uri = Uri.parse(baseUrl + path);
            final response = await _client.post(
                uri,
                headers: {
                    'Content-Type': 'application/json',
                    ...?headers,
                },
                body: json.encode(body),
            );
            return _handleResponse<T>(response);
        } catch (e) {
            throw NetworkException(e.toString());
        }
    }

    T _handleResponse<T>(http.Response response) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
            return json.decode(response.body);
        } else {
            throw ApiException(
                statusCode: response.statusCode,
                message: response.body,
            );
        }
    }
}
```

### 4. Clean Code Principles

1. **Single Responsibility**: Each class has one job
2. **Dependency Injection**: Using `get_it` for service locator
3. **Interface Segregation**: Small, specific interfaces
4. **Repository Pattern**: Data layer abstraction
5. **Use Cases**: Business logic encapsulation
6. **Error Handling**: Proper error types and handling
7. **Testing**: Each layer can be tested independently

### 5. Feature-Based Structure

Each feature (auth, feed, creator) contains:

- Data Layer (API integration)
- Domain Layer (Business logic)
- Presentation Layer (UI/UX)

## Table of Contents

1. [Project Setup](#project-setup)
2. [Authentication Flow](#authentication-flow)
3. [User Role-Based Navigation](#user-role-based-navigation)
4. [Creator Dashboard](#creator-dashboard)
5. [Consumer Feed](#consumer-feed)
6. [API Integration Points](#api-integration-points)
7. [Data Models](#data-models)
8. [Error Handling](#error-handling)

## Project Setup

### Required Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  shared_preferences: ^2.2.1
  provider: ^6.0.5
  get_it: ^7.6.4
  equatable: ^2.0.5
  dartz: ^0.10.1
  image_picker: ^1.0.4
  video_player: ^2.7.2
  path_provider: ^2.1.1
  video_thumbnail: ^0.5.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.2
  build_runner: ^2.4.6
```

### Base URL Configuration

```dart
// core/constants/api_constants.dart
class ApiConstants {
    static const String baseUrl = 'http://localhost:3001/api';
    static const int timeoutSeconds = 30;

    // API Endpoints
    static const String login = '/auth/login';
    static const String register = '/auth/register';
    static const String currentUser = '/auth/current';
    static const String feed = '/media/feed';
    static const String creatorFeed = '/media/creator';
    static const String upload = '/media/upload';
    static const String updateProfilePic = '/users/profile-picture';
}
```

### HTTP Client Setup

````dart
// core/network/http_client.dart
class ApiClient {
    final http.Client _client = http.Client();
    final SharedPreferencesHelper _prefs;

    ApiClient(this._prefs);

    Future<Map<String, String>> _getHeaders() async {
        final token = await _prefs.getToken();
        return {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
        };
    }

    Future<T> get<T>(
        String endpoint, {
        Map<String, dynamic>? queryParams,
    }) async {
        try {
            final uri = Uri.parse(ApiConstants.baseUrl + endpoint)
                .replace(queryParameters: queryParams);

            final response = await _client.get(
                uri,
                headers: await _getHeaders(),
            );

            return _handleResponse<T>(response);
        } on SocketException {
            throw NetworkException('No Internet connection');
        } catch (e) {
            throw ServerException(e.toString());
        }
    }

    Future<T> post<T>(
        String endpoint, {
        dynamic body,
        bool isMultipart = false,
    }) async {
        try {
            final uri = Uri.parse(ApiConstants.baseUrl + endpoint);
            final headers = await _getHeaders();

            late http.Response response;
            if (isMultipart && body is List<http.MultipartFile>) {
                final request = http.MultipartRequest('POST', uri)
                    ..headers.addAll(headers)
                    ..files.addAll(body);
                response = await http.Response.fromStream(
                    await request.send()
                );
            } else {
                response = await _client.post(
                    uri,
                    headers: headers,
                    body: json.encode(body),
                );
            }

            return _handleResponse<T>(response);
        } on SocketException {
            throw NetworkException('No Internet connection');
        } catch (e) {
            throw ServerException(e.toString());
        }
    }

    T _handleResponse<T>(http.Response response) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
            return json.decode(response.body) as T;
        } else {
            throw ApiException(
                code: response.statusCode,
                message: _parseErrorMessage(response.body),
            );
        }
    }

    String _parseErrorMessage(String body) {
        try {
            final parsed = json.decode(body);
            return parsed['message'] ?? 'Unknown error occurred';
        } catch (_) {
            return body;
        }
    }
}

## Authentication Flow

### 1. Registration
```http
POST /api/auth/register
Content-Type: application/json

Request Body:
{
    "username": "string",
    "email": "string",
    "password": "string",
    "role": "creator" | "consumer"
}

Response:
{
    "data": {
        "_id": "string",
        "username": "string",
        "email": "string",
        "role": "string",
        "profilePic": "string",
        "token": "string"
    },
    "message": "User registered successfully"
}
````

### 2. Login

```http
POST /api/auth/login
Content-Type: application/json

Request Body:
{
    "email": "string",
    "password": "string"
}

Response:
{
    "data": {
        "_id": "string",
        "username": "string",
        "email": "string",
        "role": "string",
        "profilePic": "string",
        "token": "string"
    },
    "message": "Login successful"
}
```

### Authentication Implementation Steps:

1. Create UserModel to match backend response:

```dart
class UserModel {
    final String id;
    final String username;
    final String email;
    final String role;
    final String profilePic;
    final String token;

    UserModel({
        required this.id,
        required this.username,
        required this.email,
        required this.role,
        required this.profilePic,
        required this.token,
    });

    factory UserModel.fromJson(Map<String, dynamic> json) {
        return UserModel(
            id: json['_id'],
            username: json['username'],
            email: json['email'],
            role: json['role'],
            profilePic: json['profilePic'] ?? '',
            token: json['token'],
        );
    }
}
```

2. Create Authentication Service:

```dart
class AuthService {
    final _storage = SharedPreferences.getInstance();
    final _api = ApiClient();

    Future<UserModel> login(String email, String password) async {
        final response = await _api.post('/auth/login', data: {
            'email': email,
            'password': password,
        });

        final user = UserModel.fromJson(response.data['data']);
        await _saveUserData(user);
        return user;
    }

    Future<UserModel> register(String username, String email, String password, String role) async {
        final response = await _api.post('/auth/register', data: {
            'username': username,
            'email': email,
            'password': password,
            'role': role,
        });

        final user = UserModel.fromJson(response.data['data']);
        await _saveUserData(user);
        return user;
    }

    Future<void> _saveUserData(UserModel user) async {
        final prefs = await _storage;
        await prefs.setString('token', user.token);
        await prefs.setString('userRole', user.role);
        await prefs.setString('userId', user.id);
        await prefs.setString('username', user.username);
    }
}
```

3. Create Authentication Interceptor:

```dart
// Example interceptor
class AuthInterceptor extends Interceptor {
    @override
    void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
        final token = SharedPreferences.getInstance().getString('token');
        options.headers['Authorization'] = 'Bearer $token';
        super.onRequest(options, handler);
    }
}
```

## User Role-Based Navigation

### Role Check and Navigation

```dart
void checkRoleAndNavigate() {
    final role = SharedPreferences.getInstance().getString('userRole');
    if (role == 'creator') {
        Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => CreatorDashboard()
        ));
    } else {
        Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => ConsumerFeed()
        ));
    }
}
```

## Creator Dashboard

### Models

```dart
class MediaModel {
    final String id;
    final String title;
    final String caption;
    final String video;
    final String thumbnail;
    final String ageRating;
    final UserModel uploader;
    final double averageRating;
    final int commentsCount;
    final List<CommentModel> comments;
    final List<RatingModel> ratings;

    MediaModel.fromJson(Map<String, dynamic> json) {
        id = json['_id'];
        title = json['title'];
        caption = json['caption'];
        video = json['video'];
        thumbnail = json['thumbnail'];
        ageRating = json['ageRating'];
        uploader = UserModel.fromJson(json['uploader']);
        averageRating = json['averageRating']?.toDouble() ?? 0.0;
        commentsCount = json['commentsCount'] ?? 0;
        comments = (json['comments'] as List?)
            ?.map((e) => CommentModel.fromJson(e))
            .toList() ?? [];
        ratings = (json['ratings'] as List?)
            ?.map((e) => RatingModel.fromJson(e))
            .toList() ?? [];
    }
}

class CommentModel {
    final String id;
    final String text;
    final DateTime createdAt;
    final UserModel user;

    CommentModel.fromJson(Map<String, dynamic> json) {
        id = json['_id'];
        text = json['text'];
        createdAt = DateTime.parse(json['createdAt']);
        user = UserModel.fromJson(json['user']);
    }
}

class RatingModel {
    final double value;

    RatingModel.fromJson(Map<String, dynamic> json) {
        value = json['value']?.toDouble() ?? 0.0;
    }
}
```

### 1. Profile Section

- Display profile picture and username at the top
- Option to update profile picture

```http
POST /api/users/profile-picture
Content-Type: multipart/form-data

Request Body:
- image: File

Response:
{
    "data": {
        "profilePic": "string"
    },
    "message": "Profile picture updated successfully"
}
```

### 2. Creator's Posts

```http
GET /api/media/creator/:userId
Parameters:
- page: number
- limit: number

Response:
{
    "data": [{
        "_id": "string",
        "title": "string",
        "caption": "string",
        "thumbnail": "string",
        "video": "string",
        "ageRating": "string",
        "averageRating": number,
        "commentsCount": number,
        "uploader": {
            "username": "string",
            "profilePic": "string"
        }
    }],
    "pagination": {
        "currentPage": number,
        "hasMore": boolean,
        "totalPages": number,
        "total": number
    }
}
```

### 3. Create Post Dialog

```http
POST /api/media/upload
Content-Type: multipart/form-data

Request Body:
- title: string
- caption: string
- ageRating: "below 18" | "18 plus"
- video: File
- thumbnail: File

Response:
{
    "data": {
        "_id": "string",
        "title": "string",
        "caption": "string",
        "video": "string",
        "thumbnail": "string",
        "ageRating": "string"
    },
    "message": "Media uploaded successfully"
}
```

### 4. Post Details Dialog

```http
GET /api/media/:id/stats

Response:
{
    "data": {
        "totalComments": number,
        "totalRatings": number,
        "averageRating": number,
        "ratingDistribution": {
            "1": number,
            "2": number,
            // ... up to 10
        },
        "recentComments": ["string"]
    }
}
```

## Consumer Feed

### MediaService Implementation

```dart
class MediaService {
    final _api = ApiClient();

    Future<List<MediaModel>> getFeed({int page = 1, int limit = 10}) async {
        final response = await _api.get('/media/feed', queryParameters: {
            'page': page,
            'limit': limit,
        });

        return (response.data['data'] as List)
            .map((item) => MediaModel.fromJson(item))
            .toList();
    }

    Future<List<MediaModel>> getCreatorFeed(String userId, {int page = 1, int limit = 10}) async {
        final response = await _api.get('/media/creator/$userId', queryParameters: {
            'page': page,
            'limit': limit,
        });

        return (response.data['data'] as List)
            .map((item) => MediaModel.fromJson(item))
            .toList();
    }

    Future<Map<String, dynamic>> getPostStats(String postId) async {
        final response = await _api.get('/media/$postId/stats');
        return response.data['data'];
    }

    Future<void> addComment(String postId, String text) async {
        await _api.post('/media/$postId/comment', data: {'text': text});
    }

    Future<void> addRating(String postId, int value) async {
        await _api.post('/media/$postId/rate', data: {'value': value});
    }
}
```

### 1. Feed Implementation

```http
GET /api/media/feed
Parameters:
- page: number
- limit: number

Response:
{
    "data": [{
        "_id": "string",
        "title": "string",
        "caption": "string",
        "thumbnail": "string",
        "video": "string",
        "ageRating": "string",
        "averageRating": number,
        "commentsCount": number,
        "uploader": {
            "username": "string",
            "profilePic": "string"
        }
    }],
    "pagination": {
        "currentPage": number,
        "hasMore": boolean,
        "totalPages": number,
        "total": number
    }
}
```

### 2. Video Player Widget

```dart
class VideoPlayerWidget extends StatefulWidget {
    final MediaModel media;
    final bool autoplay;

    const VideoPlayerWidget({
        Key? key,
        required this.media,
        this.autoplay = false,
    }) : super(key: key);

    @override
    _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
    late VideoPlayerController _controller;
    bool _isHovering = false;
    bool _isInitialized = false;

    @override
    void initState() {
        super.initState();
        _initializeVideo();
    }

    Future<void> _initializeVideo() async {
        _controller = VideoPlayerController.network(widget.media.video)
            ..initialize().then((_) {
                setState(() {
                    _isInitialized = true;
                });
                if (widget.autoplay) {
                    _controller.play();
                    _controller.setLooping(true);
                }
            });
    }

    @override
    Widget build(BuildContext context) {
        return MouseRegion(
            onEnter: (_) => _onHover(true),
            onExit: (_) => _onHover(false),
            child: Stack(
                children: [
                    if (!_isInitialized || !_isHovering)
                        Image.network(
                            widget.media.thumbnail,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                        ),
                    if (_isInitialized && _isHovering)
                        AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                        ),
                    _buildVideoInfo(),
                ],
            ),
        );
    }

    Widget _buildVideoInfo() {
        return Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                        ],
                    ),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                            widget.media.title,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                            ),
                        ),
                        SizedBox(height: 4),
                        Row(
                            children: [
                                Icon(Icons.star, color: Colors.yellow, size: 16),
                                Text(
                                    '${widget.media.averageRating.toStringAsFixed(1)}',
                                    style: TextStyle(color: Colors.white),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.comment, color: Colors.white, size: 16),
                                Text(
                                    '${widget.media.commentsCount}',
                                    style: TextStyle(color: Colors.white),
                                ),
                                SizedBox(width: 8),
                                Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                        color: widget.media.ageRating == 'below 18'
                                            ? Colors.green
                                            : Colors.red,
                                        borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                        widget.media.ageRating,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                        ),
                                    ),
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        );
    }

    void _onHover(bool hovering) {
        setState(() {
            _isHovering = hovering;
            if (hovering && _isInitialized) {
                _controller.play();
                _controller.setLooping(true);
            } else {
                _controller.pause();
                _controller.seekTo(Duration.zero);
            }
        });
    }

    @override
    void dispose() {
        _controller.dispose();
        super.dispose();
    }
}
```

### 3. Comment System

```http
POST /api/media/:id/comment
Content-Type: application/json

Request Body:
{
    "text": "string"
}

Response:
{
    "data": {
        // Updated media object with new comment
    },
    "message": "Comment added successfully"
}
```

### 4. Rating System

```http
POST /api/media/:id/rate
Content-Type: application/json

Request Body:
{
    "value": number // 1-10
}

Response:
{
    "data": {
        // Updated media object with new rating
    },
    "message": "Rating added successfully"
}
```

## Implementation Guidelines

### 1. Video Hover Mechanism

```dart
// Video hover mechanism for consumer feed
class VideoCard extends StatefulWidget {
    @override
    Widget build(BuildContext context) {
        return MouseRegion(
            onEnter: (_) {
                setState(() {
                    isHovering = true;
                    videoController.play();
                });
            },
            onExit: (_) {
                setState(() {
                    isHovering = false;
                    videoController.pause();
                });
            },
            child: Column(
                children: [
                    isHovering ?
                        VideoPlayer(videoController) :
                        Image.network(thumbnail),
                    VideoStats(
                        commentsCount: media.commentsCount,
                        averageRating: media.averageRating,
                        ageRating: media.ageRating
                    )
                ]
            )
        );
    }
}
```

### 2. Feed Screen Implementation

```dart
class ConsumerFeedScreen extends StatefulWidget {
    @override
    _ConsumerFeedScreenState createState() => _ConsumerFeedScreenState();
}

class _ConsumerFeedScreenState extends State<ConsumerFeedScreen> {
    final ScrollController _scrollController = ScrollController();
    final MediaService _mediaService = MediaService();
    int _currentPage = 1;
    bool _hasMore = true;
    bool _isLoading = false;
    List<MediaModel> _posts = [];

    @override
    void initState() {
        super.initState();
        _loadInitialData();
        _scrollController.addListener(_onScroll);
    }

    Future<void> _loadInitialData() async {
        setState(() => _isLoading = true);
        try {
            final posts = await _mediaService.getFeed(page: 1);
            setState(() {
                _posts = posts;
                _currentPage = 1;
                _hasMore = posts.length == 10; // assuming limit is 10
            });
        } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to load feed'))
            );
        } finally {
            setState(() => _isLoading = false);
        }
    }

    void _onScroll() {
        if (!_isLoading && _hasMore &&
            _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
            _loadMoreData();
        }
    }

    Future<void> _loadMoreData() async {
        if (_isLoading) return;

        setState(() => _isLoading = true);
        try {
            final nextPage = _currentPage + 1;
            final morePosts = await _mediaService.getFeed(page: nextPage);

            setState(() {
                _posts.addAll(morePosts);
                _currentPage = nextPage;
                _hasMore = morePosts.length == 10;
            });
        } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to load more posts'))
            );
        } finally {
            setState(() => _isLoading = false);
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            body: RefreshIndicator(
                onRefresh: _loadInitialData,
                child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                        SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 9/16,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                            ),
                            delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                    if (index >= _posts.length) {
                                        return _hasMore
                                            ? Center(child: CircularProgressIndicator())
                                            : null;
                                    }

                                    return VideoPlayerWidget(
                                        media: _posts[index]
                                    );
                                },
                                childCount: _posts.length + (_hasMore ? 1 : 0),
                            ),
                        ),
                    ],
                ),
            ),
        );
    }

    @override
    void dispose() {
        _scrollController.dispose();
        super.dispose();
    }
}
```

### 3. Creator Post Creation Flow

```dart
class CreatePostDialog extends StatefulWidget {
    @override
    _CreatePostDialogState createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
    final _formKey = GlobalKey<FormState>();
    final _titleController = TextEditingController();
    final _captionController = TextEditingController();
    String _selectedAgeRating = 'below 18';
    File? _videoFile;
    File? _thumbnailFile;
    bool _isUploading = false;

    Future<void> _pickVideo() async {
        final result = await ImagePicker().pickVideo(
            source: ImageSource.gallery,
            maxDuration: Duration(minutes: 10),
        );
        if (result != null) {
            setState(() => _videoFile = File(result.path));
            // Generate thumbnail automatically
            final thumbnail = await VideoThumbnail.thumbnailFile(
                video: result.path,
                imageFormat: ImageFormat.JPEG,
                quality: 75,
            );
            if (thumbnail != null) {
                setState(() => _thumbnailFile = File(thumbnail));
            }
        }
    }

    Future<void> _uploadPost() async {
        if (!_formKey.currentState!.validate() ||
            _videoFile == null ||
            _thumbnailFile == null) {
            return;
        }

        setState(() => _isUploading = true);
        try {
            final formData = FormData.fromMap({
                'title': _titleController.text,
                'caption': _captionController.text,
                'ageRating': _selectedAgeRating,
                'video': await MultipartFile.fromFile(_videoFile!.path),
                'thumbnail': await MultipartFile.fromFile(_thumbnailFile!.path),
            });

            await ApiClient().post('/media/upload', data: formData);
            Navigator.of(context).pop(true); // true indicates successful upload
        } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to upload post: ${e.toString()}'))
            );
        } finally {
            setState(() => _isUploading = false);
        }
    }

    @override
    Widget build(BuildContext context) {
        return Dialog(
            child: Container(
                padding: EdgeInsets.all(16),
                width: 400,
                child: Form(
                    key: _formKey,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            TextFormField(
                                controller: _titleController,
                                decoration: InputDecoration(labelText: 'Title'),
                                validator: (v) => v?.isEmpty ?? true
                                    ? 'Title is required'
                                    : null,
                            ),
                            TextFormField(
                                controller: _captionController,
                                decoration: InputDecoration(labelText: 'Caption'),
                                validator: (v) => v?.isEmpty ?? true
                                    ? 'Caption is required'
                                    : null,
                            ),
                            DropdownButtonFormField<String>(
                                value: _selectedAgeRating,
                                items: ['below 18', '18 plus']
                                    .map((e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                    ))
                                    .toList(),
                                onChanged: (v) => setState(() =>
                                    _selectedAgeRating = v ?? 'below 18'),
                                decoration: InputDecoration(
                                    labelText: 'Age Rating'
                                ),
                            ),
                            SizedBox(height: 16),
                            if (_videoFile == null)
                                ElevatedButton(
                                    onPressed: _pickVideo,
                                    child: Text('Pick Video'),
                                )
                            else
                                Row(
                                    children: [
                                        Icon(Icons.check_circle,
                                            color: Colors.green),
                                        SizedBox(width: 8),
                                        Text('Video Selected'),
                                        Spacer(),
                                        TextButton(
                                            onPressed: _pickVideo,
                                            child: Text('Change'),
                                        ),
                                    ],
                                ),
                            if (_thumbnailFile != null)
                                Image.file(
                                    _thumbnailFile!,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                ),
                            SizedBox(height: 16),
                            ElevatedButton(
                                onPressed: _isUploading ? null : _uploadPost,
                                child: _isUploading
                                    ? CircularProgressIndicator()
                                    : Text('Upload Post'),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }

    @override
    void dispose() {
        _titleController.dispose();
        _captionController.dispose();
        super.dispose();
    }
}
```

## Error Handling

```dart
try {
    // API call
} catch (e) {
    if (e.response?.statusCode == 401) {
        // Handle unauthorized access
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => LoginScreen()));
    } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.response?.data['message'] ?? 'Error occurred'))
        );
    }
}
```

## Shared Preferences Keys

```dart
const String TOKEN_KEY = 'auth_token';
const String USER_ROLE_KEY = 'user_role';
const String USER_ID_KEY = 'user_id';
const String USERNAME_KEY = 'username';
```

Remember to:

1. Implement proper error handling for all API calls
2. Use loading indicators during API calls
3. Implement proper state management (e.g., Provider, Bloc, or GetX)
4. Handle video caching for better performance
5. Implement pull-to-refresh for feed updates
