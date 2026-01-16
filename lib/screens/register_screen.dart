import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  String fullName = '';
  String email = '';
  String phoneNumber = '';
  String address = '';
  String age = '';
  String gender = 'Male';  // Default gender
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

                buildInput("Full Name", Icons.person, (v) => fullName = v!, "Enter your full name"),
                SizedBox(height: 12),

                buildInput("Email", Icons.email, (v) => email = v!, "Enter your email"),
                SizedBox(height: 12),

                buildInput("Phone Number", Icons.phone, (v) => phoneNumber = v!, "Enter 10-digit phone number"),
                SizedBox(height: 12),

                buildInput("Address", Icons.location_city, (v) => address = v!, "Enter your address"),
                SizedBox(height: 12),

                buildInput("Age", Icons.cake, (v) => age = v!, "Enter your age"),
                SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: gender,
                  decoration: InputDecoration(
                    labelText: "Gender",
                    prefixIcon: Icon(Icons.person, color: Color(0xFF8c6239)),
                    filled: true,
                    fillColor: Color(0xfff7f7f7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: ['Male', 'Female', 'Other']
                      .map((g) => DropdownMenuItem(
                    value: g,
                    child: Text(g),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => gender = value);
                    }
                  },
                  validator: (value) => (value == null || value.isEmpty) ? 'Select gender' : null,
                ),
                SizedBox(height: 12),

                buildPasswordInput(),
                SizedBox(height: 20),

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

  Widget buildInput(String label, IconData icon, Function(String?) onSaved, String validationMsg) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF8c6239)),
        filled: true,
        fillColor: Color(0xfff7f7f7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      validator: (value) => value == null || value.isEmpty ? validationMsg : null,
      onSaved: onSaved,
    );
  }

  Widget buildPasswordInput() {
    return TextFormField(
      obscureText: true,
      decoration: InputDecoration(
        labelText: "Password",
        prefixIcon: Icon(Icons.lock, color: Color(0xFF8c6239)),
        filled: true,
        fillColor: Color(0xfff7f7f7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      validator: (value) => (value == null || value.length < 6) ? "Password must be 6+ chars" : null,
      onSaved: (value) => password = value ?? '',
    );
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() => _isLoading = true);

      // Call AuthService with updated parameters
      final result = await _authService.register(
        fullName,
        email,
        phoneNumber,
        address,
        age,
        gender,
        password,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration successful! Please login.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Registration failed')),
        );
      }
    }
  }
}
