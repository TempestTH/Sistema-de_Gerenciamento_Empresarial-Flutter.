import 'package:flutter/material.dart';
import 'package:projeto_elifone/services/supabase_material_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final SupabaseMaterialService service = SupabaseMaterialService();

  List<dynamic> usuarios = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    carregarUsuarios();
  }

  Future<void> carregarUsuarios() async {
    try {
      final data = await service.listar();

      setState(() {
        usuarios = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      debugPrint('Erro: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : usuarios.isEmpty
              ? const Center(child: Text('Nenhum registro encontrado'))
              : ListView.builder(
                  itemCount: usuarios.length,
                  itemBuilder: (context, index) {
                    final user = usuarios[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.id.toString()),
                      ),
                      title: Text(user.nome ?? 'Sem nome'),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: carregarUsuarios,
        tooltip: 'Atualizar',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
