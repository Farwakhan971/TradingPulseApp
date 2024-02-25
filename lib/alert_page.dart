import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
class AlertSettingsPage extends StatefulWidget {
  @override
  _AlertSettingsPageState createState() => _AlertSettingsPageState();
}

class _AlertSettingsPageState extends State<AlertSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  double _targetPrice = 0.0;
  String _coinName = '';
  String _selectedSound = 'success'; // Default sound
  final List<String> _sounds = ['success', 'chime 2', 'chime 3']; // List of available sounds
  final databaseReference = FirebaseDatabase.instance.ref();
  Timer? _priceCheckTimer;


  @override
  void initState() {
    super.initState();
    setupFirebaseMessagingListeners();
    const Duration checkInterval = Duration(minutes: 3);
    _priceCheckTimer = Timer.periodic(checkInterval, (Timer timer) {
      checkPriceAndTriggerAlert();
    });
  }
  @override
  void dispose() {
    _priceCheckTimer?.cancel();
    super.dispose();
  }

  void setupFirebaseMessagingListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received message in onMessage: ${message.messageId}');
      showNotificationDialog(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Received message in onMessageOpenedApp: ${message.messageId}');
      showNotificationDialog(message);
    });
  }

  void showNotificationDialog(RemoteMessage message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Notification"),
          content: Text(message.notification?.body ?? "No message body"),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  void playSound(String soundFileName) {
    final player = AudioPlayer();
    player.play(AssetSource('$soundFileName.mp3'));
  }
  void checkPriceAndTriggerAlert() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User is not signed in.');
      return;
    }
    final uid = user.uid;

    try {
      final alertsSnapshot = await databaseReference.child('alerts/$uid').get();
      if (alertsSnapshot.exists && alertsSnapshot.value != null) {
        var alert = Map<String, dynamic>.from(alertsSnapshot.value as Map);
        double currentPrice = await fetchCurrentPriceFor(alert['coinName']);

        if (currentPrice >= alert['targetPrice']) {
          playSound(alert['selectedSound']);
        }
      }
    } catch (error) {
      print('Error checking price: $error');
      // Handle any other errors
    }
  }




  Future<double> fetchCurrentPriceFor(String coinName) async {
    final apiKey = '5f3735c7-55f4-493e-9ff0-de9391c26c0a';
    final url = 'https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'X-CMC_PRO_API_KEY': apiKey,
      });

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        var cryptocurrencyData = data['data'].firstWhere(
              (crypto) => crypto['name'].toString().toLowerCase() == coinName.toLowerCase(),
          orElse: () => null,
        );

        if (cryptocurrencyData != null) {
          return cryptocurrencyData['quote']['USD']['price'];
        } else {
          print('Cryptocurrency not found');
          return 0.0;
        }
      } else {
        print('Failed to load crypto data. Status code: ${response.statusCode}');
        return 0.0;
      }
    } catch (e) {
      print('Error during API request: $e');
      return 0.0;
    }
  }

  Future<void> saveAlertSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User is not signed in.');
      return;
    }
    final uid = user.uid; // Get the current user's UID
    final userEmail = user.email ?? ''; // Get the user's email
    final fCMToken = await FirebaseMessaging.instance.getToken();

    try {
      await databaseReference.child('alerts/$uid').set({
        'coinName': _coinName,
        'targetPrice': _targetPrice,
        'userFcmToken': fCMToken,
        'selectedSound': _selectedSound,
        'userEmail': userEmail, // Save user email
      });
      print('Alert settings saved successfully for $_coinName at $_targetPrice');
    } catch (error) {
      print('Failed to save alert settings: $error');
      // Handle any other errors
    }
  }




  void fetchUserAlerts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User is not signed in.');
      return;
    }
    final uid = user.uid;

    try {
      final snapshot = await databaseReference.child('alerts/$uid').get();
      if (snapshot.exists) {
        // Process the alert data
        var alerts = Map<String, dynamic>.from(snapshot.value as Map);
        print('User alerts: $alerts');
      } else {
        print('No alerts found for user $uid');
      }
    } catch (error) {
      print('Error fetching alerts: $error');
      // Handle any other errors
    }
  }


  Future<bool> _showOverwriteAlertConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Alert Already Set"),
          content: Text("An alert is already set. Do you want to overwrite it?"),
          actions: <Widget>[
            TextButton(
              child: Text("No", style: TextStyle(color: Colors.black),),
              onPressed: () => Navigator.of(context).pop(false), // Returns false
            ),
            TextButton(
              child: Text("Yes", style: TextStyle(color: Colors.black),),
              onPressed: () => Navigator.of(context).pop(true), // Returns true
            ),
          ],
        );
      },
    ) ?? false; // Assumes 'No' as default action if dialog is dismissed.
  }
  void _removeAllAlerts() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No user signed in."),
        ),
      );
      return;
    }
    final uid = user.uid; // Get the current user's UID

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Remove Alert"),
          content: Text("Are you sure you want to remove alert?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel", style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Remove", style: TextStyle(color: Colors.black)),
              onPressed: () async {
                _priceCheckTimer?.cancel(); // Stop checking prices
                await databaseReference.child('alerts/$uid').remove(); // Remove alerts for the current user
                Navigator.of(context).pop(); // Close the dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Alert has been removed."),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
  Future<bool> _showInitialAlertConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Confirm Alert"),
          content: Text("Are you sure you want to set this alert? It will be checked every 3 minutes when the app is running, and the sound will be played if the price of the coin is equal to or greater than the target price."),
          actions: <Widget>[
            TextButton(
              child: Text("No", style: TextStyle(color: Colors.black),),
              onPressed: () => Navigator.of(context).pop(false), // Returns false
            ),
            TextButton(
              child: Text("Yes", style: TextStyle(color: Colors.black),),
              onPressed: () => Navigator.of(context).pop(true), // Returns true
            ),
          ],
        );
      },
    ) ?? false; // Assumes 'No' as default action if dialog is dismissed.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => _removeAllAlerts(),
          ),
        ],
        backgroundColor: Colors.black,
        title: Text('Alert Settings', style: TextStyle(color: Colors.white)),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 70),
                Icon(Icons.notifications, size: 50.0, color: Colors.black),
                SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Enter the name of the coin',
                    labelStyle: TextStyle(color: Colors.black), // Label text style in black
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    // Add cursor color
                  ),
                  cursorColor: Colors.black,
                  style: TextStyle(color: Colors.black), // Text style in black
                  onSaved: (value) {
                    _coinName = value ?? '';
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the name of the coin';
                    }
                    return null;
                  },
                ),


                SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Enter target price for the alert',
                    labelStyle: TextStyle(color: Colors.black), // Label text style in black
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                  ),
                  cursorColor: Colors.black,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Colors.black), // Text style in black
                  onSaved: (value) {
                    _targetPrice = double.tryParse(value ?? '0') ?? 0.0;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a target price';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                DropdownButtonFormField(
                  decoration: InputDecoration(
                    labelText: 'Select Alert Sound',
                    labelStyle: TextStyle(
                      color: Colors.black, // Default label color
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    // Add this to change label text color when focused
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  value: _selectedSound,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedSound = newValue;
                      });
                      playSound(newValue);
                    }
                  },
                  items: _sounds.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  child: Text('Set Alert', style: TextStyle(color: Colors.white)),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        final uid = user.uid;
                        final snapshot = await databaseReference.child('alerts/$uid').get();
                        bool shouldProceed = true;

                        // Check if an alert already exists
                        if (snapshot.exists && snapshot.value != null) {
                          // Show overwrite confirmation if an alert already exists
                          bool overwriteConfirmed = await _showOverwriteAlertConfirmation();
                          if (!overwriteConfirmed) {
                            shouldProceed = false; // Do not proceed if user chose not to overwrite
                          }
                        } else {
                          // Show initial alert confirmation only if no alert exists
                          bool initialConfirmation = await _showInitialAlertConfirmation();
                          if (!initialConfirmation) {
                            shouldProceed = false; // Do not proceed if user cancels initial confirmation
                          }
                        }

                        if (shouldProceed) {
                          // If confirmed, save the alert settings
                          await saveAlertSettings();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Alert has been successfully set.")),
                          );
                        }
                      } else {
                        print('User is not signed in.');
                      }
                    }
                  },




                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}