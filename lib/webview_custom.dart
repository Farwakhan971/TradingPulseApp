import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewLoader extends StatefulWidget {
  final String url;

  WebViewLoader({required this.url});

  @override
  _WebViewLoaderState createState() => _WebViewLoaderState();
}

class _WebViewLoaderState extends State<WebViewLoader> {
  bool _loadWebView = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _loadWebView = true;
        });
      },
      child: Container(
        height: 200, // Placeholder height
        decoration: BoxDecoration(
          color: Colors.grey[200], // Light grey background
          borderRadius: BorderRadius.circular(10), // Rounded corners
          border: Border.all(
            color: Colors.grey[400]!, // Grey border
            width: 1,
          ),
        ),
        child: _loadWebView
            ? WebView(
          initialUrl: widget.url,
          javascriptMode: JavascriptMode.unrestricted,
        )
            : Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app, // Touch icon
                color: Colors.black,
                size: 40,
              ),
              SizedBox(height: 8), // Spacing
              Text(
                'Tap to load',
                style: TextStyle(
                  color: Colors.black,
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
