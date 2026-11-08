import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/client.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('clients.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';

    await db.execute('''
    CREATE TABLE clients (
      id $idType,
      name $textType,
      phone $textTypeNullable,
      email $textTypeNullable,
      address $textTypeNullable,
      company $textTypeNullable,
      notes $textTypeNullable,
      createdAt $textType
    )
    ''');
  }

  // Create a new client
  Future<int> createClient(Client client) async {
    final db = await instance.database;
    return await db.insert('clients', client.toMap());
  }

  // Read all clients
  Future<List<Client>> readAllClients() async {
    final db = await instance.database;
    const orderBy = 'createdAt DESC';
    final result = await db.query('clients', orderBy: orderBy);
    return result.map((json) => Client.fromMap(json)).toList();
  }

  // Read a single client by id
  Future<Client?> readClient(int id) async {
    final db = await instance.database;
    final maps = await db.query('clients', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Client.fromMap(maps.first);
    }
    return null;
  }

  // Update a client
  Future<int> updateClient(Client client) async {
    final db = await instance.database;
    return db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  // Delete a client
  Future<int> deleteClient(int id) async {
    final db = await instance.database;
    return await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  // Check if client exists by phone or name
  Future<bool> clientExists(String phone, String name) async {
    final db = await instance.database;

    // إذا كان الهاتف فارغاً، ابحث بالاسم فقط
    if (phone.isEmpty) {
      final result = await db.query(
        'clients',
        where: 'name = ?',
        whereArgs: [name],
      );
      return result.isNotEmpty;
    }

    // إذا كان الهاتف موجوداً، ابحث بالاسم أو الهاتف
    final result = await db.query(
      'clients',
      where: 'phone = ? OR name = ?',
      whereArgs: [phone, name],
    );
    return result.isNotEmpty;
  }

  // Search clients
  Future<List<Client>> searchClients(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'clients',
      where: 'name LIKE ? OR phone LIKE ? OR email LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => Client.fromMap(json)).toList();
  }

  // Get client count
  Future<int> getClientCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM clients');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Close the database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
