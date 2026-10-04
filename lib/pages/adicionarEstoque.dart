import 'package:flutter/material.dart';
import 'package:projeto_elifone/theme/app_theme.dart';
import 'package:projeto_elifone/model/estoque_model.dart';
import 'package:projeto_elifone/model/material_model.dart';
import 'package:projeto_elifone/services/supabase_estoque_service.dart';
import 'package:projeto_elifone/services/supabase_material_service.dart';

class AdicionarEstoquePage extends StatefulWidget {
  final bool entradaInicial;
  final bool saidaInicial;

  const AdicionarEstoquePage({
    super.key,
    this.entradaInicial = false,
    this.saidaInicial = false,
  });

  @override
  State<AdicionarEstoquePage> createState() => _AdicionarEstoquePageState();
}

class _AdicionarEstoquePageState extends State<AdicionarEstoquePage> {
  final materialService = SupabaseMaterialService();
  final estoqueService = SupabaseEstoqueService();

  final buscaController = TextEditingController();
  final nomeController = TextEditingController();
  final valorController = TextEditingController();
  final quantidadeController = TextEditingController();

  List<MaterialModel> materiais = [];
  List<dynamic> movimentacoes = [];
  MaterialModel? materialSelecionado;
  String modo = 'inventario';
  bool medidoEmMetros = false;
  bool loading = true;
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    if (widget.entradaInicial) modo = 'entrada';
    if (widget.saidaInicial) modo = 'saida';
    carregarDados();
  }

  @override
  void dispose() {
    buscaController.dispose();
    nomeController.dispose();
    valorController.dispose();
    quantidadeController.dispose();
    super.dispose();
  }

  Future<void> carregarDados() async {
    setState(() => loading = true);

    try {
      final materiaisData = await materialService.listar();
      final movimentacoesData = await estoqueService.listarComMaterial();

      if (!mounted) return;
      setState(() {
        materiais = materiaisData;
        movimentacoes = movimentacoesData;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      _mostrarMensagem('Nao foi possivel carregar o estoque.');
    }
  }

  List<MaterialModel> get materiaisFiltrados {
    final busca = buscaController.text.trim().toLowerCase();
    if (busca.isEmpty) return materiais;

    return materiais.where((material) {
      return material.nome.toLowerCase().contains(busca);
    }).toList();
  }

  int get totalItens {
    return materiais.fold<int>(0, (total, item) => total + item.quantidade);
  }

  num get valorEmEstoque {
    return materiais.fold<num>(
      0,
      (total, item) => total + (item.quantidade * item.valor),
    );
  }

  int get estoqueBaixo {
    return materiais.where((item) => item.quantidade <= 10).length;
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
      setState(() {
        medidoEmMetros = false;
        modo = 'inventario';
      });
      await carregarDados();
      _mostrarMensagem('Material adicionado com sucesso.');
    } catch (_) {
      _mostrarMensagem('Erro ao adicionar material.');
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  Future<void> confirmarMovimentacao({required bool entrada}) async {
    final material = materialSelecionado;
    final quantidade = int.tryParse(quantidadeController.text);

    if (material == null || quantidade == null || quantidade <= 0) {
      _mostrarMensagem('Selecione o material e informe uma quantidade valida.');
      return;
    }

    final novoTotal = entrada
        ? material.quantidade + quantidade
        : material.quantidade - quantidade;

    if (novoTotal < 0) {
      _mostrarMensagem('A saida nao pode deixar o estoque negativo.');
      return;
    }

    setState(() => salvando = true);
    try {
      await estoqueService.inserir(
        EstoqueModel(
          quantidade: quantidade,
          idMaterial: material.id!,
          entrada: entrada,
          saida: !entrada,
          createdAt: DateTime.now(),
        ),
      );
      await materialService.atualizarQuantidade(material.id!, novoTotal);

      quantidadeController.clear();
      setState(() {
        materialSelecionado = null;
        modo = 'inventario';
      });
      await carregarDados();
      _mostrarMensagem(
        entrada
            ? 'Entrada registrada com sucesso.'
            : 'Saida registrada com sucesso.',
      );
    } catch (_) {
      _mostrarMensagem('Erro ao registrar movimentacao.');
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: carregarDados,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 18),
                    _buildMetricas(),
                    const SizedBox(height: 18),
                    _buildConteudo(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 880;

        return Flex(
          direction: compacto ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: compacto
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gerenciamento de Estoque',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text(
                  'Materiais, entradas e saidas em um fluxo unico.',
                  style: TextStyle(color: AppColors.mutedText),
                ),
              ],
            ),
            if (compacto) const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _modoButton('inventario', 'Inventario', Icons.inventory_2),
                _modoButton('entrada', 'Entrada', Icons.login),
                _modoButton('saida', 'Saida', Icons.logout),
                _modoButton('material', 'Novo Material', Icons.add),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _modoButton(String value, String label, IconData icon) {
    final selecionado = modo == value;
    return selecionado
        ? FilledButton.icon(
            onPressed: () => setState(() => modo = value),
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          )
        : OutlinedButton.icon(
            onPressed: () => setState(() => modo = value),
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          );
  }

  Widget _buildMetricas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colunas = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        final largura = (constraints.maxWidth - ((colunas - 1) * 12)) / colunas;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: largura,
              child: _MetricaCard(
                titulo: 'Total de Itens',
                valor: totalItens.toString(),
                legenda: '${materiais.length} materiais cadastrados',
                icon: Icons.category_outlined,
              ),
            ),
            SizedBox(
              width: largura,
              child: _MetricaCard(
                titulo: 'Estoque Baixo',
                valor: estoqueBaixo.toString(),
                legenda: 'Itens com 10 unidades ou menos',
                icon: Icons.warning_amber,
                destaque: estoqueBaixo > 0,
              ),
            ),
            SizedBox(
              width: largura,
              child: _MetricaCard(
                titulo: 'Valor em Estoque',
                valor: _formatCurrency(valorEmEstoque),
                legenda: 'Quantidade x preco unitario',
                icon: Icons.payments_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConteudo() {
    return switch (modo) {
      'entrada' => _buildMovimentacao(entrada: true),
      'saida' => _buildMovimentacao(entrada: false),
      'material' => _buildNovoMaterial(),
      _ => _buildInventario(),
    };
  }

  Widget _buildInventario() {
    return Column(
      children: [
        _Painel(
          title: 'Lista de Materiais',
          action: SizedBox(
            width: 280,
            child: TextField(
              controller: buscaController,
              onChanged: (_) => setState(() {}),
              decoration: _fieldDecoration(
                'Pesquisar material...',
              ).copyWith(prefixIcon: const Icon(Icons.search, size: 18)),
            ),
          ),
          child: Column(
            children: [
              _buildMaterialHeader(),
              if (materiaisFiltrados.isEmpty)
                const _EmptyState(message: 'Nenhum material encontrado.')
              else
                ...materiaisFiltrados.map(_buildMaterialRow),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Painel(
          title: 'Ultimas Movimentacoes',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final larguraTabela = constraints.maxWidth < 760
                  ? 760.0
                  : constraints.maxWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: larguraTabela,
                  child: Column(
                    children: [
                      _buildMovimentacaoHeader(larguraTabela),
                      if (movimentacoes.isEmpty)
                        const _EmptyState(
                          message: 'Nenhuma movimentacao registrada.',
                        )
                      else
                        ...movimentacoes
                            .take(6)
                            .map(
                              (item) =>
                                  _buildMovimentacaoRow(item, larguraTabela),
                            ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNovoMaterial() {
    return _Painel(
      title: 'Adicionar Material',
      action: _formActions(onConfirmar: salvarMaterial),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Nome do material'),
          const SizedBox(height: 8),
          TextField(
            controller: nomeController,
            decoration: _fieldDecoration('Ex: Cabo de fibra optica 12F'),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compacto = constraints.maxWidth < 620;
              return Flex(
                direction: compacto ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: compacto ? 0 : 1,
                    child: Column(
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
                    ),
                  ),
                  SizedBox(width: compacto ? 0 : 12, height: compacto ? 16 : 0),
                  Expanded(
                    flex: compacto ? 0 : 1,
                    child: Column(
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
                          tileColor: AppColors.surface,
                          shape: const RoundedRectangleBorder(
                            side: BorderSide(color: AppColors.border),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMovimentacao({required bool entrada}) {
    final titulo = entrada
        ? 'Registrar Entrada de Material'
        : 'Registrar Saida de Estoque';
    final actionLabel = entrada ? 'Confirmar Entrada' : 'Confirmar Saida';

    return _Painel(
      title: titulo,
      action: _formActions(
        confirmarLabel: actionLabel,
        onConfirmar: () => confirmarMovimentacao(entrada: entrada),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Selecionar material'),
          const SizedBox(height: 8),
          DropdownButtonFormField<MaterialModel>(
            initialValue: materialSelecionado,
            isExpanded: true,
            decoration: _fieldDecoration('Item do inventario'),
            selectedItemBuilder: (context) => materiais
                .map(
                  (material) => Text(
                    '${material.nome} - ${material.quantidade} ${material.metro ? 'm' : 'un'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
                .toList(),
            items: materiais
                .map(
                  (material) => DropdownMenuItem(
                    value: material,
                    child: Text(
                      '${material.nome} - ${material.quantidade} ${material.metro ? 'm' : 'un'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => materialSelecionado = value),
          ),
          const SizedBox(height: 16),
          _label(entrada ? 'Quantidade adicionada' : 'Quantidade removida'),
          const SizedBox(height: 8),
          TextField(
            controller: quantidadeController,
            keyboardType: TextInputType.number,
            decoration: _fieldDecoration(entrada ? 'Ex: 20' : 'Ex: 5').copyWith(
              suffixText: materialSelecionado?.metro == true ? 'M' : 'UN',
            ),
          ),
          if (!entrada && materialSelecionado != null) ...[
            const SizedBox(height: 14),
            _AvisoEstoque(material: materialSelecionado!),
          ],
        ],
      ),
    );
  }

  Widget _formActions({
    String confirmarLabel = 'Salvar Material',
    required VoidCallback onConfirmar,
  }) {
    return Wrap(
      spacing: 8,
      children: [
        OutlinedButton(
          onPressed: salvando
              ? null
              : () => setState(() => modo = 'inventario'),
          style: _secondaryButtonStyle(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: salvando ? null : onConfirmar,
          style: _primaryButtonStyle(),
          child: salvando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.surface,
                  ),
                )
              : Text(confirmarLabel),
        ),
      ],
    );
  }

  Widget _buildMaterialHeader() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: _TableLabel('Material')),
          Expanded(child: _TableLabel('Nivel Atual')),
          Expanded(child: _TableLabel('Preco Unit.')),
          SizedBox(width: 92, child: _TableLabel('Status')),
        ],
      ),
    );
  }

  Widget _buildMaterialRow(MaterialModel material) {
    final baixo = material.quantidade <= 10;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              material.nome,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: Text(
              '${material.quantidade} ${material.metro ? 'm' : 'un'}',
              style: TextStyle(
                color: baixo ? AppColors.danger : AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Text(_formatCurrency(material.valor))),
          SizedBox(
            width: 92,
            child: _StatusBadge(
              label: baixo ? 'Critico' : 'Ok',
              color: baixo ? AppColors.danger : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovimentacaoRow(dynamic item, double larguraTabela) {
    final material = (item['Material']?['nome'] ?? '---').toString();
    final quantidade = (item['Quantidade'] ?? 0).toString();
    final entrada = item['Entrada'] == true;
    final created = DateTime.tryParse((item['created_at'] ?? '').toString());
    final larguraUtil = larguraTabela - 48;
    final dataWidth = larguraUtil * 0.17;
    final materialWidth = larguraUtil * 0.43;
    final quantidadeWidth = larguraUtil * 0.18;
    final tipoWidth = larguraUtil * 0.22;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: dataWidth,
            child: Text(
              created == null ? '---' : _formatDate(created),
              style: const TextStyle(color: AppColors.mutedText),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: materialWidth,
            child: Text(
              material,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: quantidadeWidth,
            child: Text(
              quantidade,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: tipoWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StatusBadge(
                label: entrada ? 'Entrada' : 'Saida',
                color: entrada ? AppColors.success : AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovimentacaoHeader(double larguraTabela) {
    final larguraUtil = larguraTabela - 48;
    final dataWidth = larguraUtil * 0.17;
    final materialWidth = larguraUtil * 0.43;
    final quantidadeWidth = larguraUtil * 0.18;
    final tipoWidth = larguraUtil * 0.22;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(width: dataWidth, child: const _TableLabel('Data')),
          const SizedBox(width: 16),
          SizedBox(width: materialWidth, child: const _TableLabel('Material')),
          const SizedBox(width: 16),
          SizedBox(
            width: quantidadeWidth,
            child: const Align(
              alignment: Alignment.centerRight,
              child: _TableLabel('Quantidade'),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(width: tipoWidth, child: const _TableLabel('Tipo')),
        ],
      ),
    );
  }
}

class _MetricaCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final String legenda;
  final IconData icon;
  final bool destaque;

  const _MetricaCard({
    required this.titulo,
    required this.valor,
    required this.legenda,
    required this.icon,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 126,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: destaque
            ? AppColors.danger.withValues(alpha: 0.08)
            : AppColors.surface,
        border: Border.all(
          color: destaque
              ? AppColors.danger.withValues(alpha: 0.24)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  titulo.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  valor,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  legenda,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: destaque ? AppColors.danger : AppColors.primary),
        ],
      ),
    );
  }
}

class _Painel extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;

  const _Painel({required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _AvisoEstoque extends StatelessWidget {
  final MaterialModel material;

  const _AvisoEstoque({required this.material});

  @override
  Widget build(BuildContext context) {
    final baixo = material.quantidade <= 10;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: baixo
            ? AppColors.danger.withValues(alpha: 0.08)
            : AppColors.surfaceAlt,
        border: Border.all(
          color: baixo
              ? AppColors.danger.withValues(alpha: 0.24)
              : AppColors.border,
        ),
      ),
      child: Text(
        'Saldo em estoque: ${material.quantidade} ${material.metro ? 'm' : 'un'}',
        style: TextStyle(
          color: baixo ? AppColors.danger : AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1)),
      child: Text(
        label.toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TableLabel extends StatelessWidget {
  final String text;

  const _TableLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.mutedText,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

Widget _label(String text) {
  return Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: AppColors.secondary,
      fontSize: 11,
      fontWeight: FontWeight.w900,
    ),
  );
}

InputDecoration _fieldDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.primary),
    ),
  );
}

ButtonStyle _primaryButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
  );
}

ButtonStyle _secondaryButtonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: const BorderSide(color: AppColors.border),
    shape: const RoundedRectangleBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
  );
}

String _formatCurrency(num value) {
  return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
