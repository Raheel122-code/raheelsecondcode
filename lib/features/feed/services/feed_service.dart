import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/media_model.dart';

class FeedResponse {
  final List<MediaModel> media;
  final PaginationInfo pagination;
  final String message;

  FeedResponse({
    required this.media,
    required this.pagination,
    required this.message,
  });

  factory FeedResponse.fromJson(Map<String, dynamic> json) {
    return FeedResponse(
      media:
          (json['data'] as List?)
              ?.map((item) => MediaModel.fromJson(item))
              .toList() ??
          [],
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
      message: json['message'] ?? '',
    );
  }
}

class PaginationInfo {
  final int currentPage;
  final bool hasMore;
  final int totalPages;
  final int total;

  PaginationInfo({
    required this.currentPage,
    required this.hasMore,
    required this.totalPages,
    required this.total,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['currentPage'] ?? 1,
      hasMore: json['hasMore'] ?? false,
      totalPages: json['totalPages'] ?? 1,
      total: json['total'] ?? 0,
    );
  }
}

class FeedService {
  final ApiClient _apiClient;

  FeedService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<FeedResponse> getFeed({int page = 1, int limit = 10}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.getFeed,
      queryParams: {'page': page.toString(), 'limit': limit.toString()},
    );

    return FeedResponse.fromJson(response);
  }

  Future<FeedResponse> getCreatorFeed(
    String userId, {
    int page = 1,
    int limit = 10,
  }) async {
    if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(userId)) {
      throw FormatException('Invalid user ID format');
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.getCreatorFeed}/$userId',
      queryParams: {'page': page.toString(), 'limit': limit.toString()},
    );

    return FeedResponse.fromJson(response);
  }

  Future<Map<String, dynamic>> getPostStats(String postId) async {
    if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(postId)) {
      throw FormatException('Invalid post ID format');
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.getMediaStats(postId),
    );

    final data = response['data'];
    if (data == null) {
      throw Exception('Post statistics not found');
    }

    return data;
  }

  Future<MediaModel> addComment(String postId, String text) async {
    if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(postId)) {
      throw FormatException('Invalid post ID format');
    }

    if (text.trim().isEmpty) {
      throw ArgumentError('Comment text cannot be empty');
    }

    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.addComment(postId),
      body: {'text': text},
    );

    final data = response['data'];
    if (data == null) {
      throw Exception('Failed to add comment');
    }

    return MediaModel.fromJson(data);
  }

  Future<MediaModel> addRating(String postId, int value) async {
    if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(postId)) {
      throw FormatException('Invalid post ID format');
    }

    if (value < 1 || value > 10) {
      throw ArgumentError('Rating value must be between 1 and 10');
    }

    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.rateMedia(postId),
      body: {'value': value},
    );

    final data = response['data'];
    if (data == null) {
      throw Exception('Failed to add rating');
    }

    return MediaModel.fromJson(data);
  }
}
