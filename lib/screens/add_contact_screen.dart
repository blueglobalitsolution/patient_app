import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/contact_service.dart';

class AddContactScreen extends StatefulWidget {
  @override
  _AddContactScreenState createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String email = '';
  String phone = '';
  String user = '';

  final ContactService _contactService = ContactService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Contact")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: "Name"),
                onSaved: (value) => name = value ?? '',
                validator: (value) => value!.isEmpty ? 'Enter name' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Email"),
                onSaved: (value) => email = value ?? '',
                validator: (value) => value!.isEmpty ? 'Enter email' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Phone"),
                onSaved: (value) => phone = value ?? '',
                validator: (value) => value!.isEmpty ? 'Enter phone' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "User"),
                onSaved: (value) => user = value ?? '',
                validator: (value) => value!.isEmpty ? 'Enter user' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text("Save Contact"),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    Contact newContact = Contact(
                      id: 0, // ID will be auto-generated in backend
                      name: name,
                      email: email,
                      phone: phone,
                      user: user,
                    );
                    bool success = await _contactService.addContact(newContact);
                    if (success) {
                      Navigator.pop(context); // Return to list
                    } else {
                      // Handle error scenario
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add contact')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
