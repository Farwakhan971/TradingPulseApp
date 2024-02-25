import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'comment_model.dart';
import 'main.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'more_detail_post.dart';

void main() {
  runApp(MaterialApp(
      home: AllPostsPage(),
  ));
}

class AllPostsPage extends StatefulWidget {
  @override
  _AllPostsPageState createState() => _AllPostsPageState();
}

class _AllPostsPageState extends State<AllPostsPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  late List<Post> _posts = [];
  Map<String, double> _likeOpacities = {};
  Map<String, double> _dislikeOpacities = {};
  late String userEmail; // Declare userEmail here
  @override
  void initState() {
    super.initState();
    userEmail = FirebaseAuth.instance.currentUser?.email ?? ''; // Get the current user's email
    _loadPosts();
    // Initialize the opacities for the animations
    for (var post in _posts) {
      _likeOpacities[post.key] = 1.0;
      _dislikeOpacities[post.key] = 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          // Navigate to the AllPostsPage
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PostPage()), // Corrected this line
          );
        },
        child: Icon(Icons.edit, color: Colors.black,), // You can change the icon if you want
        tooltip: 'Go to add Posts', // This is optional
      ),

      appBar: AppBar(
        title: Text('All Posts'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
          onRefresh: _refreshPosts,
          child: _posts == null
              ? Center(
            child: CircularProgressIndicator(),
          )
              : ListView.builder(
            itemCount: _posts.length,
            itemBuilder: (context, index) {
              return _buildPostCard(_posts[index], index); // Pass the index here
            },
          )

      ),
    );
  }

  Future<void> _refreshPosts() async {
    await _loadPosts();
  }
  Future<List<Post>> _fetchUserPosts(String userEmail) async {
    List<Post> userPosts = [];

    try {
      // Query Firebase to fetch posts created by the logged-in user
      DatabaseEvent userPostsEvent = await _database.child('posts')
          .orderByChild('userEmail')
          .equalTo(userEmail)
          .once();

      Map<dynamic, dynamic>? userPostsValues = userPostsEvent.snapshot.value as Map<dynamic, dynamic>?;

      if (userPostsValues != null) {
        userPostsValues.forEach((key, value) {
          Post post = Post.fromMap(key, value, userEmail);
          userPosts.add(post);
        });
      }
    } catch (e) {
      print('Error loading user posts: $e');
    }

    return userPosts;
  }


  Future<void> _loadPosts() async {
    try {
      // Fetch all posts
      DatabaseEvent allPostsEvent = await _database.child('posts').once();
      List<Post> allPosts = [];

      Map<dynamic, dynamic>? allPostsValues = allPostsEvent.snapshot.value as Map<dynamic, dynamic>?;
      if (allPostsValues != null) {
        allPostsValues.forEach((key, value) {
          Post post = Post.fromMap(key, value, userEmail); // Pass the user's email here
          allPosts.add(post);
        });
        allPosts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }

      // Fetch user posts
      List<Post> userPosts = await _fetchUserPosts(userEmail);

      // Merge user posts with all posts
      List<Post> mergedPosts = [...userPosts, ...allPosts];

      setState(() {
        _posts = mergedPosts;
      });
    } catch (e) {
      print('Error loading posts: $e');
    }
  }
  void _deletePost(Post post) async {
    try {
      // Delete the post from Firebase using its key
      await _database.child('posts').child(post.key).remove();

      // Update the UI by removing the deleted post from the _posts list
      setState(() {
        _posts.remove(post);
      });

      // Show a success message or perform any other necessary actions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post deleted successfully'),
        ),
      );
    } catch (e) {
      print('Error deleting post: $e');
      // Handle any errors that occur during the deletion process
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while deleting the post'),
        ),
      );
    }
  }

  void _updateLikesDislikes(Post post, bool isLike) {
    String userId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID

    // Check if the user has already performed the opposite action
    if (isLike && post.userDislikes[userId] == true) {
      post.dislikes -= 1; // Decrease dislike if they are changing their mind
      post.userDislikes[userId] = false; // Mark as not disliked anymore
    } else if (!isLike && post.userLikes[userId] == true) {
      post.likes -= 1; // Decrease like if they are changing their mind
      post.userLikes[userId] = false; // Mark as not liked anymore
    }
    if ((isLike && post.userLikes[userId] != true) || (!isLike && post.userDislikes[userId] != true)) {
      if (isLike) {
        post.likes += 1;
        post.userLikes[userId] = true;
      } else {
        post.dislikes += 1;
        post.userDislikes[userId] = true;
      }
      _database.child('posts').child(post.key).update({
        'likes': post.likes,
        'dislikes': post.dislikes,
        'userLikes': post.userLikes,
        'userDislikes': post.userDislikes,
      });
    }

    // Reset the opacity back to full after a delay
    Future.delayed(Duration(milliseconds: 200), () {
      setState(() {
        _likeOpacities[post.key] = 1.0;
        _dislikeOpacities[post.key] = 1.0;
      });
    });

    _database.child('posts').child(post.key).update({
      'likes': post.likes,
      'dislikes': post.dislikes,
    });
  }

  Widget _buildPostCard(Post post, int index) {
    String timeAgo = formatTimeAgo(post.timestamp);

    bool isDeleting = false;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => PostDetailPage(post: post),
        ));
      },
      child: Card(
        elevation: 10.0,
        margin: EdgeInsets.all(10.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        color: Color(0xFF1A1A1A),
        child: Row( // Wrap the Card with a Row
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Posted $timeAgo',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.white),
                          onPressed: () {
                            // Handle delete post here
                            _deletePost(post);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (post.title.isNotEmpty) ...[
                      Text(
                        post.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                    if (post.body.isNotEmpty) ...[
                      Text(
                        post.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                    if (post.images.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          post.images.first,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Text('Image not available'),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          SizedBox(width: 8),
                          Icon(Icons.thumb_up, color: Colors.white),
                          SizedBox(width: 8),
                          Text('${post.likes} Likes',
                              style: TextStyle(color: Colors.white)),
                          SizedBox(width: 14), // Spacing between likes and dislikes

                          // Dislikes
                          Icon(Icons.thumb_down, color: Colors.red),
                          SizedBox(width: 8),
                          Text('${post.dislikes} Dislikes',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatTimeAgo(int timestamp) {
    DateTime postDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    Duration difference = DateTime.now().difference(postDate);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return DateFormat('yMd').format(postDate);
    }
  }


}
class Post {
  String key;
  String title;
  String body;
  List<String> images;
  List<String?> urls;
  List<String> videos;
  String? audioPath;
  int timestamp;
  int likes;
  int dislikes;
  List<Comment> comments;
  Map<String, bool> userLikes; // Tracks if a user has liked this post
  Map<String, bool> userDislikes; // Tracks if a user has disliked this post=

  Post({
    required this.key,
    required this.title,
    required this.body,
    required this.images,
    required this.urls,
    required this.videos,
    required this.timestamp,
    this.audioPath,
    this.likes = 0,
    this.dislikes = 0,
    required this.comments,
    Map<String, bool>? userLikes, // Optional parameter with default value
    Map<String, bool>? userDislikes, // Optional parameter with default value
  }) : this.userLikes = userLikes ?? {}, // Initialize with empty or provided map
        this.userDislikes = userDislikes ?? {}; // Initialize with empty or provided map


  factory Post.fromMap(String key, Map<dynamic, dynamic> map, String userEmail) {
    int timestamp = map['timestamp'] is int ? map['timestamp'] : 0;

    List<String> images = List<String>.from(map['images'] ?? []);
    List<String> videos = List<String>.from(map['videos'] ?? []);
    List<String?> urls = (map['urls'] as List?)
        ?.map((url) => url as String?)
        .toList() ?? [];

    String? audioPath = map['audioPath'];
    Map<String, bool> userLikes = Map<String, bool>.from(map['userLikes'] ?? {});
    Map<String, bool> userDislikes = Map<String, bool>.from(map['userDislikes'] ?? {});

    List<Comment> comments = [];
    var commentsData = map['comments'];
    if (commentsData != null) {
      if (commentsData is String) {
        // Parse the JSON string into a List
        List<dynamic> commentsList = json.decode(commentsData);
        comments = commentsList.map((commentMap) {
          return Comment.fromMap(commentMap, userEmail);
        }).toList();
      } else if (commentsData is Map) {
        comments = commentsData.values.map((commentMap) {
          return Comment.fromMap(commentMap, userEmail);
        }).toList();
      } else if (commentsData is List) {
        comments = commentsData.map((commentItem) {
          if (commentItem is String) {
            // Handle non-JSON strings as plain text comments
            return Comment(userId: userEmail, text: commentItem, timestamp: 0);
          } else {
            // If the item is already a Map, use it directly
            return Comment.fromMap(commentItem, userEmail);
          }
        }).toList();
      }
    }

    return Post(
      key: key,
      title: map['title'] as String,
      body: map['body'] as String,
      images: images,
      urls: urls,
      videos: videos,
      timestamp: timestamp,
      audioPath: audioPath,
      likes: map['likes'] ?? 0,
      dislikes: map['dislikes'] ?? 0,
      comments: comments,
      userLikes: userLikes,
      userDislikes: userDislikes,
    );
  }
}

