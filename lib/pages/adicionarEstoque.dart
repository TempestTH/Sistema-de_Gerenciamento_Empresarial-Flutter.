import 'package:flutter/material.dart';
import 'package:projeto_elifone/model/estoque_model.dart';
import 'package:projeto_elifone/services/supabase_material_service.dart';
import 'package:projeto_elifone/services/supabase_estoque_service.dart';

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

class _AdicionarEstoquePageState extends State<AdicionarEstoquePage> {
  final SupabaseMaterialService materialService = SupabaseMaterialService();
  final SupabaseEstoqueService estoqueService = SupabaseEstoqueService();

  List<dynamic> materiais = [];
  List<dynamic> materiaisFiltrados = [];

  dynamic materialSelecionado;
  final TextEditingController buscaController = TextEditingController();
  final TextEditingController quantidadeController = TextEditingController();

  bool loading = true;
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    carregarMateriais();
  }

  Future<void> carregarMateriais() async {
    try {
      final data = await materialService.listar();
      setState(() {
        materiais = data;
        materiaisFiltrados = data;
        loading = false;
      });
    } catch (e) {
      loading = false;
    }
  }

  void filtrarMateriais(String value) {
    setState(() {
      materiaisFiltrados = materiais.where((m) {
        final nome = m.nome.toString().toLowerCase();
        return nome.contains(value.toLowerCase());
      }).toList();
    });
  }

  Future<void> salvar() async {
    if (materialSelecionado == null) return;
    if (quantidadeController.text.isEmpty) return;

    setState(() => salvando = true);

    final int materialId = materialSelecionado.id;
    final int quantidade = int.parse(quantidadeController.text);

    try {
      // 1️⃣ Inserir no estoque
      await estoqueService.inserir(
        EstoqueModel(
          idMaterial: materialId,
          quantidade: quantidade,
          entrada: widget.Entrada,
          saida: widget.Saida,
          createdAt: DateTime.now(),
        ),
      );

      // 2️⃣ Atualizar quantidade do material
      final int novoTotal;
      final int quantidadeAtual = materialSelecionado.quantidade ?? 0;
      if (widget.Entrada) {
        novoTotal = quantidadeAtual + quantidade;
      } else {
        novoTotal = quantidadeAtual - quantidade;
      }
      await materialService.atualizarQuantidade(
        materialId,
        novoTotal, // ✅ CORRETO
      );
      // Mostra a mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.Entrada
                ? "Entrada adicionada com sucesso!"
                : "Saída adicionada com sucesso!",
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Limpa os campos
      quantidadeController.clear();
      setState(() {
        materialSelecionado = null;
      });

      // Recarrega a lista de materiais
      carregarMateriais();
      salvando = false;
    } catch (e) {
      setState(() => salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro inesperado'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Adicionar ao Estoque")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Pesquisar Material"),
                  TextField(
                    controller: buscaController,
                    onChanged: filtrarMateriais,
                    decoration: const InputDecoration(
                      hintText: "Digite o nome do material...",
                    ),
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: materiaisFiltrados.isEmpty
                        ? const Center(
                            child: Text("Nenhum material encontrado"),
                          )
                        : ListView.builder(
                            itemCount: materiaisFiltrados.length,
                            itemBuilder: (context, index) {
                              final item = materiaisFiltrados[index];
                              return ListTile(
                                title: Text(item.nome),
                                selectedTileColor: Colors.grey.shade300,
                                subtitle: Text(
                                  "Quantidade atual: ${item.quantidade ?? 0}",
                                ),
                                selected: materialSelecionado?.id == item.id,
                                onTap: () {
                                  setState(() {
                                    materialSelecionado = item;
                                  });
                                },
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 10),
                  const Text("Quantidade a adicionar"),
                  TextField(
                    controller: quantidadeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: "Ex: 10"),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: salvando ? null : salvar,
                      child: salvando
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white, // deixa visível no botão
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("Salvar"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
