import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'data.dart';
import 'pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(ChangeNotifierProvider(
    create: (context) => DataController(),
    child: const ShiftWork(),
  ));
}

class ShiftWork extends StatelessWidget {
  const ShiftWork({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShiftWork',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color.fromARGB(255, 78, 137, 247),
      ),
      home: const HomePage(),
    );
  }
}
