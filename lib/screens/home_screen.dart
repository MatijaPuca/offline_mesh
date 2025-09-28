import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connection_service.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final connection = Provider.of<ConnectionService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('OfflineMesh')),
      body: Column(
        children: [
          const SizedBox(height: 12),
          const Text('Nearby Connections', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: connection.connectedPeers.length,
              itemBuilder: (context, i) {
                final peer = connection.connectedPeers[i];
                return ListTile(
                  leading: const Icon(Icons.device_hub),
                  title: Text(peer),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatScreen()),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => connection.start(),
            child: const Text('Start Mesh'),
          ),
        ],
      ),
    );
  }
}
