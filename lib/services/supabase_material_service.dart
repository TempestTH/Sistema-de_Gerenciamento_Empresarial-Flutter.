import '../model/material_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseMaterialService {
  final SupabaseClient _client = Supabase.instance.client;

    // CREATE
  Future<void> inserir(MaterialModel material) async {
    await _client
        .from('Material')
        .insert(material.toJson());
  }

  // READ
  Future<List<MaterialModel>> listar() async {
    final data = await _client
        .from('Material')
        .select();

    return (data as List)
        .map((json) => MaterialModel.fromJson(json))
        .toList();
  }

  // DELETE
  Future<void> deletar(int id) async {
    await _client
        .from('Material')
        .delete()
        .eq('id', id);
  }
}