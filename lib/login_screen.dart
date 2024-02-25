import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trading_admin/viewpost.dart';
import 'Sign_up.dart';
import 'firebase_auth_services.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuthservice _auth = FirebaseAuthservice();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorText = '';
  bool _obscurePassword = true;

  void _clearFields() {
    _emailController.clear();
    _passwordController.clear();
  }

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    String email = _emailController.text;
    String password = _passwordController.text;

    User? user = await _auth.signInWithEmailAndPassword(email, password);

    if (user != null) {
      _clearFields();
      // Navigate to the AllPostsPage after successful login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => AllPostsPage()),
      );
    } else {
      setState(() {
        _errorText = 'Login failed. Please check your information.';
        _isLoading = false;
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Theme(
        data: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black, // Set the screen's background color to black
          textTheme: TextTheme(
            bodyText1: TextStyle(color: Colors.white), // Set text color to white for the dark theme
          ),
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 140),
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Set text color to white for the dark theme
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white), // Set border color to white for the dark theme
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    prefixIcon: Icon(Icons.email, color: Colors.white), // Set icon color to white
                  ),
                  keyboardType: TextInputType.emailAddress,
                  cursorColor: Colors.white, // Set cursor color to white
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    prefixIcon: Icon(Icons.lock, color: Colors.white), // Set icon color to white
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  cursorColor: Colors.white, // Set cursor color to white
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    primary: Colors.white, // Set button color to white
                    padding: EdgeInsets.all(20.0),
                    minimumSize: Size(double.infinity, 0),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  )
                      : Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  _errorText,
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => SignUpScreen()),
                    );
                  },
                  child: Text(
                    'Don\'t have an account? Sign up',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


}
