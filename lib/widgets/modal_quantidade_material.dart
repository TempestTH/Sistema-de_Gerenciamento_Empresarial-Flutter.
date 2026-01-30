import 'package:flutter/material.dart';

class ModalQuantidadeMaterial extends StatelessWidget {
  final List<dynamic> materiaisSelecionados;
  final Map<int, TextEditingController> controllers;
  final VoidCallback onConfirmar;
  final bool carregando;

  const ModalQuantidadeMaterial({
    super.key,
    required this.materiaisSelecionados,
    required this.controllers,
    required this.onConfirmar,
    required this.carregando,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text("Adicionar quantidades"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: materiaisSelecionados.map((material) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: controllers[material.id],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: material.nome,
                  hintText: "Quantidade",
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: carregando ? null : () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: carregando ? null : onConfirmar,
          child: carregando
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Confirmar"),
        ),
      ],
    );
  }
}
