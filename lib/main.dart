import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sound/public/flutter_sound_player.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:flutter_sound/public/ui/sound_player_ui.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:trading_admin/video_player_custom.dart';
import 'package:trading_admin/webview_custom.dart';
import 'Sign_up.dart';
import 'audiorecorder.dart';
import 'login_screen.dart';
import 'splash_screen.dart';
import 'viewpost.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:chewie/chewie.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
class FirebaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();

  Future<void> submitPost(Post post) async {
    try {
      DatabaseReference newPostRef = _database.child('posts').push();
      Map<String, dynamic> postData = {
        'title': post.title,
        'body': post.body,
        'topics': post.topics,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'audioPath': post.audioPath,
        'images': post.images, // Directly use the list of image URLs
        'videos': post.videos, // Directly use the list of video URLs
        'urls': post.urls,
      };

      // Set the post data at the new reference
      await newPostRef.set(postData);
    } catch (e) {
      print('Error submitting post: $e');
    }
  }

}

class Post {
  String title;
  String body;
  List<String> topics;
  List<String> images; // URLs of images
  List<String> videos; // URLs of videos
  List<String?> urls;
  String? audioPath;
  Post({
    required this.title,
    required this.body,
    required this.topics,
    required this.images,
    required this.videos,
    required this.urls,
    required this.audioPath,
  });
}
void main() async {
  FirebaseAuth.instance.signOut();
  WidgetsFlutterBinding.ensureInitialized();
  Platform.isAndroid
      ? await Firebase.initializeApp(
    options: const FirebaseOptions(
        apiKey: "AIzaSyDa_mzaO0Du8zEZL_EBKRbqNBMk7ZZc92k",
        appId: "1:635722570599:android:b5a4d1514a08dbf983edc2",
        messagingSenderId: "635722570599",
        projectId: "trading-app-3a52f",
        storageBucket: 'gs://trading-app-3a52f.appspot.com',
    ),
  )
      : await Firebase.initializeApp();
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/allpost': (context) => AllPostsPage(),
      },
    );
  }
}
class PostPage extends StatefulWidget {
  @override
  _PostPageState createState() => _PostPageState();
}
class _PostPageState extends State<PostPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GlobalKey<AudioRecorderPageState> _recorderPageKey = GlobalKey<
      AudioRecorderPageState>();
  final FlutterSoundRecorder? recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer? player = FlutterSoundPlayer();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _bodyController = TextEditingController();
  List<String> _selectedTopics = [];
  List<File> _selectedImages = [];
  List<File> _selectedVideos = [];
  List<String?> _enteredUrls = [];
  String? _audioPath;
  String? _audioUrl;
  bool _isPreviewButtonEnabled = true;// URL for the uploaded audio file
  bool _isLoading = false;
  void _handleRecordingStateChanged(bool isRecording) {
    if (isRecording) {
      setState(() => _isPreviewButtonEnabled = true);
    } else {
      setState(() => _isPreviewButtonEnabled = false);
      Future.delayed(Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _isPreviewButtonEnabled = true);
        }
      });
    }
  }
  Future<void> _pickImage() async {
    final ImagePicker _imagePicker = ImagePicker();
    XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  Future<String> uploadFile(File file) async {
    String fileName = path.basename(file.path);
    firebase_storage.Reference storageRef =
    firebase_storage.FirebaseStorage.instance.ref().child('uploads/$fileName');

    firebase_storage.UploadTask uploadTask = storageRef.putFile(file);

    await uploadTask.whenComplete(() => null);
    String downloadUrl = await storageRef.getDownloadURL();
    return downloadUrl;
  }



  Future<void> _pickVideo() async {
    final ImagePicker _imagePicker = ImagePicker();
    XFile? pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedVideos.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _pickUrl() async {
    String? url = await _showDialog('Enter URL');
    if (url != null && url.isNotEmpty) {
      setState(() {
        _enteredUrls.add(url);
      });
    }
  }

  Future<String?> _fetchUrlContent(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  Future<void> _processDataAndShowPreview() async {
    // Set isLoading to true to display the progress indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Start with empty lists for image and video URLs
      List<String> imageUrls = [];
      List<String> videoUrls = [];

      // Upload images and get their URLs
      for (File image in _selectedImages) {
        String imageUrl = await uploadFile(image);
        imageUrls.add(imageUrl);
      }

      // Upload videos and get their URLs
      for (File video in _selectedVideos) {
        String videoUrl = await uploadFile(video);
        videoUrls.add(videoUrl);
      }
      String audioUrl = await _recorderPageKey.currentState?.stopRecording() ?? '';
      _audioPath = audioUrl.isNotEmpty ? audioUrl : _audioPath;

      Post post = Post(
        title: _titleController.text,
        body: _bodyController.text,
        topics: _selectedTopics,
        images: imageUrls,
        videos: videoUrls,
        urls: _enteredUrls,
        audioPath: _audioPath,
      );
      print("Debug: _audioPath before preview: $_audioPath");
      await Future.delayed(Duration(seconds: 5));  // Introduce a small delay
      _showPostPreview(post);
    } catch (e) {
      print('Error during processing: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
            'Create Post',
            style: TextStyle(
              color: Colors.white, // Keep the title white for consistency
              fontWeight: FontWeight.bold, // Bold for prominence
              letterSpacing: 1.2, // Letter spacing for a more refined look
            ),
          ),
          backgroundColor: Colors.black54,
          // Slightly transparent background
          elevation: 10.0,
          bottom: PreferredSize( // Optional bottom area for a subtle design element or additional options
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Enter title...',
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                      ),
                      cursorColor: Colors.white,
                    ),
                    const SizedBox(height: 25),
                    TextField(
                      controller: _bodyController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: 'What do you want to share?',
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        contentPadding: EdgeInsets.all(20.0),
                      ),
                      cursorColor: Colors.white,
                    ),
                    const SizedBox(height: 25),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            style: ElevatedButton.styleFrom(
                              primary: Colors.white,
                            ),
                            icon: const Icon(
                                Icons.add_a_photo, color: Colors.black),
                            label: const Text('Add Image',
                                style: TextStyle(color: Colors.black)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _pickUrl,
                            style: ElevatedButton.styleFrom(
                              primary: Colors.white,
                            ),
                            icon: const Icon(Icons.link, color: Colors.black),
                            label: const Text('Add URL',
                                style: TextStyle(color: Colors.black,)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _pickVideo,
                            style: ElevatedButton.styleFrom(
                              primary: Colors.white,
                            ),
                            icon: const Icon(
                                Icons.videocam, color: Colors.black),
                            label: const Text('Add Video',
                                style: TextStyle(color: Colors.black)),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                    AudioRecorderPage(
                      recorder: recorder,
                      player: player,
                      onRecordingComplete: (String uploadedAudioUrl) {
                        setState(() {
                          _audioPath = uploadedAudioUrl;
                          print("Audio path updated: $_audioPath");
                        });
                      },
                      onRecordingStateChanged: _handleRecordingStateChanged,
                      uploadFile: uploadFile,
                    ),
                    if (!_isPreviewButtonEnabled) ...[
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "Processing audio, please wait...",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white, // Adjust the color as needed
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],

                    Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child:  ElevatedButton.icon(
    onPressed: _isPreviewButtonEnabled && !_isLoading
    ? () async {
    // Check if the user is logged in
    User? user = _auth.currentUser;
    if (user != null) {
    await _processDataAndShowPreview();
    } else {
    // User is not logged in, show a message or redirect to login/signup
    showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
    return AlertDialog(
    title: Text('Authentication Required'),
    content: Text('Please log in or sign up to add a post.'),
    actions: [
    TextButton(
    onPressed: () {
    Navigator.of(dialogContext).pop();
    },
    child: Text('OK'),
    ),
    ],
    );
    },
    );
    }
    }
        : null,
    icon: _isLoading
    ? Container(
    width: 24,
    height: 24,
    padding: const EdgeInsets.all(2.0),
    child: CircularProgressIndicator(
    strokeWidth: 2.0,
    color: Colors.black,
    ),
    )
        : Icon(Icons.preview, color: Colors.black),
    label: Text(
    _isLoading ? 'Loading...' : 'Preview Post',
    style: TextStyle(
    color: Colors.black,
    fontWeight: FontWeight.bold,
    ),
    ),
    style: ElevatedButton.styleFrom(
    primary: Colors.white,
    onPrimary: Colors.white,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
    ),
    padding: EdgeInsets.symmetric(
    vertical: 14,
    horizontal: 90,
    ),
    elevation: 15,
    backgroundColor: Colors.white,
    disabledBackgroundColor: Colors.white.withOpacity(0.5),
    ),
    ),


  ),
                    ),
                  ],
                ),
        ),
      ],
    ),
    ),
    )
    );
  }

  void _showPostPreview(Post post) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        print("Debug: _audioPath when building preview: ${post.audioPath}");

        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Post Preview', style: TextStyle(color: Colors.black)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(post.body, style: const TextStyle(color: Colors.black)),
                // Display other post details like images, videos, etc.
                // Example for displaying images:
                if (post.images.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Images:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  Container(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: post.images.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: CachedNetworkImage(
                            imageUrl: post.images[index],
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                if (post.urls.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('URLs:', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 200, // Fixed height for the list
                    child: ListView.builder(
                      itemCount: post.urls.length,
                      itemBuilder: (context, index) {
                        return ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 200), // Add constraints
                          child: WebViewLoader(url: post.urls[index]!),
                        );
                      },
                    ),
                  ),
                ],
                if (_audioPath != null && _audioPath!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Audio:', style: TextStyle(color: Colors.black,
                      fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  SoundPlayerUI.fromLoader(
                    sliderThemeData: SliderThemeData(
                      activeTickMarkColor: Colors.white,
                      disabledActiveTickMarkColor: Colors.white,
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.grey[300],
                      thumbColor: Colors.white,
                      overlayColor: Colors.white.withOpacity(0.2),
                      trackHeight: 3.0,
                      thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 6.0),
                      overlayShape: RoundSliderOverlayShape(
                          overlayRadius: 10.0),
                    ),
                    iconColor: Colors.white,
                    disabledIconColor: Colors.white,
                    backgroundColor: Colors.black,
                        (context) async =>
                        Track(
                          trackPath: _audioPath,

                        ),

                  ),
                ],
                if (post.videos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Videos:', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 200,
                    child: SingleChildScrollView(
                      child: Column(
                        children: post.videos.map((videoUrl) {
                          return Container(
                            height: 200,
                            child: VideoItem(
                              videoUrl: videoUrl,
                              thumbnailUrl: 'assets/thumnail_1.png'
                              , // Placeholder thumbnail URL
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Close', style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              onPressed: () {
                _submitPost(post);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllPostsPage(),
                  ),
                );
              },
              child: const Text(
                'Submit Post',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
  void _submitPost(Post post) async {
    FirebaseService firebaseService = FirebaseService();

    try {
      await firebaseService.submitPost(post);
      print('Post Submitted: ${post.title}');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AllPostsPage()),
      );
    } catch (e) {
      print("Failed to submit post: $e");
    }
  }
  Future<String?> _showDialog(String title) async {
    TextEditingController _textFieldController = TextEditingController();
    String? value = '';
    return showDialog<String>(
      context: context, // Use the context from the surrounding widget
      builder: (BuildContext dialogContext) { // Use dialogContext here
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(title),
          titleTextStyle: TextStyle(color: Colors.black),
          content: TextField(
            controller: _textFieldController,
            autofocus: true,
            onChanged: (newValue) {
              value = newValue;
            },
            onSubmitted: (submittedValue) {
              Navigator.of(dialogContext).pop(submittedValue); // Use dialogContext here
            },
            cursorColor: Colors.black,
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'https://google.com',
              hintStyle: TextStyle(color: Colors.grey),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(null); // Use dialogContext here
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(value); // Use dialogContext here
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }
}