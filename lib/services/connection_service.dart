import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';

class ConnectionService extends ChangeNotifier {
  final Strategy strategy = Strategy.P2P_CLUSTER;
  final String userId = const Uuid().v4();
  final List<String> connectedPeers = [];
  final List<Message> messages = [];

  void start() async {
    await Nearby().stopAllEndpoints();
    _startAdvertising();
    _startDiscovery();
  }

  void _startAdvertising() async {
    await Nearby().startAdvertising(
      userId,
      strategy,
      onConnectionInitiated: (id, info) {
        Nearby().acceptConnection(
          id,
          onPayLoadRecieved: (endpointId, payload) {
            _onReceiveMessage(endpointId, payload);
          },
        );
      },
      onConnectionResult: (id, status) {
        if (status == Status.CONNECTED && !connectedPeers.contains(id)) {
          connectedPeers.add(id);
          notifyListeners();
        }
      },
      onDisconnected: (id) {
        connectedPeers.remove(id);
        notifyListeners();
      },
    );
  }

  void _startDiscovery() async {
    await Nearby().startDiscovery(
      userId,
      strategy,
      onEndpointFound: (id, name, serviceId) async {
        await Nearby().requestConnection(
          userId,
          id,
          onConnectionInitiated: (id, info) {
            Nearby().acceptConnection(
              id,
              onPayLoadRecieved: (endpointId, payload) {
                _onReceiveMessage(endpointId, payload);
              },
            );
          },
          onConnectionResult: (id, status) {
            if (status == Status.CONNECTED && !connectedPeers.contains(id)) {
              connectedPeers.add(id);
              notifyListeners();
            }
          },
          onDisconnected: (id) {
            connectedPeers.remove(id);
            notifyListeners();
          },
        );
      },
      onEndpointLost: (id) {
        connectedPeers.remove(id);
        notifyListeners();
      },
    );
  }

  void sendMessage(String text) {
    final msg = Message(
      id: const Uuid().v4(),
      senderId: userId,
      text: text,
      timestamp: DateTime.now(),
      isMe: true,
    );

    messages.add(msg);
    notifyListeners();

    final bytes = Uint8List.fromList(text.codeUnits);

    for (final peer in connectedPeers) {
      Nearby().sendBytesPayload(peer, bytes);
    }
  }

  void _onReceiveMessage(String endpointId, Payload payload) {
    if (payload.bytes != null) {
      final text = String.fromCharCodes(payload.bytes!);
      final msg = Message(
        id: const Uuid().v4(),
        senderId: endpointId,
        text: text,
        timestamp: DateTime.now(),
        isMe: false,
      );

      messages.add(msg);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    Nearby().stopAllEndpoints();
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    super.dispose();
  }
}
