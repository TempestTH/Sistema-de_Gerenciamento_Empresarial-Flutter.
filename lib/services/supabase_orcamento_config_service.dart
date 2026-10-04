import 'dart:convert';
import 'dart:typed_data';

import 'package:projeto_elifone/model/orcamento_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseOrcamentoConfigService {
  static const String _bucket = 'orcamento-imagens';

  final SupabaseClient _client = Supabase.instance.client;

  Future<OrcamentoLayoutModel?> buscar() async {
    final data = await _client
        .from('orcamento_config')
        .select()
        .eq('id', 1)
        .maybeSingle();

    if (data == null) return null;
    return _layoutFromConfig(Map<String, dynamic>.from(data));
  }

  Future<OrcamentoLayoutModel> salvar(OrcamentoLayoutModel layout) async {
    final cabecalhoPath = await _salvarImagem(
      bytes: layout.cabecalho,
      nomeArquivo: layout.cabecalhoNome,
      pathAtual: layout.cabecalhoPath,
      prefixo: 'cabecalho',
    );
    final rodapePath = await _salvarImagem(
      bytes: layout.rodape,
      nomeArquivo: layout.rodapeNome,
      pathAtual: layout.rodapePath,
      prefixo: 'rodape',
    );

    final data = await _client
        .from('orcamento_config')
        .upsert({
          'id': 1,
          'texto_padrao': layout.textoPadrao,
          'cabecalho_path': cabecalhoPath,
          'rodape_path': rodapePath,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return _layoutFromConfig(Map<String, dynamic>.from(data));
  }

  Future<OrcamentoLayoutModel> _layoutFromConfig(
    Map<String, dynamic> json,
  ) async {
    final cabecalhoPath = _pathFromJson(json['cabecalho_path']);
    final rodapePath = _pathFromJson(json['rodape_path']);

    return OrcamentoLayoutModel(
      textoPadrao: json['texto_padrao'] ?? '',
      cabecalho: await _bytesFromStorageOrBase64(
        path: cabecalhoPath,
        base64Value: json['cabecalho_base64'] ?? json['cabecalho_path'],
      ),
      cabecalhoNome: _nomeFromPath(cabecalhoPath),
      cabecalhoPath: cabecalhoPath,
      rodape: await _bytesFromStorageOrBase64(
        path: rodapePath,
        base64Value: json['rodape_base64'] ?? json['rodape_path'],
      ),
      rodapeNome: _nomeFromPath(rodapePath),
      rodapePath: rodapePath,
    );
  }

  Future<String?> _salvarImagem({
    required Uint8List? bytes,
    required String? nomeArquivo,
    required String? pathAtual,
    required String prefixo,
  }) async {
    if (bytes == null) return null;
    final extension = _extensionFromName(nomeArquivo ?? pathAtual);
    final path = 'config/$prefixo$extension';

    await _client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentType(extension),
          ),
        );

    return path;
  }

  Future<Uint8List?> _bytesFromStorageOrBase64({
    required String? path,
    required dynamic base64Value,
  }) async {
    if (path != null) {
      return _client.storage.from(_bucket).download(path);
    }

    final value = base64Value?.toString();
    if (value == null || value.isEmpty) return null;
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  String? _pathFromJson(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    final text = value.toString();
    try {
      base64Decode(text);
      return null;
    } catch (_) {
      return text;
    }
  }

  String? _nomeFromPath(String? path) {
    if (path == null || path.isEmpty) return null;
    return path.split('/').last;
  }

  String _extensionFromName(String? name) {
    final sanitized = name?.toLowerCase().split('?').first ?? '';
    final index = sanitized.lastIndexOf('.');
    if (index == -1) return '.png';
    final extension = sanitized.substring(index);
    const allowed = {'.jpg', '.jpeg', '.png', '.webp'};
    return allowed.contains(extension) ? extension : '.png';
  }

  String _contentType(String extension) {
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.webp':
        return 'image/webp';
      case '.png':
      default:
        return 'image/png';
    }
  }
}
