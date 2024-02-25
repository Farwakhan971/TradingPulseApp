import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'viewpost.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_extend/share_extend.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_player.dart';
import 'package:flutter_sound/public/ui/sound_player_ui.dart';
import 'comment_model.dart';
import 'to_display_full_image.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
class PostDetailPage extends StatefulWidget {
  final Post post;
  PostDetailPage({Key? key, required this.post}) : super(key: key);
  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}
class _PostDetailPageState extends State<PostDetailPage> {
  Future<VideoPlayerController> _initializeVideoPlayer(String videoUrl) async {
    final VideoPlayerController videoPlayerController = VideoPlayerController.network(videoUrl);
    await videoPlayerController.initialize();
    return videoPlayerController;
  }
  final TextEditingController _commentController = TextEditingController();
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  bool isCommentFieldFocused = false;
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _commentFocusNode.addListener(() {
      setState(() {
        isCommentFieldFocused = _commentFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    // Dispose the FocusNode
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<String?> _fetchUrlContent(String url) async {
    return "URL Content for $url";
  }

  String convertToEmbedUrl(String url) {
    if (url.contains("youtube.com/watch?v=")) {
      Uri uri = Uri.parse(url);
      String? videoId = uri.queryParameters['v'];
      return 'https://www.youtube.com/embed/$videoId';
    } else {
      return url;
    }
  }

  void _submitComment(String commentText, Post post) {
    if (commentText.isNotEmpty) {
      final DatabaseReference postRef = _database.child('posts').child(post.key);
      String userEmail = FirebaseAuth.instance.currentUser?.email ?? ''; // Get the current user's email

      postRef.once().then((DatabaseEvent event) {
        final data = event.snapshot.value;

        if (data != null && data is Map) { // Type check before casting
          Map<dynamic, dynamic> postData = data as Map<dynamic, dynamic>;
          List<dynamic> currentComments = List<dynamic>.from(postData['comments'] ?? []);

          // Add comment text and timestamp as a map
          int timestamp = DateTime.now().millisecondsSinceEpoch;
          Map<String, dynamic> newComment = {
            'userId': userEmail,
            'text': commentText,
            'timestamp': timestamp
          };
          currentComments.add(newComment);
          postRef.update({'comments': currentComments}).then((_) {
            setState(() {
              post.comments.add(Comment.fromMap(newComment, userEmail));
            });
          });
        } else {
          print('Unknown data type: ${data.runtimeType}');
        }
      });
    }
  }
  Future<void> _submitCommentWithAnimation(String commentText, Post post) async {
    if (commentText.isNotEmpty) {
      // Fade-out animation
      await Future.delayed(Duration(milliseconds: 300));
      _submitComment(commentText, post);
    }
  }
  Future<void> openURL(String url) async {
    print('Attempting to launch URL: $url');
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch URL: $url');
    }
  }

  Future<void> _launchURL(String url) async {
    print('Attempting to launch URL: $url');
    try {
      if (await canLaunch(url)) {
        await launch(url);
        print('Launched URL successfully');
      } else {
        print('Could not launch URL: $url');
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }
  String getInitials(String name) {
    List<String> names = name.split(' ');
    String initials = '';
    if (names.length > 1) {
      initials = names[0][0] + names[1][0];
    } else if (names.isNotEmpty) {
      initials = names[0][0];
    }
    return initials.toUpperCase();
  }
  void sharePostContent() {
    String contentToShare = 'Check out this post: ${widget.post.title}\n\n${widget.post.body}';

    if (widget.post.images.isNotEmpty) {
      contentToShare += '\n\nImages:\n' + widget.post.images.join('\n');
    }
    if (widget.post.videos.isNotEmpty) {
      contentToShare += '\n\nVideos:\n' + widget.post.videos.join('\n');
    }
    if (widget.post.audioPath != null && widget.post.audioPath!.isNotEmpty) {
      contentToShare += '\n\nAudio: ${widget.post.audioPath}';
    }
    if (widget.post.urls.isNotEmpty) {
      contentToShare += '\n\nURLs:\n' + widget.post.urls.where((url) => url != null).join('\n');
    }

    Share.share(contentToShare);
  }
  Future<File> _downloadFile(String url, String fileType) async {
    final response = await http.get(Uri.parse(url));
    final documentDirectory = await getTemporaryDirectory();

    final file = File(join(documentDirectory.path, '${DateTime.now().millisecondsSinceEpoch}.$fileType'));
    file.writeAsBytesSync(response.bodyBytes);

    return file;
  }
  Color getColorForInitial(String initial) {
    Map<String, Color> colorMap = {
      'A': Colors.orange,
      'B': Colors.blue,
      'C': Colors.cyan,
      'D': Colors.deepPurple,
      'E': Colors.green,
      'F': Colors.blueGrey,
      'G': Colors.pink,
      'H': Colors.red,
      'I': Colors.lightGreen,
      'J': Colors.brown,
      'K': Colors.indigo,
      'L': Colors.tealAccent,
      'M': Colors.lightBlueAccent,
      'N': Colors.purpleAccent,
      'O': Colors.amberAccent,
      'P': Colors.teal,
      'Q': Colors.lime,
      'R': Colors.greenAccent,
      'S': Colors.cyanAccent,
      'T': Color(0xFFB03060),
      'U': Colors.yellow,
      'V': Color(0xFF8A2BE2),
      'W': Colors.deepOrange,
      'X': Colors.pink,
      'Y': Colors.yellowAccent,
      'Z': Color(0xFF7E7E7E),
    };
    String uppercaseInitial = initial.toUpperCase();
    return colorMap[uppercaseInitial] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            widget.post.title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          elevation: 10.0,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(4.0),
            child: Container(
              height: 4.0,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white10, Colors.white30, Colors.white10],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.body,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 20),
                if (widget.post.images.isNotEmpty) ...[
                  buildSectionTitle('Images'),
                  SizedBox(height: 10),
                  buildImageSection(widget.post.images),
                ],
                SizedBox(height: 20),
                if (widget.post.audioPath != null && widget.post.audioPath!.isNotEmpty) ...[
                  buildSectionTitle('Audio'),
                  SizedBox(height: 10),
                  buildAudio(),
                ],
                SizedBox(height: 20),
                if (widget.post.videos.isNotEmpty) ...[
                  buildSectionTitle('Videos'),
                  SizedBox(height: 10),
                  buildVideoSection(widget.post.videos),
                ],
                SizedBox(height: 20),
                if (widget.post.urls.isNotEmpty) ...[
                  buildSectionTitle('URLs'),
                  SizedBox(height: 10),
                  buildURLsSection(),
                ],
                SizedBox(height: 30),
                buildSectionTitle('Comments'),
                SizedBox(height: 10),
                _buildCommentInput(widget.post),
                _buildCommentsSection(widget.post),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget buildSectionTitle(String title) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [
            Colors.white, // Starting with white
            Colors.grey, // A very light grey, closer to white
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height));
      },
      blendMode: BlendMode.srcIn,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 0.5,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget buildComment(Comment comment) {
    String initials = getInitials(comment.userId); // Make sure getInitials function exists
    Color avatarColor = getColorForInitial(initials.isNotEmpty ? initials[0] : '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: avatarColor,
            child: Text(initials, style: TextStyle(color: Colors.white)),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      comment.userId,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      comment.formattedTimestamp,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Text(
                  comment.text,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Inside PostDetailPage class
  Widget _buildCommentsSection(Post post) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: post.comments.length,
      itemBuilder: (context, index) {
        final comment = post.comments[index];
        return buildComment(comment);
      },
    );
  }
  Widget buildImageSection(List<String> images) {
    return Container(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FullScreenImagePage(imageUrl: images[index]),
                ),
              );

            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(images[index]), // Changed to Image.network
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildVideoSection(List<String> videos) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: videos.map((videoUrl) {
          return Container(
            width: 300,
            height: 200,
            margin: EdgeInsets.only(right: 10),
            child: FutureBuilder(
              future: _initializeVideoPlayer(videoUrl),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return Center(child: Icon(Icons.videocam_off));
                  }
                  return Chewie(
                    controller: ChewieController(
                      videoPlayerController: VideoPlayerController.network(videoUrl),
                      autoPlay: false,
                      looping: false,
                      aspectRatio: 16 / 9,
                      autoInitialize: true,
                      materialProgressColors: ChewieProgressColors(
                        playedColor: Colors.red,
                        handleColor: Colors.white,
                        backgroundColor: Colors.grey.withOpacity(0.5),
                        bufferedColor: Colors.grey[800]!,
                      ),
                    ),
                  );
                } else {
                  return Center(
                    child: SizedBox(
                      height: 20.0, // Adjust the size of the CircularProgressIndicator
                      width: 20.0, // Adjust the size of the CircularProgressIndicator
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0, // Adjust the stroke width of the circle
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Set the color to black
                      ),
                    ),
                  );
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildURLsSection() {
    return SizedBox(
      height: 200,
      child: SingleChildScrollView(
        child: Column(
          children: widget.post.urls.map((String? url) {
            if (url!.contains('youtube.com') || url.contains('youtu.be')) {
              // It's a YouTube URL, use the YouTube player widget
              String videoId = YoutubePlayer.convertUrlToId(url)!;
              return YoutubePlayer(
                controller: YoutubePlayerController(
                  initialVideoId: videoId,
                  flags: YoutubePlayerFlags(autoPlay: false),
                ),
              );
            } else {
              String displayUrl = convertToEmbedUrl(url);
              return GestureDetector(
                onTap: () async {
                  if (await canLaunch(url)) {
                    await launch(url);
                  } else {
                    throw 'Could not launch $url';
                  }
                },
                child: AbsorbPointer(
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    child: WebView(
                      initialUrl: displayUrl,
                      javascriptMode: JavascriptMode.unrestricted,
                      gestureNavigationEnabled: true,
                    ),
                  ),
                ),
              );
            }
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCommentInput(Post post) {
    return Column(
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            border: Border.all(
              color: isCommentFieldFocused ? Colors.white : Colors.grey,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: TextField(
            controller: _commentController,
            focusNode: _commentFocusNode,
            decoration: InputDecoration(
              labelText: 'Write a comment...',
              border: InputBorder.none,
              labelStyle: TextStyle(
                color: isCommentFieldFocused ? Colors.grey[700] : Colors.grey,
              ),
            ),
            cursorColor: Colors.white,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            onTap: () => setState(() => isCommentFieldFocused = true),
            onEditingComplete: () => setState(() => isCommentFieldFocused = false),
          ),
        ),

        SizedBox(height: 20),

        // Animated Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: Colors.white, // Background color
            onPrimary: Colors.black, // Text color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          ),
          onPressed: () async {
            // Comment submission animation
            await _submitCommentWithAnimation(_commentController.text, post);
            _commentController.clear();
          },
          child: Text('Submit Comment'),
        ),

        SizedBox(height: 20),
      ],
    );
  }
  Widget buildAudio() {
    if (widget.post.audioPath != null && widget.post.audioPath!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10),
          SoundPlayerUI.fromLoader(
                (context) async {
              return Track(
                trackPath: widget.post.audioPath,
              );
            },
            sliderThemeData: SliderThemeData(
              activeTickMarkColor: Colors.black,
              disabledActiveTickMarkColor: Colors.black,
              activeTrackColor: Colors.black,
              inactiveTrackColor: Colors.grey[300],
              thumbColor: Colors.black,
              overlayColor: Colors.black.withOpacity(0.2),
              trackHeight: 3.0,
            ),
            iconColor: Colors.black,
            textStyle: TextStyle(color: Colors.black),
            backgroundColor: Colors.white,
          ),
        ],
      );
    } else {
      return Container();
    }
  }
}