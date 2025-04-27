import 'package:flutter/material.dart';
import 'package:nicoya_now/screens/categoria_producto_screen.dart';
import 'package:nicoya_now/services/data/data_manager.dart';
import 'package:nicoya_now/services/repositories/multi_source_repository.dart';

class NicoyaNowApp extends StatelessWidget {
  const NicoyaNowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nicoya Now',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isSyncing = false;
  DataSourcePriority _currentPriority = DataSourcePriority.remote;

  final List<Widget> _pages = [
    const CategoriaProductoScreen(),
    const Placeholder(), // Página para establecimientos (pendiente)
    const Placeholder(), // Página para productos (pendiente)
    const Placeholder(), // Página para pedidos (pendiente)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _changePriority(DataSourcePriority priority) async {
    setState(() {
      _isSyncing = true;
      _currentPriority = priority;
    });

    try {
      await DataManager.instance.setGlobalDataSourcePriority(priority);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cambiar la prioridad: $e')),
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nicoya Now'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isSyncing) 
            const Center(child: Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )),
          PopupMenuButton<DataSourcePriority>(
            onSelected: _changePriority,
            icon: const Icon(Icons.storage),
            itemBuilder: (context) => [
              const PopupMenuItem(
                enabled: false,
                child: Text('Prioridad de datos', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              CheckedPopupMenuItem(
                value: DataSourcePriority.remote,
                checked: _currentPriority == DataSourcePriority.remote,
                child: const Text('Supabase (Remoto)'),
              ),
              CheckedPopupMenuItem(
                value: DataSourcePriority.turso,
                checked: _currentPriority == DataSourcePriority.turso,
                child: const Text('Turso (Remoto)'),
              ),
              CheckedPopupMenuItem(
                value: DataSourcePriority.local,
                checked: _currentPriority == DataSourcePriority.local,
                child: const Text('SQLite (Local)'),
              ),
              CheckedPopupMenuItem(
                value: DataSourcePriority.all,
                checked: _currentPriority == DataSourcePriority.all,
                child: const Text('Todos (Cascada)'),
              ),
            ],
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categorías',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Establecimientos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fastfood),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Pedidos',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}