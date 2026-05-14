import 'package:flutter/material.dart';
import 'package:projeto_elifone/model/material_model.dart';
import 'package:projeto_elifone/services/supabase_material_service.dart';

class AdicionarMaterialPage extends StatefulWidget {
  const AdicionarMaterialPage({super.key});

  @override
  State<AdicionarMaterialPage> createState() => _AdicionarMaterialPageState();
}

class _AdicionarMaterialPageState extends State<AdicionarMaterialPage> {
  final materialService = SupabaseMaterialService();
  final nomeController = TextEditingController();
  final valorController = TextEditingController();

  bool medidoEmMetros = false;
  bool salvando = false;

  @override
  void dispose() {
    nomeController.dispose();
    valorController.dispose();
    super.dispose();
  }

  Future<void> salvarMaterial() async {
    final nome = nomeController.text.trim();
    final valor = num.tryParse(valorController.text.replaceAll(',', '.'));

    if (nome.isEmpty || valor == null) {
      _mostrarMensagem('Preencha nome e preco unitario.');
      return;
    }

    setState(() => salvando = true);
    try {
      await materialService.inserir(
        MaterialModel(
          nome: nome,
          quantidade: 0,
          valor: valor,
          metro: medidoEmMetros,
          createdAt: DateTime.now(),
        ),
      );

      nomeController.clear();
      valorController.clear();
      setState(() => medidoEmMetros = false);
      _mostrarMensagem('Material adicionado com sucesso.');
    } catch (_) {
      _mostrarMensagem('Erro ao adicionar material.');
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adicionar Material',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Cadastro direto para itens usados no estoque e nas ordens.',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Informacoes Gerais',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: salvando
                            ? null
                            : () {
                                nomeController.clear();
                                valorController.clear();
                                setState(() => medidoEmMetros = false);
                              },
                        style: _secondaryButtonStyle(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: salvando ? null : salvarMaterial,
                        style: _primaryButtonStyle(),
                        child: salvando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Salvar Material'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _label('Nome do material'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nomeController,
                    decoration: _fieldDecoration(
                      'Ex: Cabo de fibra optica 12F',
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compacto = constraints.maxWidth < 620;
                      final preco = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Preco unitario'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: valorController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _fieldDecoration('Ex: 85,00'),
                          ),
                        ],
                      );
                      final unidade = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Unidade de medida'),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            value: medidoEmMetros,
                            onChanged: (value) {
                              setState(() => medidoEmMetros = value);
                            },
                            title: Text(medidoEmMetros ? 'Metro' : 'Unidade'),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            tileColor: const Color(0xFFFAFAFA),
                            shape: const RoundedRectangleBorder(
                              side: BorderSide(color: Color(0xFFD1D5DB)),
                            ),
                          ),
                        ],
                      );

                      if (compacto) {
                        return Column(
                          children: [
                            preco,
                            const SizedBox(height: 16),
                            unidade,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: preco),
                          const SizedBox(width: 12),
                          Expanded(child: unidade),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _label(String text) {
  return Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: Color(0xFF374151),
      fontSize: 11,
      fontWeight: FontWeight.w900,
    ),
  );
}

InputDecoration _fieldDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFFAFAFA),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Color(0xFFD1D5DB)),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Color(0xFF111827)),
    ),
  );
}

ButtonStyle _primaryButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    shape: const RoundedRectangleBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
  );
}

ButtonStyle _secondaryButtonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: Colors.black,
    side: const BorderSide(color: Color(0xFFD1D5DB)),
    shape: const RoundedRectangleBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
  );
}
