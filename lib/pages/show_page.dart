import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shift_work/comp.dart';

import '../core.dart';
import '../data.dart';

DateFormat dateTimeFormat = DateFormat('EEE, MMM d, h:mm a');

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

class ShowPage extends StatelessWidget {
  final String shiftId;
  const ShowPage(this.shiftId, {super.key});

  @override
  Widget build(BuildContext context) {
    DataController dataController =
        Provider.of<DataController>(context, listen: false);
    Shift shift = dataController.getShift(shiftId);
    List<Work> works =
        shift.workIds.map((id) => dataController.getWork(id)).toList();
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
                      'Name\tDescription\tStart At\tEnd At\tMembers\n';
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
                      informUser(context,
                          title: 'Saved',
                          content:
                              'Saved to: Internal Storage/Documents/${shift.title}.tsv');
                    } else {
                      informUser(context,
                          title: 'Export Failed',
                          content: 'Please contact developer for it.');
                    }
                  });
                },
                child: const Text('Export'))
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
