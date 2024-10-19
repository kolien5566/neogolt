import 'package:flutter/material.dart';
import 'package:neoglot/language_tab.dart';

class Home extends StatelessWidget {
  const Home({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text("RealTime Traslator"),
        ),
        body: LanguageTab());
  }
}
