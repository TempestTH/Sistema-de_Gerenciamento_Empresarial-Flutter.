import 'package:flutter/material.dart';
import 'package:projeto_elifone/model/agendamento_anexo_model.dart';
import 'package:projeto_elifone/model/agendamento_historico_model.dart';
import 'package:projeto_elifone/model/agendamento_item_model.dart';
import 'package:projeto_elifone/model/agendamento_model.dart';
import 'package:projeto_elifone/model/estoque_model.dart';
import 'package:projeto_elifone/model/material_model.dart';
import 'package:projeto_elifone/services/supabase_agendamento_service.dart';
import 'package:projeto_elifone/services/supabase_estoque_service.dart';
import 'package:projeto_elifone/services/supabase_material_service.dart';

const List<String> _statusOptions = [
  'Agendado',
  'Urgente',
  'Em Execucao',
  'Concluido',
  'Cancelado',
];

class DetalhesServicoPage extends StatefulWidget {
  final AgendamentoModel agendamento;
  final VoidCallback? onVoltar;

  const DetalhesServicoPage({
    super.key,
    required this.agendamento,
    this.onVoltar,
  });

  @override
  State<DetalhesServicoPage> createState() => _DetalhesServicoPageState();
}

class _DetalhesServicoPageState extends State<DetalhesServicoPage> {
  final agendamentoService = SupabaseAgendamentoService();
  final materialService = SupabaseMaterialService();
  final estoqueService = SupabaseEstoqueService();
  final descricaoController = TextEditingController();

  late AgendamentoModel agendamento;
  List<AgendamentoItemModel> itens = [];
  List<AgendamentoAnexoModel> anexos = [];
  List<AgendamentoHistoricoModel> historico = [];
  List<MaterialModel> materiais = [];
  bool loading = true;
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    agendamento = widget.agendamento;
    descricaoController.text = agendamento.observacao ?? '';
    carregarDetalhes();
  }

  @override
  void dispose() {
    descricaoController.dispose();
    super.dispose();
  }

  Future<void> carregarDetalhes() async {
    setState(() => loading = true);

    try {
      final id = agendamento.id;
      final materialData = await materialService.listar();
      if (id == null) {
        throw Exception('Agendamento local');
      }

      final agendamentoData = await agendamentoService.buscarPorId(id);
      final itensData = await agendamentoService.listarItens(id);
      final anexosData = await agendamentoService.listarAnexos(id);
      final historicoData = await agendamentoService.listarHistorico(id);

      if (!mounted) return;
      setState(() {
        agendamento = agendamentoData;
        descricaoController.text = agendamentoData.observacao ?? '';
        materiais = materialData;
        itens = itensData;
        anexos = anexosData;
        historico = historicoData;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        materiais = [];
        itens = [];
        anexos = [];
        historico = [];
        loading = false;
      });
    }
  }

  Future<void> salvarAlteracoes({bool concluir = false}) async {
    setState(() => salvando = true);

    final novoStatus = concluir ? 'Concluido' : agendamento.status;
    final atualizado = AgendamentoModel(
      id: agendamento.id,
      createdAt: agendamento.createdAt,
      cliente: agendamento.cliente,
      servico: agendamento.servico,
      responsavel: agendamento.responsavel,
      inicio: agendamento.inicio,
      fim: agendamento.fim,
      status: novoStatus,
      valor: _valorTotal,
      observacao: descricaoController.text,
    );

    try {
      if (agendamento.id != null) {
        await agendamentoService.atualizar(atualizado, agendamento.id!);

        if (concluir) {
          await _registrarSaidasDeMateriais();
          await agendamentoService.inserirHistorico(
            AgendamentoHistoricoModel(
              idAgendamento: agendamento.id,
              titulo: 'Servico concluido',
              descricao: 'Status alterado automaticamente para concluido.',
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        agendamento = atualizado;
        salvando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            concluir
                ? 'Servico concluido e saidas registradas.'
                : 'Alteracoes salvas.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        agendamento = atualizado;
        salvando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alteracoes aplicadas na tela. Verifique as tabelas.'),
        ),
      );
    }
  }

  Future<void> _registrarSaidasDeMateriais() async {
    for (final item in itens.where((item) => item.material)) {
      final idMaterial = item.idMaterial;
      if (idMaterial == null) continue;

      await estoqueService.inserir(
        EstoqueModel(
          quantidade: item.quantidade.round(),
          idMaterial: idMaterial,
          entrada: false,
          saida: true,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _abrirModalItem() async {
    final item = await showDialog<AgendamentoItemModel>(
      context: context,
      builder: (_) => _ItemServicoModal(materiais: materiais),
    );

    if (item == null) return;

    final itemComServico = AgendamentoItemModel(
      idAgendamento: agendamento.id,
      idMaterial: item.idMaterial,
      descricao: item.descricao,
      quantidade: item.quantidade,
      valorUnitario: item.valorUnitario,
      material: item.material,
    );

    try {
      if (agendamento.id != null) {
        await agendamentoService.inserirItem(itemComServico);
        await carregarDetalhes();
      } else {
        setState(() => itens = [...itens, itemComServico]);
      }
    } catch (_) {
      setState(() => itens = [...itens, itemComServico]);
    }
  }

  Future<void> _removerItem(AgendamentoItemModel item) async {
    try {
      if (item.id != null) {
        await agendamentoService.deletarItem(item.id!);
        await carregarDetalhes();
      } else {
        setState(() => itens = itens.where((value) => value != item).toList());
      }
    } catch (_) {
      setState(() => itens = itens.where((value) => value != item).toList());
    }
  }

  Future<void> _adicionarAnexo(String tipo) async {
    final anexo = AgendamentoAnexoModel(
      idAgendamento: agendamento.id,
      nome: tipo == 'foto' ? 'foto_servico.jpg' : 'os_assinada.pdf',
      tipo: tipo,
      caminho: tipo == 'foto' ? 'camera/local' : 'arquivo/local',
    );

    try {
      if (agendamento.id != null) {
        await agendamentoService.inserirAnexo(anexo);
        await carregarDetalhes();
      } else {
        setState(() => anexos = [anexo, ...anexos]);
      }
    } catch (_) {
      setState(() => anexos = [anexo, ...anexos]);
    }
  }

  Future<void> _removerAnexo(AgendamentoAnexoModel anexo) async {
    try {
      if (anexo.id != null) {
        await agendamentoService.deletarAnexo(anexo.id!);
        await carregarDetalhes();
      } else {
        setState(
          () => anexos = anexos.where((value) => value != anexo).toList(),
        );
      }
    } catch (_) {
      setState(() => anexos = anexos.where((value) => value != anexo).toList());
    }
  }

  num get _valorTotal {
    if (itens.isEmpty) return agendamento.valor;
    return itens.fold<num>(0, (total, item) => total + item.total);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopo(),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 900;
                      if (compact) {
                        return Column(
                          children: [
                            _buildPrincipal(),
                            const SizedBox(height: 16),
                            _buildLateral(),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildPrincipal()),
                          const SizedBox(width: 18),
                          Expanded(child: _buildLateral()),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTopo() {
    final podeConcluir = agendamento.status != 'Concluido';

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 340,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: widget.onVoltar,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar para agenda'),
              ),
              Row(
                children: [
                  _StatusPill(status: agendamento.status),
                  const SizedBox(width: 8),
                  Text(
                    'Ref: OS-${(agendamento.id ?? 0).toString().padLeft(4, '0')}',
                    style: const TextStyle(color: Color(0xFF4B5563)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Detalhes do Servico',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.print, size: 18),
              label: const Text('Imprimir'),
              style: _secondaryButtonStyle(),
            ),
            OutlinedButton.icon(
              onPressed: loading ? null : carregarDetalhes,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Atualizar'),
              style: _secondaryButtonStyle(),
            ),
            if (podeConcluir)
              FilledButton.icon(
                onPressed: salvando
                    ? null
                    : () => salvarAlteracoes(concluir: true),
                icon: const Icon(Icons.task_alt, size: 18),
                label: const Text('Concluir Servico'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                ),
              ),
            FilledButton.icon(
              onPressed: salvando ? null : salvarAlteracoes,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Salvar Alteracoes'),
              style: _primaryButtonStyle(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrincipal() {
    return Column(
      children: [
        _Panel(
          title: 'Informacoes Gerais',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 36,
                runSpacing: 16,
                children: [
                  _InfoBlock(label: 'Cliente', value: agendamento.cliente),
                  _InfoBlock(
                    label: 'Data de inicio',
                    value: _formatDate(agendamento.inicio),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      initialValue: _statusOptions.contains(agendamento.status)
                          ? agendamento.status
                          : 'Agendado',
                      decoration: _fieldDecoration('Status'),
                      items: _statusOptions
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          agendamento = AgendamentoModel(
                            id: agendamento.id,
                            createdAt: agendamento.createdAt,
                            cliente: agendamento.cliente,
                            servico: agendamento.servico,
                            responsavel: agendamento.responsavel,
                            inicio: agendamento.inicio,
                            fim: agendamento.fim,
                            status: value,
                            valor: agendamento.valor,
                            observacao: agendamento.observacao,
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionLabel('Descricao do servico'),
              const SizedBox(height: 8),
              TextField(
                controller: descricaoController,
                minLines: 4,
                maxLines: 6,
                decoration: _fieldDecoration('Detalhes do atendimento...'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Materiais e Valores',
          action: TextButton.icon(
            onPressed: _abrirModalItem,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar item'),
          ),
          child: Column(
            children: [
              _buildItensHeader(),
              ...itens.map(_buildItemRow),
              Container(
                padding: const EdgeInsets.all(14),
                color: const Color(0xFFF4F4F5),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Valor Total do Servico',
                        textAlign: TextAlign.end,
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 120,
                      child: Text(
                        _formatCurrency(_valorTotal),
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLateral() {
    return Column(
      children: [
        _Panel(
          title: 'Upload da Ordem',
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFFD1D5DB),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload, color: Color(0xFF2563EB)),
                    const SizedBox(height: 12),
                    const Text(
                      'Adicionar OS, foto ou comprovante',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _adicionarAnexo('arquivo'),
                          icon: const Icon(Icons.attach_file, size: 18),
                          label: const Text('Arquivo'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _adicionarAnexo('foto'),
                          icon: const Icon(Icons.photo_camera, size: 18),
                          label: const Text('Foto'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...anexos.map(_buildAnexoRow),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Historico',
          child: Column(children: historico.map(_buildHistoricoRow).toList()),
        ),
      ],
    );
  }

  Widget _buildItensHeader() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'ITEM / DESCRICAO',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(child: Text('QTD', textAlign: TextAlign.end)),
          Expanded(child: Text('UNITARIO', textAlign: TextAlign.end)),
          Expanded(child: Text('TOTAL', textAlign: TextAlign.end)),
          SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _buildItemRow(AgendamentoItemModel item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(item.descricao)),
          Expanded(
            child: Text(item.quantidade.toString(), textAlign: TextAlign.end),
          ),
          Expanded(
            child: Text(
              _formatCurrency(item.valorUnitario),
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            child: Text(
              _formatCurrency(item.total),
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          SizedBox(
            width: 42,
            child: IconButton(
              onPressed: () => _removerItem(item),
              icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnexoRow(AgendamentoAnexoModel anexo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(anexo.tipo == 'foto' ? Icons.image : Icons.description),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              anexo.nome,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            onPressed: () => _removerAnexo(anexo),
            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricoRow(AgendamentoHistoricoModel item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.createdAt == null
                      ? 'Agora'
                      : _formatDate(item.createdAt!),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                ),
                Text(
                  item.titulo,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(item.descricao, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemServicoModal extends StatefulWidget {
  final List<MaterialModel> materiais;

  const _ItemServicoModal({required this.materiais});

  @override
  State<_ItemServicoModal> createState() => _ItemServicoModalState();
}

class _ItemServicoModalState extends State<_ItemServicoModal> {
  final descricaoController = TextEditingController();
  final quantidadeController = TextEditingController(text: '1');
  final valorController = TextEditingController(text: '0');
  MaterialModel? materialSelecionado;
  bool usarMaterial = false;

  @override
  void dispose() {
    descricaoController.dispose();
    quantidadeController.dispose();
    valorController.dispose();
    super.dispose();
  }

  void salvar() {
    final descricao = usarMaterial
        ? materialSelecionado?.nome ?? ''
        : descricaoController.text;

    if (descricao.isEmpty) return;

    Navigator.pop(
      context,
      AgendamentoItemModel(
        idMaterial: materialSelecionado?.id,
        descricao: descricao,
        quantidade:
            num.tryParse(quantidadeController.text.replaceAll(',', '.')) ?? 1,
        valorUnitario:
            num.tryParse(valorController.text.replaceAll(',', '.')) ?? 0,
        material: usarMaterial,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFBF9FA),
            borderRadius: BorderRadius.circular(6),
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
                        'Adicionar Item',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: usarMaterial,
                      onChanged: (value) {
                        setState(() => usarMaterial = value ?? false);
                      },
                      title: const Text('Este item e material do estoque'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 12),
                    if (usarMaterial)
                      DropdownButtonFormField<MaterialModel>(
                        initialValue: materialSelecionado,
                        decoration: _fieldDecoration('Material'),
                        items: widget.materiais
                            .map(
                              (material) => DropdownMenuItem(
                                value: material,
                                child: Text(material.nome),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            materialSelecionado = value;
                            valorController.text =
                                value?.valor.toString() ?? valorController.text;
                          });
                        },
                      )
                    else
                      TextField(
                        controller: descricaoController,
                        decoration: _fieldDecoration('Descricao'),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: quantidadeController,
                            keyboardType: TextInputType.number,
                            decoration: _fieldDecoration('Quantidade'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: valorController,
                            keyboardType: TextInputType.number,
                            decoration: _fieldDecoration('Valor unitario'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: _secondaryButtonStyle(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: salvar,
                      style: _primaryButtonStyle(),
                      child: const Text('Salvar'),
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

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;

  const _Panel({required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
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

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;

  const _InfoBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(label),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      color: const Color(0xFFDDEBFF),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

Widget _sectionLabel(String label) {
  return Text(
    label.toUpperCase(),
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
      borderSide: BorderSide(color: Colors.black),
    ),
  );
}

ButtonStyle _primaryButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    shape: const RoundedRectangleBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  );
}

ButtonStyle _secondaryButtonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: Colors.black,
    side: const BorderSide(color: Color(0xFFD1D5DB)),
    shape: const RoundedRectangleBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  );
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _formatCurrency(num value) {
  return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}
