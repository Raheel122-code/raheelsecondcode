import '../../auth/models/user_model.dart';

class MediaModel {
  final String id;
  final String title;
  final String caption;
  final String video;
  final String thumbnail;
  final String ageRating;
  final UserModel uploader;
  final double averageRating;
  final int totalComments;
  final int totalRatings;
  final List<CommentModel> comments;
  final Map<String, int> ratingDistribution;
  final List<String> recentComments;
  final DateTime createdAt;

  MediaModel({
    required this.id,
    required this.title,
    required this.caption,
    required this.video,
    required this.thumbnail,
    required this.ageRating,
    required this.uploader,
    required this.averageRating,
    required this.totalComments,
    required this.totalRatings,
    required this.comments,
    required this.ratingDistribution,
    required this.recentComments,
    required this.createdAt,
  });

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      caption: json['caption'] ?? '',
      video: json['video'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      ageRating: json['ageRating'] ?? 'below 18',
      uploader: UserModel.fromJson(json['uploader'] ?? {}),
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalComments: json['totalComments'] ?? 0,
      totalRatings: json['totalRatings'] ?? 0,
      comments:
          (json['comments'] as List?)
              ?.map((e) => CommentModel.fromJson(e))
              .toList() ??
          [],
      ratingDistribution:
          json['ratingDistribution'] != null
              ? Map<String, int>.from(json['ratingDistribution'])
              : {},
      recentComments:
          (json['recentComments'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'caption': caption,
      'video': video,
      'thumbnail': thumbnail,
      'ageRating': ageRating,
      'uploader': uploader.toJson(),
      'averageRating': averageRating,
      'totalComments': totalComments,
      'totalRatings': totalRatings,
      'comments': comments.map((e) => e.toJson()).toList(),
      'ratingDistribution': ratingDistribution,
      'recentComments': recentComments,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  MediaModel copyWith({
    String? id,
    String? title,
    String? caption,
    String? video,
    String? thumbnail,
    String? ageRating,
    UserModel? uploader,
    double? averageRating,
    int? totalComments,
    int? totalRatings,
    List<CommentModel>? comments,
    Map<String, int>? ratingDistribution,
    List<String>? recentComments,
    DateTime? createdAt,
  }) {
    return MediaModel(
      id: id ?? this.id,
      title: title ?? this.title,
      caption: caption ?? this.caption,
      video: video ?? this.video,
      thumbnail: thumbnail ?? this.thumbnail,
      ageRating: ageRating ?? this.ageRating,
      uploader: uploader ?? this.uploader,
      averageRating: averageRating ?? this.averageRating,
      totalComments: totalComments ?? this.totalComments,
      totalRatings: totalRatings ?? this.totalRatings,
      comments: comments ?? this.comments,
      ratingDistribution: ratingDistribution ?? this.ratingDistribution,
      recentComments: recentComments ?? this.recentComments,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CommentModel {
  final String id;
  final String text;
  final DateTime createdAt;
  final UserModel user;

  CommentModel({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.user,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['_id'] ?? '',
      text: json['text'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'user': user.toJson(),
    };
  }
}

enum AgeRating {
  below18('below 18'),
  above18('18 plus');

  final String value;
  const AgeRating(this.value);

  factory AgeRating.fromString(String value) {
    return AgeRating.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AgeRating.below18,
    );
  }
}
