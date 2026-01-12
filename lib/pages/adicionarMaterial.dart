import 'package:flutter/material.dart';
import 'package:projeto_elifone/model/material_model.dart';
import 'package:projeto_elifone/services/supabase_material_service.dart';

class AdicionarMaterialPage extends StatefulWidget {
  const AdicionarMaterialPage({super.key});

  @override
  State<AdicionarMaterialPage> createState() => _AdicionarMaterialPageState();
}

class _AdicionarMaterialPageState extends State<AdicionarMaterialPage> {
  final SupabaseMaterialService materialService = SupabaseMaterialService();

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController valorController = TextEditingController();

  bool metros = false;
  bool salvando = false;

  Future<void> salvarMaterial() async {
    if (nomeController.text.isEmpty || valorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Preencha todos os campos"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => salvando = true);

    try {
      final String nome = nomeController.text;
      final double valor = double.parse(valorController.text);

      await materialService.inserir(
        MaterialModel(
          nome: nome,
          valor: valor,
          metro: metros,
          quantidade: 0, // quando cria o material, quantidade inicial é 0
          createdAt: DateTime.now(),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Material adicionado com sucesso!"),
          duration: Duration(seconds: 2),
        ),
      );

      // limpa campos
      nomeController.clear();
      valorController.clear();
      setState(() {
        metros = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erro ao adicionar material"),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() => salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Adicionar Material")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Nome do Material"),
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                hintText: "Digite o nome do material",
              ),
            ),

            const SizedBox(height: 16),
            const Text("Valor do Material"),
            TextField(
              controller: valorController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: "Ex: 50.25",
              ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: metros,
                  onChanged: (value) {
                    setState(() {
                      metros = value ?? false;
                    });
                  },
                ),
                const Text("Medido em metros"),
              ],
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: salvando ? null : salvarMaterial,
                child: salvando
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
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
