import 'package:flutter/material.dart';
import 'package:projeto_elifone/Control/my_app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await Supabase.initialize(
    url: 'https://rfqbxnigjmxfjinhlqbh.supabase.co',
    anonKey: 'sb_publishable_Bk_XyPzUNyef3Qm1ye7p0A_aYpBsuCZ',
  );
  runApp(MyApp());
}