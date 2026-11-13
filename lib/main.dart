import 'package:flutter/material.dart';
import 'core/app_store.dart';
import 'core/cytech_theme.dart';
import 'screens/entry_flow.dart';
import 'screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store=AppStore();
  await store.initialize();
  runApp(MyApp(store:store));
}

class MyApp extends StatelessWidget{
  const MyApp({super.key,required this.store});
  final AppStore store;
  @override Widget build(BuildContext context)=>MaterialApp(
    debugShowCheckedModeBanner:false,
    title:'Cytech Manpower',
    theme:cytechTheme(),
    home:AnimatedBuilder(animation:store,builder:(context,_)=>
      store.signedIn?MainShell(store:store):EntryFlow(store:store)),
  );
}
