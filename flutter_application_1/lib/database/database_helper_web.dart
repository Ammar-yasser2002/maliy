import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/client.dart';

/// Database Helper for Web using SharedPreferences
class DatabaseHelperWeb {
  static const String _clientsKey = 'clients_data';

  // Get all clients
  static Future<List<Client>> getAllClients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clientsJson = prefs.getStringList(_clientsKey) ?? [];

      return clientsJson
          .map((json) => Client.fromMap(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('❌ Error getting clients from web storage: $e');
      return [];
    }
  }

  // Save all clients
  static Future<void> saveAllClients(List<Client> clients) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clientsJson = clients
          .map((client) => jsonEncode(client.toMap()))
          .toList();

      await prefs.setStringList(_clientsKey, clientsJson);
    } catch (e) {
      print('❌ Error saving clients to web storage: $e');
      rethrow;
    }
  }

  // Add client
  static Future<int> addClient(Client client) async {
    try {
      final clients = await getAllClients();
      final newId = clients.isEmpty
          ? 1
          : clients.map((c) => c.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;

      final newClient = client.copyWith(id: newId);
      clients.insert(0, newClient);

      await saveAllClients(clients);
      return newId;
    } catch (e) {
      print('❌ Error adding client: $e');
      rethrow;
    }
  }

  // Update client
  static Future<void> updateClient(Client client) async {
    try {
      final clients = await getAllClients();
      final index = clients.indexWhere((c) => c.id == client.id);

      if (index != -1) {
        clients[index] = client;
        await saveAllClients(clients);
      }
    } catch (e) {
      print('❌ Error updating client: $e');
      rethrow;
    }
  }

  // Delete client
  static Future<void> deleteClient(int id) async {
    try {
      final clients = await getAllClients();
      clients.removeWhere((c) => c.id == id);
      await saveAllClients(clients);
    } catch (e) {
      print('❌ Error deleting client: $e');
      rethrow;
    }
  }

  // Check if client exists
  static Future<bool> clientExists(String phone, String name) async {
    try {
      final clients = await getAllClients();

      if (phone.isEmpty) {
        return clients.any((c) => c.name == name);
      }

      return clients.any((c) => c.phone == phone || c.name == name);
    } catch (e) {
      print('❌ Error checking client existence: $e');
      return false;
    }
  }

  // Search clients
  static Future<List<Client>> searchClients(String query) async {
    try {
      final clients = await getAllClients();

      return clients
          .where(
            (c) =>
                c.name.toLowerCase().contains(query.toLowerCase()) ||
                c.phone.toLowerCase().contains(query.toLowerCase()) ||
                c.email.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    } catch (e) {
      print('❌ Error searching clients: $e');
      return [];
    }
  }

  // Get client count
  static Future<int> getClientCount() async {
    try {
      final clients = await getAllClients();
      return clients.length;
    } catch (e) {
      print('❌ Error getting client count: $e');
      return 0;
    }
  }
}
