import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_config.dart';

class ConfigDrawer extends StatelessWidget {
  const ConfigDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppConfig>(
      builder: (context, config, child) {
        return Drawer(
          child: ListView(
            children: [
              const DrawerHeader(
                child: Text(
                  'Configuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  initialValue: config.apiKey,
                  decoration: const InputDecoration(
                    labelText: 'API Key',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => config.setApiKey(value),
                ),
              ),
              SwitchListTile(
                title: const Text('Proxy'),
                value: config.useProxy,
                onChanged: (value) => config.setUseProxy(value),
              ),
              ListTile(
                title: const Text('Language 1'),
                trailing: DropdownButton<String>(
                  value: config.language1,
                  items: ['Chinese', 'English', 'French'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) config.setLanguage1(newValue);
                  },
                ),
              ),
              ListTile(
                title: const Text('Language 2'),
                trailing: DropdownButton<String>(
                  value: config.language2,
                  items: ['Chinese', 'English', 'French'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) config.setLanguage2(newValue);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
