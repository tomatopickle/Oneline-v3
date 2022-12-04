import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vertical_tabs_flutter/vertical_tabs.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key, required this.user});
  final User? user;
  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  FirebaseFirestore db = FirebaseFirestore.instance;
  Map settings = {
    'appearance': {'darkMode': true}
  };
  @override
  void initState() {
    db
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get()
        .then((event) {
      print(event.data());
      setState(() {
        settings = event.data()?['settings'];
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text('Appearance'),
            tiles: <SettingsTile>[
              SettingsTile.switchTile(
                onToggle: (value) {
                  setState(() {
                    settings['appearance']['darkMode'] = value;
                    print(settings);
                    db
                        .collection('users')
                        .doc(widget.user?.uid)
                        .update({'settings': settings});
                  });
                },
                initialValue: settings['appearance']['darkMode'],
                leading: Icon(Icons.brightness_6),
                title: Text('Dark Mode'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
