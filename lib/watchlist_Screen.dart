import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WatchListScreen extends StatefulWidget {
  @override
  _WatchListScreenState createState() => _WatchListScreenState();
}

class _WatchListScreenState extends State<WatchListScreen> {

  final databaseReference = FirebaseDatabase.instance.reference();
  List<Map<String, dynamic>> watchList = [];

  @override
  void initState() {
    super.initState();
    _loadWatchList();
  }
  Future<void> _onRefresh() async {
    // You can call _loadWatchList here to refresh the data
    setState(() {
      _loadWatchList();
    });
  }
  void _loadWatchList() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;
      databaseReference.child('watchlist').child(uid).onValue.listen((event) {
        var snapshots = event.snapshot.value as Map<dynamic, dynamic>?;
        if (snapshots != null) {
          List<Map<String, dynamic>> tempList = [];
          snapshots.forEach((key, value) {
            Map<String, dynamic> item = Map<String, dynamic>.from(value);
            item['firebaseKey'] = key;
            tempList.add(item);
          });
          setState(() {
            watchList = tempList.reversed.toList();
          });
        } else {
          setState(() {
            watchList = []; // Explicitly setting to empty list
          });
        }
      });
    }
  }

  Widget _buildLinksSection(Map<String, dynamic> item) {
    List<Widget> linkWidgets = [];

    void addLinks(String title, dynamic links, {int? maxLinks}) {
      if (links != null && links is List) {
        int count = 0;
        for (var link in links) {
          if (link is String && link.isNotEmpty) {
            linkWidgets.add(_buildLinkText(title, link));
            if (maxLinks != null) {
              count++;
              if (count >= maxLinks) break; // Stop adding links after reaching the limit
            }
          }
        }
      }
    }

    addLinks('Website', item['website']);
    addLinks('Explorers', item['explorers'], maxLinks: 2); // Limiting to 2 links
    addLinks('Message Boards', item['messageboards']);
    addLinks('Social Media', item['social media']);
    addLinks('Technical Documents', item['technical documents']);

    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: linkWidgets,
      ),
    );
  }

  Widget _buildLinkText(String title, String? url) {
    if (url != null && url.isNotEmpty) {
      return InkWell(
        onTap: () => _launchURL(url),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Text(
                '$title: ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Flexible( // Using Flexible to handle long URLs
                child: Text(
                  url,
                  style: TextStyle(
                    color: Colors.cyan,
                  ),
                  overflow: TextOverflow.ellipsis, // Add an ellipsis for long URLs
                ),
              ),
              SizedBox(width: 5),
              Icon(Icons.touch_app, size: 16, color: Colors.white) // Icon indicating it's touchable
            ],
          ),
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          '$title: Not available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
  }



  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      // Show error or handle it
      print('Could not launch $url');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text('Watch List', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView.builder(
          itemCount: watchList.length,
          itemBuilder: (context, index) {
            final item = watchList[index];
            final firebaseKey = item['firebaseKey'];  // Make sure 'key' is a field in your item map
            if (item.isNotEmpty) {
              return Card(
                color: Colors.blueGrey,
                elevation: 4,
                margin: EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Align(
                        alignment: Alignment.centerLeft, // Aligns the CircleAvatar to the left
                        child: CircleAvatar(
                          radius: 25, // Adjust the size
                          backgroundImage: NetworkImage(item['logoUrl'] ?? ''),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ),

                    ListTile(
                        title: Text(
                          item['coinName'] ?? '',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          item['coinPrice'] != null
                              ? '\$${item['coinPrice'].toStringAsFixed(8)}'
                              : '',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      trailing: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white10, Colors.white24],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.white),
                          onPressed: () {
                            _deleteItem(firebaseKey);
                          },
                        ),
                      ),
                    ),
                    ExpansionTile(
                      title: Text(
                        'View Links',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      collapsedIconColor: Colors.white,
                      iconColor: Colors.white, // Color for the arrow icon when the tile is not expanded
                      children: <Widget>[
                        _buildLinksSection(item),
                      ],
                    )


                  ],
                ),
              );
            } else {
              return SizedBox.shrink();
            }
          },
        ),

      ),
    );
  }
  void _deleteItem(String key) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;
      databaseReference.child('watchlist').child(uid).child(key).remove().then((_) {
        // Refresh the watchlist after deletion
        _loadWatchList();
      }).catchError((error) {
        // Handle any errors here
        print('Error deleting item: $error');
      });
    }
  }

}
