import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String email = '';
  String phone = '';
  String city = '';
  String password = '';

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff2f2f2), // Soft gray background
      appBar: AppBar(
        backgroundColor: Color(0xFF8c6239), // gold-brown theme
        title: Text("Register", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),

      body: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
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
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  "Create an Account",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8c6239),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 25),

                // Input Fields
                buildInput("Name", Icons.person, (v) => name = v!, "Enter your name"),
                SizedBox(height: 12),

                buildInput("Email", Icons.email, (v) => email = v!, "Enter your email"),
                SizedBox(height: 12),

                buildInput("Phone", Icons.phone, (v) => phone = v!, "Enter phone number"),
                SizedBox(height: 12),

                buildInput("City", Icons.location_city, (v) => city = v!, "Enter city"),
                SizedBox(height: 12),

                buildPasswordInput(),
                SizedBox(height: 20),

                // Register Button
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8c6239),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Register',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  onPressed: _handleRegister,
                ),

                SizedBox(height: 10),

                TextButton(
                  child: Text(
                    "Already have an account? Login",
                    style: TextStyle(color: Color(0xFF8c6239)),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
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

  // Input Field Builder
  Widget buildInput(String label, IconData icon, Function(String?) onSaved, String validationMsg) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF8c6239)),
        filled: true,
        fillColor: Color(0xfff7f7f7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      validator: (value) => value!.isEmpty ? validationMsg : null,
      onSaved: onSaved,
    );
  }

  // Password Field
  Widget buildPasswordInput() {
    return TextFormField(
      obscureText: true,
      decoration: InputDecoration(
        labelText: "Password",
        prefixIcon: Icon(Icons.lock, color: Color(0xFF8c6239)),
        filled: true,
        fillColor: Color(0xfff7f7f7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      validator: (value) => value!.length < 6 ? "Password must be 6+ chars" : null,
      onSaved: (value) => password = value ?? '',
    );
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() => _isLoading = true);

      bool success = await _authService.register(
        name,
        email,
        phone,
        city,
        password,
      );

      setState(() => _isLoading = false);

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration successful! Please login.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed')),
        );
      }
    }
  }
}
