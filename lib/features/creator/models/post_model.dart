class Post {
  final String id;
  final String title;
  final String caption;
  final String videoUrl;
  final String thumbnailUrl;
  final double averageRating;
  final int commentsCount;
  final int ratingsCount;
  final String creatorId;
  final String creatorUsername;
  final String? creatorProfilePic;

  Post({
    required this.id,
    required this.title,
    required this.caption,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.averageRating,
    required this.commentsCount,
    required this.ratingsCount,
    required this.creatorId,
    required this.creatorUsername,
    this.creatorProfilePic,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'],
      title: json['title'],
      caption: json['caption'],
      videoUrl: json['video'],
      thumbnailUrl: json['thumbnail'],
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      commentsCount: json['commentsCount'] ?? 0,
      ratingsCount: json['ratingsCount'] ?? 0,
      creatorId: json['uploader']['_id'],
      creatorUsername: json['uploader']['username'],
      creatorProfilePic: json['uploader']['profilePic'],
    );
  }
}

class Comment {
  final String id;
  final String text;
  final DateTime createdAt;
  final CommentUser user;

  Comment({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.user,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'],
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
      user: CommentUser.fromJson(json['user']),
    );
  }
}

class CommentUser {
  final String id;
  final String username;
  final String? profilePic;

  CommentUser({required this.id, required this.username, this.profilePic});

  factory CommentUser.fromJson(Map<String, dynamic> json) {
    return CommentUser(
      id: json['_id'],
      username: json['username'],
      profilePic: json['profilePic'],
    );
  }
}

class PostDetails {
  final Post post;
  final List<Comment> comments;

  PostDetails({required this.post, required this.comments});

  factory PostDetails.fromJson(Map<String, dynamic> json) {
    return PostDetails(
      post: Post.fromJson(json),
      comments:
          (json['comments'] as List)
              .map((comment) => Comment.fromJson(comment))
              .toList(),
    );
  }
}
