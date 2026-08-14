import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & settings')),
      body: ListView(
        children: const [
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('VectorFlow User'),
            subtitle: Text('demo@vectorflow.dev'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.security),
            title: Text('Secure authentication'),
            subtitle: Text('JWT tokens stored using secure storage'),
          ),
          ListTile(
            leading: Icon(Icons.sync),
            title: Text('Offline-first synchronization'),
            subtitle: Text('Queued operations retry when connectivity returns'),
          ),
          ListTile(
            leading: Icon(Icons.notifications_active_outlined),
            title: Text('Realtime status'),
            subtitle: Text('Socket.IO package processing updates'),
          ),
        ],
      ),
    );
  }
}
