import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    final ruta = join(await getDatabasesPath(), 'notas.db');
    _db = await openDatabase(
      ruta,
      version: 1,
      onCreate: (db, version) => db.execute(
        'CREATE TABLE notas(id INTEGER PRIMARY KEY AUTOINCREMENT, titulo TEXT, contenido TEXT, completada INTEGER DEFAULT 0)',
      ),
    );
    return _db!;
  }

  // INSERTAR
  static Future<int> insertar(String titulo, String contenido) async {
    final db = await database;
    return db.insert('notas', {
      'titulo': titulo,
      'contenido': contenido,
      'completada': 0,
    });
  }

  // LISTAR
  static Future<List<Map<String, dynamic>>> listar() async {
    final db = await database;
    return db.query('notas', orderBy: 'id DESC');
  }

  // ACTUALIZAR
  static Future<int> actualizar(int id, String titulo, String contenido) async {
    final db = await database;
    return db.update(
      'notas',
      {'titulo': titulo, 'contenido': contenido},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ELIMINAR
  static Future<int> eliminar(int id) async {
    final db = await database;
    return db.delete('notas', where: 'id = ?', whereArgs: [id]);
  }

  // MARCAR COMPLETADA
  static Future<int> marcarCompletada(int id, bool completada) async {
    final db = await database;
    return db.update(
      'notas',
      {'completada': completada ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}