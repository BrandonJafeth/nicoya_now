import 'package:flutter/material.dart';
import 'package:nicoya_now/models/categoria_producto.dart';
import 'package:nicoya_now/services/categoria_producto_service.dart';
import 'package:nicoya_now/services/repositories/multi_source_repository.dart';
import 'package:nicoya_now/widgets/categoria_list_item.dart';

class CategoriaProductoScreen extends StatefulWidget {
  const CategoriaProductoScreen({super.key});

  @override
  State<CategoriaProductoScreen> createState() => _CategoriaProductoScreenState();
}

class _CategoriaProductoScreenState extends State<CategoriaProductoScreen> {
  final _categoriaService = CategoriaProductoService();
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  
  bool _isLoading = false;
  DataSourcePriority _currentPriority = DataSourcePriority.remote;
  
  @override
  void initState() {
    super.initState();
    _refreshData();
  }
  
  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }
  
  Future<void> _refreshData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      // Forzar una sincronización con las fuentes remotas
      await _categoriaService.syncWithRemote();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al sincronizar datos: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showAddCategoriaDialog() {
    _nombreController.clear();
    _descripcionController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Categoría'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un nombre';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<DataSourcePriority>(
                decoration: const InputDecoration(
                  labelText: 'Guardar en',
                  border: OutlineInputBorder(),
                ),
                value: _currentPriority,
                items: const [
                  DropdownMenuItem(
                    value: DataSourcePriority.remote,
                    child: Text('Supabase (Remoto)'),
                  ),
                  DropdownMenuItem(
                    value: DataSourcePriority.turso,
                    child: Text('Turso (Remoto)'),
                  ),
                  DropdownMenuItem(
                    value: DataSourcePriority.local,
                    child: Text('SQLite (Local)'),
                  ),
                  DropdownMenuItem(
                    value: DataSourcePriority.all,
                    child: Text('Todos (Cascada)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _currentPriority = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _addCategoria,
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _addCategoria() async {
    if (_formKey.currentState!.validate()) {
      final newCategoria = CategoriaProducto(
        nombre: _nombreController.text,
        descripcion: _descripcionController.text.isEmpty 
            ? null 
            : _descripcionController.text,
      );
      
      Navigator.pop(context);
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        final result = await _categoriaService.createCategoria(
          newCategoria, 
          priority: _currentPriority
        );
        
        if (result == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error al crear la categoría')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  Future<void> _deleteCategoria(String id) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await _categoriaService.deleteCategoria(id);
      
      if (!result && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar la categoría')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _changePriority(DataSourcePriority priority) async {
    if (_currentPriority == priority) return;
    
    setState(() {
      _isLoading = true;
      _currentPriority = priority;
    });
    
    try {
      await _categoriaService.setDataSourcePriority(priority);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar la prioridad: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const Text('Origen de datos:'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SegmentedButton<DataSourcePriority>(
                              segments: const [
                                ButtonSegment(
                                  value: DataSourcePriority.remote,
                                  label: Text('Supabase'),
                                  icon: Icon(Icons.cloud),
                                ),
                                ButtonSegment(
                                  value: DataSourcePriority.turso,
                                  label: Text('Turso'),
                                  icon: Icon(Icons.cloud_queue),
                                ),
                                ButtonSegment(
                                  value: DataSourcePriority.local,
                                  label: Text('Local'),
                                  icon: Icon(Icons.storage),
                                ),
                              ],
                              selected: {_currentPriority},
                              onSelectionChanged: (Set<DataSourcePriority> newSelection) {
                                _changePriority(newSelection.first);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<CategoriaProducto>>(
                    stream: _categoriaService.categoriasStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                    
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }
                    
                      final categorias = snapshot.data ?? [];
                    
                      if (categorias.isEmpty) {
                        return const Center(
                          child: Text('No hay categorías disponibles'),
                        );
                      }
                    
                      return RefreshIndicator(
                        onRefresh: _refreshData,
                        child: ListView.builder(
                          itemCount: categorias.length,
                          itemBuilder: (context, index) {
                            final categoria = categorias[index];
                            return CategoriaListItem(
                              categoria: categoria,
                              onDelete: () => _deleteCategoria(categoria.id!),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoriaDialog,
        tooltip: 'Agregar Categoría',
        child: const Icon(Icons.add),
      ),
    );
  }
}