import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/db.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TareasPage(),
    ));

class TareasPage extends StatefulWidget {
  const TareasPage({super.key});

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final tituloCtrl = TextEditingController();
  final contenidoCtrl = TextEditingController();
  List<Map<String, dynamic>> tareas = [];
  int? editandoId;
  String nombreUsuario = '';
  bool soloPendientes = false;

  @override
  void initState() {
    super.initState();
    cargarNombre();
    cargarTareas();
  }

  // ========== SHARED PREFERENCES ==========
  Future<void> cargarNombre() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nombreUsuario = prefs.getString('nombre_usuario') ?? '';
      soloPendientes = prefs.getBool('solo_pendientes') ?? false;
    });
    if (nombreUsuario.isEmpty) {
      _mostrarDialogoNombre();
    }
  }

  Future<void> guardarNombre(String nombre) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombre_usuario', nombre);
    setState(() => nombreUsuario = nombre);
  }

  Future<void> guardarFiltro(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('solo_pendientes', valor);
    setState(() => soloPendientes = valor);
  }

  void _mostrarDialogoNombre() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('¡Bienvenido!'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: '¿Cómo te llamas?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                guardarNombre(ctrl.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // ========== SQLITE CRUD ==========
  Future<void> cargarTareas() async {
    final data = await DB.listar();
    setState(() => tareas = data);
  }

  Future<void> guardar() async {
    final titulo = tituloCtrl.text.trim();
    final contenido = contenidoCtrl.text.trim();

    if (titulo.isEmpty || contenido.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Completa todos los campos')),
      );
      return;
    }

    if (editandoId == null) {
      await DB.insertar(titulo, contenido);
    } else {
      await DB.actualizar(editandoId!, titulo, contenido);
      editandoId = null;
    }

    tituloCtrl.clear();
    contenidoCtrl.clear();
    cargarTareas();
  }

  Future<void> eliminar(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: const Text('¿Estás seguro de que deseas eliminar esta tarea?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await DB.eliminar(id);
      cargarTareas();
    }
  }

  Future<void> toggleCompletada(int id, bool completada) async {
    await DB.marcarCompletada(id, completada);
    cargarTareas();
  }

  void editar(Map<String, dynamic> tarea) {
    setState(() {
      tituloCtrl.text = tarea['titulo'];
      contenidoCtrl.text = tarea['contenido'];
      editandoId = tarea['id'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final tareasFiltradas = soloPendientes
        ? tareas.where((t) => t['completada'] == 0).toList()
        : tareas;

    return Scaffold(
      appBar: AppBar(
        title: Text(nombreUsuario.isEmpty
            ? 'Gestor de Tareas'
            : 'Hola, $nombreUsuario'),
        actions: [
          IconButton(
            icon: Icon(soloPendientes
                ? Icons.filter_alt
                : Icons.filter_alt_outlined),
            tooltip: 'Mostrar solo pendientes',
            onPressed: () => guardarFiltro(!soloPendientes),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: tituloCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contenidoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Contenido',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: guardar,
                        icon: Icon(editandoId == null ? Icons.add : Icons.save),
                        label: Text(editandoId == null ? 'Guardar' : 'Actualizar'),
                      ),
                    ),
                    if (editandoId != null) ...[
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            editandoId = null;
                            tituloCtrl.clear();
                            contenidoCtrl.clear();
                          });
                        },
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: tareasFiltradas.isEmpty
                ? const Center(child: Text('No hay tareas registradas'))
                : ListView.builder(
                    itemCount: tareasFiltradas.length,
                    itemBuilder: (_, i) {
                      final t = tareasFiltradas[i];
                      final completada = t['completada'] == 1;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: Checkbox(
                            value: completada,
                            onChanged: (v) =>
                                toggleCompletada(t['id'], v ?? false),
                          ),
                          title: Text(
                            t['titulo'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: completada
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Text(t['contenido']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => editar(t),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => eliminar(t['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}