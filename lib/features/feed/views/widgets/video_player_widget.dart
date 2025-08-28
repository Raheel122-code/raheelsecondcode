import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/media_model.dart';

class VideoPlayerWidget extends StatefulWidget {
  final MediaModel media;
  final bool autoplay;
  final bool showControls;
  final bool expandedView;
  final VoidCallback? onTap;

  const VideoPlayerWidget({
    Key? key,
    required this.media,
    this.autoplay = false,
    this.showControls = false,
    this.expandedView = false,
    this.onTap,
  }) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with AutomaticKeepAliveClientMixin {
  late VideoPlayerController _controller;
  bool _isHovering = false;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlaying = false;
  double? _cachedAspectRatio;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media.video != widget.media.video) {
      _disposeController();
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.network(widget.media.video);

      await _controller.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
          _cachedAspectRatio = _controller.value.aspectRatio;
        });

        if (widget.autoplay) {
          _controller.play();
          _controller.setLooping(true);
          setState(() {
            _isPlaying = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitialized = false;
        });
      }
    }
  }

  void _disposeController() {
    _controller.pause();
    _controller.dispose();
    _isInitialized = false;
    _hasError = false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.expandedView) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (!_isInitialized || _hasError) _buildThumbnail(),
          if (_isInitialized && !_hasError) _buildVideoPlayer(),
          if (widget.showControls && _isInitialized) _buildControls(),
          if (!_isInitialized && !_hasError)
            const Center(child: CircularProgressIndicator()),
          if (_hasError) _buildErrorWidget(),
        ],
      );
    }

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!_isInitialized || !_isHovering || _hasError) _buildThumbnail(),
          if (_isInitialized && _isHovering && !_hasError) _buildVideoPlayer(),
          _buildOverlay(),
          Material(
            color: Colors.transparent,
            child: InkWell(onTap: widget.onTap),
          ),
          if (!_isInitialized && !_hasError)
            const Center(child: CircularProgressIndicator()),
          if (_hasError) _buildErrorWidget(),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    return Image.network(
      widget.media.thumbnail,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported, size: 40),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildVideoPlayer() {
    if (_cachedAspectRatio == null) return const SizedBox();

    return Center(
      child: AspectRatio(
        aspectRatio: _cachedAspectRatio!,
        child: VideoPlayer(_controller),
      ),
    );
  }

  Widget _buildOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.media.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text(
                  widget.media.averageRating.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.comment, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  widget.media.totalComments.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Stack(
      children: [
        // Play/Pause button in center
        Center(
          child: AnimatedOpacity(
            opacity: _isHovering || !_isPlaying ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: _togglePlayPause,
              ),
            ),
          ),
        ),
        // Progress bar at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              ),
            ),
            child: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, VideoPlayerValue value, child) {
                return Column(
                  children: [
                    Slider(
                      value: value.position.inSeconds.toDouble(),
                      min: 0,
                      max: value.duration.inSeconds.toDouble(),
                      onChanged: (newPosition) {
                        _controller.seekTo(
                          Duration(seconds: newPosition.toInt()),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(value.position),
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            _formatDuration(value.duration),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 8),
          TextButton(onPressed: _initializeVideo, child: const Text('Retry')),
        ],
      ),
    );
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _controller.play();
      } else {
        _controller.pause();
      }
    });
  }

  void _onHover(bool hovering) {
    if (!mounted || !_isInitialized || _hasError) return;

    setState(() {
      _isHovering = hovering;
      if (hovering) {
        _controller.play();
        _controller.setLooping(true);
        _isPlaying = true;
      } else {
        _controller.pause();
        _controller.seekTo(Duration.zero);
        _isPlaying = false;
      }
    });
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }
}
