import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/contact_service.dart';

class ContactListScreen extends StatefulWidget {
  @override
  _ContactListScreenState createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  late Future<List<Contact>> futureContacts;
  final ContactService contactService = ContactService();

  @override
  void initState() {
    super.initState();
    futureContacts = contactService.getContacts();  // Fetch contacts when screen loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contacts'),
      ),
      body: FutureBuilder<List<Contact>>(
        future: futureContacts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show loading spinner while waiting for data
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Show error message in case of error
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Show message if no contacts found
            return Center(child: Text('No contacts found.'));
          } else {
            // On successful data fetch, build ListView
            List<Contact> contacts = snapshot.data!;
            return ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                Contact contact = contacts[index];
                return ListTile(
                  title: Text(contact.name),
                  subtitle: Text(contact.email),
                  trailing: Text(contact.phone),
                  onTap: () {
                    // Handle tapping contact for edit or detail screen
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          // Navigate to AddContactScreen (to implement next)
        },
      ),
    );
  }
}
