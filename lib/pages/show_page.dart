import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Text(
                '${dateTimeFormat.format(interval.start)} - ${dateTimeFormat.format(interval.end)}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            const Divider(
              height: 20,
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
    List<Work> works = dataController
        .getShift(shiftId)
        .workIds
        .map((id) => dataController.getWork(id))
        .toList();
    works.sort(
        (a, b) => a.dateTimeInterval.start.compareTo(b.dateTimeInterval.start));

    return Scaffold(
        appBar: AppBar(),
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
