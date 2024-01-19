import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(children: [
          Center(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                          color: Theme.of(context).dividerColor,
                          offset: const Offset(3, 3),
                          blurRadius: 5),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: const Image(
                    image: AssetImage('assets/icon.png'),
                    width: 150,
                    height: 150,
                  ),
                ),
              ),
              Text(
                'ShiftWork',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              Text('${AppLocalizations.of(context)!.version} 1.0.0'),
            ]),
          ),
          const Padding(padding: EdgeInsets.only(top: 30)),
          Expanded(
              child: Column(
            children: [
              Text(AppLocalizations.of(context)!.developedBy),
              const Padding(padding: EdgeInsets.only(bottom: 12)),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                          const ClipboardData(text: 'alsciokat@gmail.com'))
                      .then(
                    (_) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(AppLocalizations.of(context)!
                              .copiedToClipboard)));
                    },
                  );
                },
                child: Text(
                  'alsciokat@gmail.com',
                  style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      decoration: TextDecoration.underline),
                ),
              )
            ],
          )),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Text(
              'Powered by Flutter',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ]),
      ),
    );
  }
}
