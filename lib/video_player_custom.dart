import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class VideoItem extends StatefulWidget {
  final String videoUrl; // This should be the direct download URL from Firebase Storage
  final String thumbnailUrl;

  VideoItem({required this.videoUrl, required this.thumbnailUrl});

  @override
  _VideoItemState createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isVideoLoaded = false;
  ImageProvider? _thumbnailImage;
  bool _isThumbnailPreCached = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isThumbnailPreCached) {
      _thumbnailImage = AssetImage(widget.thumbnailUrl);
      precacheImage(_thumbnailImage!, context);
      _isThumbnailPreCached = true;
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _initializeAndPlayVideo() async {
    if (!_isVideoLoaded) {
      // Initialize VideoPlayerController with the direct download URL
      _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
      await _videoPlayerController!.initialize().catchError((error) {
        print('Error initializing video: $error');
      });

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: 16 / 9,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red,
          handleColor: Colors.white,
          backgroundColor: Colors.black.withOpacity(0.5),
          bufferedColor: Colors.white24,
        ),
        errorBuilder: (context, errorMessage) {
          return Center(child: Text(errorMessage, style: TextStyle(color: Colors.white)));
        },
      );

      setState(() {
        _isVideoLoaded = true;
      });
    } else {
      if (!_chewieController!.isPlaying) {
        _chewieController?.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _initializeAndPlayVideo,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[400]!, width: 1),
        ),
        child: _isVideoLoaded && _chewieController != null
            ? Chewie(controller: _chewieController!)
            : Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_circle_outline, // Play icon
                color: Colors.white,
                size: 40,
              ),
              SizedBox(height: 8), // Spacing
              Text(
                'Tap to play',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
