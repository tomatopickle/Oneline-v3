import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../packages/settings_ui/settings_ui.dart';
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
    'appearance': {'darkMode': true, 'theme': 'flutterDash'}
  };
  Map theme = {};
  @override
  void initState() {
    print(FlexThemeData.dark(scheme: FlexScheme.flutterDash).primaryColor);
    db
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get()
        .then((event) {
      setState(() {
        Map data = event.data()?['settings'] ?? {};
        settings.forEach((key, value) {
          if (data[key] == null) {
            data[key] = settings[key];
          }
        });
        settings = data;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List themes = [];
    for (var t in FlexScheme.values) {
      // print(FlexThemeData.dark(scheme: theme).primaryColor);
      Map d = {
        'name': t.toString().replaceAll('FlexScheme.', ''),
        'color': FlexThemeData.dark(scheme: t).primaryColor
      };
      themes.add(d);
      if (d['name'] == settings['appearance']['theme']) {
        theme = d;
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text('Appearance'),
            tiles: [
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
              SettingsTile.navigation(
                leading: Icon(Icons.format_paint_rounded),
                title: Text('Theme'),
                value: Text(settings['appearance']['theme']),
                trailing: DropdownButton(
                  value: theme,
                  items: [
                    for (var t in themes)
                      DropdownMenuItem(
                        child: Text(t['name']),
                        value: t,
                        onTap: (() {
                          setState(() {
                            settings['appearance']['theme'] = t['name'];
                            print(settings);
                            db
                                .collection('users')
                                .doc(widget.user?.uid)
                                .update({'settings': settings});
                          });
                        }),
                      )
                  ],
                  onChanged: (e) {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
