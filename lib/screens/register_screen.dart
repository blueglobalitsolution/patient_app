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
  String? gender;
  String password = '';

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Color get primaryColor => const Color(0xFF8c6239);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: primaryColor,
        title: const Text("Register", style: TextStyle(color: Colors.white , )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "Create an Account",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    buildInput("Full Name", Icons.person_outline, (v) => fullName = v!, "Enter your full name"),
                    const SizedBox(height: 12),
                    TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      decoration: buildInputDecoration("Email", Icons.email_outlined),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                      onSaved: (value) => email = value ?? '',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      keyboardType: TextInputType.phone,
                      decoration: buildInputDecoration("Phone Number", Icons.phone_outlined),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.length != 10 || int.tryParse(value) == null) {
                          return 'Phone number must be 10 digits';
                        }
                        return null;
                      },
                      onSaved: (value) => phoneNumber = value ?? '',
                    ),
                    const SizedBox(height: 12),
                    buildInput("Address", Icons.location_on_outlined, (v) => address = v!, "Enter your address"),
                    const SizedBox(height: 12),
                    buildInput("Age", Icons.cake_outlined, (v) => age = v!, "Enter your age"),
                    const SizedBox(height: 12),
                    buildGenderDropdown(),
                    const SizedBox(height: 12),
                    buildPasswordInput(),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Register',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                            onPressed: _handleRegister,
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? ", style: TextStyle(color: Colors.grey)),
                  TextButton(
                    child: Text(
                      "Login",
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration buildInputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: primaryColor, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor),
      ),
    );
  }

  Widget buildInput(String hintText, IconData icon, Function(String?) onSaved, String validationMsg) {
    return TextFormField(
      decoration: buildInputDecoration(hintText, icon),
      validator: (value) => value == null || value.isEmpty ? validationMsg : null,
      onSaved: onSaved,
    );
  }
  
  Widget buildGenderDropdown(){
    return DropdownButtonFormField<String>(
      value: gender,
      hint: const Text('Select Gender'),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.people_alt_outlined, color: primaryColor, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
         enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor),
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
      validator: (value) => (value == null || value.isEmpty) ? 'Please select your gender' : null,
    );
  }

  Widget buildPasswordInput() {
    return TextFormField(
      obscureText: true,
      decoration: buildInputDecoration("Password", Icons.lock_outline),
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
        gender!,
        password,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please login.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Registration failed')),
        );
      }
    }
  }
}
