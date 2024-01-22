import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../core.dart';
import '../data.dart';
import '../comp.dart';

class WorkCard extends StatelessWidget {
  final String name;
  final String description;
  final DateTimeInterval interval;
  final String members;

  const WorkCard(
      {super.key,
      required this.name,
      required this.description,
      required this.interval,
      required this.members});

  @override
  Widget build(BuildContext context) {
    DateFormat dateTimeFormat =
        DateFormat.MMMEd(Localizations.localeOf(context).languageCode).add_jm();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            description.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : const Padding(padding: EdgeInsets.zero),
            Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Text(
                '${dateTimeFormat.format(interval.start)} - ${dateTimeFormat.format(interval.end)}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            const Divider(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Text(members),
            )
          ]),
        ),
      ),
    );
  }
}

class ShowPage extends StatefulWidget {
  final String shiftId;
  final bool generate;
  const ShowPage(this.shiftId, {super.key, this.generate = false});

  @override
  State<ShowPage> createState() => _ShowPageState();
}

class _ShowPageState extends State<ShowPage> {
  late bool loading;

  @override
  void initState() {
    loading = widget.generate;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    DataController dataController =
        Provider.of<DataController>(context, listen: false);
    Shift shift = dataController.getShift(widget.shiftId);

    if (loading) {
      () async {
        try {
          dataController.generateShift(widget.shiftId,
              l10n: AppLocalizations.of(context)!);
          shift.created = true;
          dataController.flush();
          return null;
        } catch (error) {
          return error;
        }
      }()
          .then((error) {
        if (error == null) {
          setState(() {
            loading = false;
          });
        } else {
          Navigator.of(context).pop(error);
        }
      });
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    AppLocalizations l10n = AppLocalizations.of(context)!;
    List<Work> works = [];
    for (Work work in shift.workIds.map((id) => dataController.getWork(id))) {
      works.add(work);
      for (Work repeatedWork in work.repeatedWorks) {
        if (work.repeatWithSameMembers) {
          repeatedWork.memberIds = work.memberIds;
        }
        works.add(repeatedWork);
      }
    }
    works.sort(
        (a, b) => a.dateTimeInterval.start.compareTo(b.dateTimeInterval.start));

    return Scaffold(
        appBar: AppBar(
          actions: [
            TextButton(
                onPressed: () async {
                  PermissionStatus status = await Permission.storage.status;
                  if (!status.isGranted) {
                    status = await Permission.storage.request();
                  }
                  if (status != PermissionStatus.granted) {
                    return;
                  }
                  String csvData =
                      '${l10n.name}\t${l10n.description}\t${l10n.startAt}\t${l10n.endAt}\t${l10n.members}\n';
                  for (Work work in works) {
                    csvData +=
                        '${work.name}\t${work.description}\t${work.dateTimeInterval.start.toString()}\t${work.dateTimeInterval.end.toString()}';
                    for (String memberId in work.memberIds) {
                      csvData += '\t${dataController.getMember(memberId).name}';
                    }
                    csvData += '\n';
                  }
                  dataController.ioController
                      .writeToExternalStorage('${shift.title}.tsv', csvData)
                      .then((success) {
                    if (success) {
                      SharedPreferences.getInstance().then((preferences) {
                        String exportDirectory =
                            preferences.getString('exportDirectory') ??
                                '/storage/emulated/0/Documents';
                        if (exportDirectory.startsWith('/storage/emulated/0')) {
                          exportDirectory = exportDirectory.replaceFirst(
                              '/storage/emulated/0',
                              AppLocalizations.of(context)!.internalStorage);
                        }
                        informUser(context,
                            title: AppLocalizations.of(context)!.saved,
                            content:
                                '${AppLocalizations.of(context)!.exportedTo}: $exportDirectory/${shift.title}.tsv');
                      });
                    } else {
                      informUser(context,
                          title: AppLocalizations.of(context)!.exportFailed,
                          content:
                              AppLocalizations.of(context)!.contactDeveloper);
                    }
                  });
                },
                child: Text(AppLocalizations.of(context)!.export))
          ],
        ),
        body: ListView.builder(
          itemCount: works.length,
          itemBuilder: (context, index) {
            String memberString = works[index]
                .memberIds
                .map((id) => dataController.getMember(id).name)
                .join(', ');
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: WorkCard(
                name: works[index].name,
                description: works[index].description,
                interval: works[index].dateTimeInterval,
                members: memberString,
              ),
            );
          },
        ));
  }
}
