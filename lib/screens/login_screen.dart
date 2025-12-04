import 'package:flutter/material.dart';
import '../services/auth_service.dart';
// import your actual patient dashboard screen here
import '../screens/dashboard/patient_dashboard.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  String email = '';
  String password = '';

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff2f2f2), // soft gray bg

      appBar: AppBar(
        backgroundColor: Color(0xFF8c6239),
        title: Text("Login", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),

      body: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),

          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8c6239),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 25),

                // Email Input
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: Color(0xFF8c6239)),
                    filled: true,
                    fillColor: Color(0xfff7f7f7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? 'Enter email' : null,
                  onSaved: (value) => email = value ?? '',
                ),

                SizedBox(height: 15),

                // Password Input
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock, color: Color(0xFF8c6239)),
                    filled: true,
                    fillColor: Color(0xfff7f7f7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? 'Enter password' : null,
                  onSaved: (value) => password = value ?? '',
                ),

                SizedBox(height: 20),

                // Login Button
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8c6239),
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),

                SizedBox(height: 10),

                // Register Redirect
                TextButton(
                  child: Text(
                    "Don't have an account? Register",
                    style: TextStyle(color: Color(0xFF8c6239)),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() => _isLoading = true);

      final result = await _authService.login(email, password);

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        // Temporary success screen - replace later with real dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Scaffold(
            appBar: AppBar(title: Text('Dashboard')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Login Successful!', style: TextStyle(fontSize: 24)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Back to Login'),
                  ),
                ],
              ),
            ),
          )),
        );
      } else {
        final errorMessage = result['error'] ?? 'Login failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

}
