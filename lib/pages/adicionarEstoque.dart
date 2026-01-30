import 'package:flutter/material.dart';
import 'package:projeto_elifone/Control/route_observer.dart';
import 'package:projeto_elifone/model/estoque_model.dart';
import 'package:projeto_elifone/services/supabase_material_service.dart';
import 'package:projeto_elifone/services/supabase_estoque_service.dart';
import 'package:projeto_elifone/widgets/modal_quantidade_material.dart';

class AdicionarEstoquePage extends StatefulWidget {
  final bool Entrada;
  final bool Saida;

  const AdicionarEstoquePage({
    super.key,
    required this.Entrada,
    required this.Saida,
  });

  @override
  State<AdicionarEstoquePage> createState() => _AdicionarEstoquePageState();
}

class _AdicionarEstoquePageState extends State<AdicionarEstoquePage>
    with RouteAware {
  final SupabaseMaterialService materialService = SupabaseMaterialService();
  final SupabaseEstoqueService estoqueService = SupabaseEstoqueService();

  List<dynamic> materiais = [];
  List<dynamic> materiaisFiltrados = [];
  List<dynamic> materiaisSelecionados = [];

  Map<int, TextEditingController> quantidadesPorMaterial = {};

  final TextEditingController buscaController = TextEditingController();

  bool loading = true;
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    carregarMateriais();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  // 🔥 SEMPRE que voltar para esta tela
  @override
  void didPopNext() {
    carregarMateriais();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    buscaController.dispose();
    for (final controller in quantidadesPorMaterial.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> carregarMateriais() async {
    final data = await materialService.listar();
    setState(() {
      materiais = data;
      materiaisFiltrados = data;
      loading = false;
    });
  }

  void filtrarMateriais(String value) {
    setState(() {
      materiaisFiltrados = materiais.where((m) {
        return m.nome.toLowerCase().contains(value.toLowerCase());
      }).toList();
    });
  }

  void toggleMaterial(dynamic material) {
    setState(() {
      if (materiaisSelecionados.contains(material)) {
        materiaisSelecionados.remove(material);
        quantidadesPorMaterial.remove(material.id);
      } else {
        materiaisSelecionados.add(material);
        quantidadesPorMaterial[material.id] = TextEditingController();
      }
    });
  }

  void abrirModalConfirmacao() {
    if (materiaisSelecionados.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ModalQuantidadeMaterial(
        materiaisSelecionados: materiaisSelecionados,
        controllers: quantidadesPorMaterial,
        carregando: salvando,
        onConfirmar: confirmarAlteracoes,
      ),
    );
  }

  Future<void> confirmarAlteracoes() async {
    setState(() => salvando = true);

    try {
      for (var material in materiaisSelecionados) {
        final controller = quantidadesPorMaterial[material.id]!;
        if (controller.text.isEmpty) continue;

        final int quantidade = int.parse(controller.text);
        final int quantidadeAtual = material.quantidade ?? 0;

        await estoqueService.inserir(
          EstoqueModel(
            idMaterial: material.id,
            quantidade: quantidade,
            entrada: widget.Entrada,
            saida: widget.Saida,
            createdAt: DateTime.now(),
          ),
        );

        final int novoTotal = widget.Entrada
            ? quantidadeAtual + quantidade
            : quantidadeAtual - quantidade;

        await materialService.atualizarQuantidade(material.id, novoTotal);
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.Entrada
                ? "Entradas adicionadas com sucesso!"
                : "Saídas adicionadas com sucesso!",
          ),
        ),
      );

      materiaisSelecionados.clear();
      quantidadesPorMaterial.clear();

      carregarMateriais();
    } finally {
      setState(() => salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1F5FE),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    onChanged: filtrarMateriais,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: "Pesquisar material...",
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF01579B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.builder(
                        itemCount: materiaisFiltrados.length,
                        itemBuilder: (_, index) {
                          final material = materiaisFiltrados[index];
                          final selecionado = materiaisSelecionados.contains(
                            material,
                          );

                          return CheckboxListTile(
                            value: selecionado,
                            onChanged: (_) => toggleMaterial(material),
                            title: Text(
                              material.nome,
                              style: const TextStyle(color: Colors.white),
                            ),
                            controlAffinity: ListTileControlAffinity.trailing,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: materiaisSelecionados.isEmpty || salvando
                          ? null
                          : abrirModalConfirmacao,
                      child: const Text("Adicionar"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
