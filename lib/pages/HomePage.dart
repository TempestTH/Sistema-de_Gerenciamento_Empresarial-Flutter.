import 'package:flutter/material.dart';
import 'package:projeto_elifone/services/supabase_estoque_service.dart';
import 'package:projeto_elifone/services/supabase_material_service.dart';
import 'package:projeto_elifone/widgets/estoque_table.dart';
import 'package:projeto_elifone/widgets/materiais_table.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final SupabaseMaterialService serviceMaterial = SupabaseMaterialService();
  final SupabaseEstoqueService serviceEstoque = SupabaseEstoqueService();
  List<dynamic> materiais = [];
  List<dynamic> estoque = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    carregarMaterial();
    carregarEstoque();
  }

  Future<void> carregarMaterial() async {
    try {
      final data = await serviceMaterial.listar();
      setState(() {
        materiais = data;
        loading = false;
      });
    } catch (e) {
      loading = false;
    }
  }

  Future<void> carregarEstoque() async {
    try {
      final data = await serviceEstoque.listarComMaterial();
      setState(() {
        estoque = data;
        loading = false;
      });
    } catch (e) {
      loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 219, 216, 216),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Card(
                      color: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,

                      child: ExpansionTile(
                        title: const Text(
                          "Materiais",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        collapsedIconColor: Colors.white,
                        iconColor: Colors.white,

                        childrenPadding: const EdgeInsets.all(16),

                        children: [
                          materiais.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    "Sem materiais cadastrados.\nCadastre materiais para visualizar aqui.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : MateriaisTable(
                                  data: materiais,
                                  onRefresh: carregarMaterial,
                                ),
                        ],
                      ),
                    ),
                    Card(
                      color: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,

                      child: ExpansionTile(
                        title: const Text(
                          "Estoque",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        collapsedIconColor: Colors.white,
                        iconColor: Colors.white,

                        childrenPadding: const EdgeInsets.all(16),

                        children: [
                          estoque.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    "Estoque vazio.\nCadastre materiais no estoque para visualizar aqui.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : EstoqueTable(
                                  data: estoque,
                                  onRefresh: carregarEstoque,
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
