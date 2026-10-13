import 'package:flutter/material.dart';
import 'package:projeto_elifone/model/material_model.dart';

class MaterialSearchField extends StatelessWidget {
  final List<MaterialModel> materiais;
  final MaterialModel? selecionado;
  final ValueChanged<MaterialModel> onSelected;
  final InputDecoration decoration;
  final String Function(MaterialModel) labelBuilder;

  const MaterialSearchField({
    super.key,
    required this.materiais,
    required this.selecionado,
    required this.onSelected,
    required this.decoration,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<MaterialModel>(
      key: ValueKey(selecionado?.id),
      initialValue: TextEditingValue(
        text: selecionado == null ? '' : labelBuilder(selecionado!),
      ),
      displayStringForOption: labelBuilder,
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return materiais;
        return materiais.where(
          (material) =>
              material.nome.toLowerCase().contains(query) ||
              labelBuilder(material).toLowerCase().contains(query),
        );
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: decoration,
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onOptionSelected, options) {
        final items = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: SizedBox(
                width: double.infinity,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final material = items[index];
                    final highlightedIndex = AutocompleteHighlightedOption.of(
                      context,
                    );
                    return InkWell(
                      onTap: () => onOptionSelected(material),
                      child: Container(
                        color: index == highlightedIndex
                            ? Theme.of(context).highlightColor
                            : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Text(labelBuilder(material)),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
