import 'dart:io';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../feed/models/media_model.dart';

class CreatorService {
  final ApiClient _apiClient;

  CreatorService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  bool _isValidVideoFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ext == 'mp4';
  }

  bool _isValidImageFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif'].contains(ext);
  }

  bool _isValidMongoId(String id) {
    return RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id);
  }

  Future<Map<String, dynamic>> getPostStats(String mediaId) async {
    if (mediaId.isEmpty) {
      throw ValidationException('Media ID is required');
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.getMediaStats(mediaId),
    );

    return {
      'totalComments': response['data']['totalComments'] as int,
      'totalRatings': response['data']['totalRatings'] as int,
      'averageRating': response['data']['averageRating'] as double,
      'ratingDistribution': Map<String, int>.from(
        response['data']['ratingDistribution'],
      ),
      'recentComments': List<String>.from(response['data']['recentComments']),
    };
  }

  Future<MediaModel> uploadVideo({
    required String title,
    required String caption,
    required String ageRating,
    required String videoPath,
    required String thumbnailPath,
  }) async {
    try {
      // Validate input parameters
      if (title.trim().isEmpty) {
        throw ValidationException('Title is required');
      }

      if (caption.trim().isEmpty) {
        throw ValidationException('Caption is required');
      }

      if (!['below 18', '18 plus'].contains(ageRating)) {
        throw ValidationException(
          'Invalid age rating. Must be either "below 18" or "18 plus"',
        );
      }

      // Validate files
      final videoFile = File(videoPath);
      final thumbnailFile = File(thumbnailPath);

      if (!videoFile.existsSync()) {
        throw ValidationException('Video file not found');
      }

      if (!thumbnailFile.existsSync()) {
        throw ValidationException('Thumbnail file not found');
      }

      if (!_isValidVideoFile(videoPath)) {
        throw ValidationException('Invalid video file format. Must be MP4');
      }

      if (!_isValidImageFile(thumbnailPath)) {
        throw ValidationException(
          'Invalid thumbnail file format. Must be JPG, PNG or GIF',
        );
      }

      // Create form data with proper field names matching the backend
      final formData = {
        'title': title.trim(),
        'caption': caption.trim(),
        'ageRating': ageRating,
        'video': videoPath,
        'thumbnail': thumbnailPath,
      };

      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.uploadMedia,
        formData: formData,
      );

      if (response['data'] == null) {
        throw ApiException(
          code: 500,
          message: 'Invalid response format from server',
          type: 'ServerError',
        );
      }

      return MediaModel.fromJson(response['data']);
    } catch (e) {
      if (e is ApiException || e is ValidationException) {
        rethrow;
      }
      throw ApiException(
        code: 500,
        message: 'Failed to upload video: ${e.toString()}',
        type: 'UploadError',
      );
    }
  }

  Future<Map<String, dynamic>> getCreatorFeed(
    String userId, {
    int page = 1,
    int limit = 10,
  }) async {
    if (userId.isEmpty) {
      throw ValidationException('User ID is required');
    }

    if (!_isValidMongoId(userId)) {
      throw ValidationException('Invalid user ID format');
    }

    if (page < 1) {
      throw ValidationException('Page number must be greater than 0');
    }

    if (limit < 1 || limit > 50) {
      throw ValidationException('Limit must be between 1 and 50');
    }

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConstants.getCreatorFeed}/$userId',
        queryParams: {'page': page.toString(), 'limit': limit.toString()},
      );

      if (response['data'] == null || response['pagination'] == null) {
        throw ApiException(
          code: 500,
          message: 'Invalid response format from server',
          type: 'ServerError',
        );
      }

      final List<MediaModel> videos =
          (response['data'] as List)
              .map((item) => MediaModel.fromJson(item))
              .toList();

      final pagination = response['pagination'] as Map<String, dynamic>;
      return {
        'videos': videos,
        'pagination': {
          'currentPage': pagination['currentPage'] as int,
          'hasMore': pagination['hasMore'] as bool,
          'totalPages': pagination['totalPages'] as int,
          'total': pagination['total'] as int,
        },
      };
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        code: 500,
        message: 'Failed to fetch creator feed: ${e.toString()}',
        type: 'FetchError',
      );
    }
  }

  Future<MediaModel> getMediaById(String mediaId) async {
    if (mediaId.isEmpty) {
      throw ValidationException('Media ID is required');
    }

    if (!_isValidMongoId(mediaId)) {
      throw ValidationException('Invalid media ID format');
    }

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.getMediaById(mediaId),
      );

      if (response['data'] == null) {
        throw ApiException(
          code: 500,
          message: 'Invalid response format from server',
          type: 'ServerError',
        );
      }

      return MediaModel.fromJson(response['data']);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        code: 500,
        message: 'Failed to fetch media: ${e.toString()}',
        type: 'FetchError',
      );
    }
  }

  Future<MediaModel> addComment(String mediaId, String text) async {
    if (mediaId.isEmpty) {
      throw ValidationException('Media ID is required');
    }

    if (!_isValidMongoId(mediaId)) {
      throw ValidationException('Invalid media ID format');
    }

    if (text.trim().isEmpty) {
      throw ValidationException('Comment text is required');
    }

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.addComment(mediaId),
        body: {'text': text.trim()},
      );

      if (response['data'] == null) {
        throw ApiException(
          code: 500,
          message: 'Invalid response format from server',
          type: 'ServerError',
        );
      }

      return MediaModel.fromJson(response['data']);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        code: 500,
        message: 'Failed to add comment: ${e.toString()}',
        type: 'CommentError',
      );
    }
  }

  Future<MediaModel> rateMedia(String mediaId, int value) async {
    if (mediaId.isEmpty) {
      throw ValidationException('Media ID is required');
    }

    if (!_isValidMongoId(mediaId)) {
      throw ValidationException('Invalid media ID format');
    }

    if (value < 1 || value > 10) {
      throw ValidationException('Rating must be between 1 and 10');
    }

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.rateMedia(mediaId),
        body: {'value': value},
      );

      if (response['data'] == null) {
        throw ApiException(
          code: 500,
          message: 'Invalid response format from server',
          type: 'ServerError',
        );
      }

      return MediaModel.fromJson(response['data']);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        code: 500,
        message: 'Failed to rate media: ${e.toString()}',
        type: 'RatingError',
      );
    }
  }

  Future<String> updateProfilePicture(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        throw ValidationException('Image file not found');
      }

      if (!_isValidImageFile(imagePath)) {
        throw ValidationException(
          'Invalid image file format. Must be JPG, PNG or GIF',
        );
      }

      final formData = {'image': imagePath};

      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.uploadProfilePicture,
        formData: formData,
      );

      if (response['data'] == null || response['data']['profilePic'] == null) {
        throw ApiException(
          code: 500,
          message: 'Invalid response format from server',
          type: 'ServerError',
        );
      }

      return response['data']['profilePic'];
    } catch (e) {
      if (e is ApiException || e is ValidationException) {
        rethrow;
      }
      throw ApiException(
        code: 500,
        message: 'Failed to update profile picture: ${e.toString()}',
        type: 'UploadError',
      );
    }
  }
}
