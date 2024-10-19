import 'package:flutter/material.dart';
import 'package:neoglot/audio_button.dart';
import 'package:neoglot/language_enum.dart';

class LanguageTab extends StatelessWidget {
  const LanguageTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'CN / EN'),
              Tab(text: 'CN / FR'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                TabContent(
                  language1: LanguageEnum.EN,
                  language2: LanguageEnum.CN,
                ),
                TabContent(
                  language1: LanguageEnum.FR,
                  language2: LanguageEnum.CN,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TabContent extends StatelessWidget {
  const TabContent({
    super.key,
    required this.language1,
    required this.language2,
  });

  final LanguageEnum language1;
  final LanguageEnum language2;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(80.0),
            child: AudioButton(language: language1, onPressedEnd: () {}),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(80.0),
            child: AudioButton(language: language2, onPressedEnd: () {}),
          ),
        ),
      ],
    );
  }
}
