import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsPage extends StatefulWidget {
  final String exportDirectoryDefault = '/storage/emulated/0/Documents';
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String exportDirectory;
  late SharedPreferences preferences;

  @override
  void initState() {
    exportDirectory = widget.exportDirectoryDefault;
    SharedPreferences.getInstance().then((value) {
      setState(() {
        preferences = value;
        exportDirectory =
            preferences.getString('exportDirectory') ?? exportDirectory;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export To',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    GestureDetector(
                      onTap: () async {
                        PermissionStatus status =
                            await Permission.storage.status;
                        if (!status.isGranted) {
                          await Permission.storage.request();
                        }
                        if (status != PermissionStatus.granted) {
                          return;
                        }
                        FilePicker.platform
                            .getDirectoryPath(dialogTitle: 'Export To')
                            .then((value) {
                          if (value == null) {
                            return;
                          }
                          if (value == '/') {
                            value = widget.exportDirectoryDefault;
                          }
                          setState(() {
                            exportDirectory = value!;
                            preferences.setString('exportDirectory', value);
                          });
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(exportDirectory),
                      ),
                    )
                  ]),
            )
          ])),
    );
  }
}
