import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'firebase_auth_services.dart';

class SignUpScreen extends StatefulWidget {
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuthservice _auth = FirebaseAuthservice();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorText = '';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signUp() async {
    setState(() {
      _isLoading = true;
    });

    String email = _emailController.text;
    String password = _passwordController.text;

    // Check if the password length is less than 6
    if (password.length < 6) {
      setState(() {
        _errorText = 'Password should be greater than 6 characters.';
        _isLoading = false;
      });
      return; // Stop the function execution if the condition is met
    }

    try {
      User? user = await _auth.signUpWithEmailAndPassword(email, password);

      if (user != null) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        setState(() {
          _errorText = 'Sign-up failed. Please check your information.';
          _isLoading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'weak-password') {
          _errorText = 'The password provided is too weak. Please use a stronger password.';
        } else if (e.code == 'email-already-in-use') {
          _errorText = 'An account with this email address already exists. Please use a different email.';
        } else {
          _errorText = 'Sign-up failed. Please check your information.';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorText = 'An error occurred during sign-up.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Use theme data
      appBar: AppBar(
        title: Text(
          'Sign Up',
          style: TextStyle(color: Theme.of(context).appBarTheme.titleTextStyle?.color), // Use theme data
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, // Use theme data
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).iconTheme.color, // Use theme data
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Set text color to white
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  prefixIcon: Icon(Icons.email, color: Colors.white), // Set icon color to white
                  labelStyle: TextStyle(color: Colors.white), // Set label color to white
                ),
                keyboardType: TextInputType.emailAddress,
                cursorColor: Colors.white, // Set cursor color to white
              ),

              SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
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
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  labelStyle: TextStyle(color: Colors.white), // Set label color to white
                ),
                obscureText: _obscurePassword,
                cursorColor: Colors.white, // Set cursor color to white
              ),


              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _signUp(),
                style: ElevatedButton.styleFrom(
                  primary: Colors.white, // Set button color to white
                  padding: EdgeInsets.all(16.0),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                )
                    : Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 20),
              if (_errorText.isNotEmpty)
                Center(
                  child: Text(
                    _errorText,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
