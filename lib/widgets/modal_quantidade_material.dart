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

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Color(0xFF111827), width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFBF9FA),
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 14, 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Adicionar Quantidades',
                        style: TextStyle(
                          color: Color(0xFF2F3137),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: carregando
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFD9D9DE)),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: materiaisSelecionados.map((material) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            _label(material.nome),
                            const SizedBox(height: 8),
                            TextField(
                              controller: controllers[material.id],
                              keyboardType: TextInputType.number,
                              decoration: _fieldDecoration('Quantidade'),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: carregando
                          ? null
                          : () => Navigator.pop(context),
                      style: _modalSecondaryButtonStyle(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: carregando ? null : onConfirmar,
                      style: _modalPrimaryButtonStyle(),
                      child: carregando
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Confirmar'),
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

ButtonStyle _modalPrimaryButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    shape: const RoundedRectangleBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
  );
}

ButtonStyle _modalSecondaryButtonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF374151),
    side: const BorderSide(color: Color(0xFFD1D5DB)),
    shape: const RoundedRectangleBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
  );
}
