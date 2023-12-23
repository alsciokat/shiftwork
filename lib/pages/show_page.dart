import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_view/calendar_view.dart';

import '../core.dart';
import '../data.dart';

class ShowPage extends StatelessWidget {
  final String shiftId;
  const ShowPage(this.shiftId, {super.key});

  @override
  Widget build(BuildContext context) {
    return CalendarControllerProvider(
      controller: EventController(),
      child: CalendarView(shiftId),
    );
  }
}

class CalendarView extends StatelessWidget {
  final String shiftId;
  const CalendarView(this.shiftId, {super.key});

  @override
  Widget build(BuildContext context) {
    final shift =
        Provider.of<DataController>(context, listen: false).getShift(shiftId);
    List<Work> works = [];
    for (final workId in shift.workIds) {
      works.add(
          Provider.of<DataController>(context, listen: false).getWork(workId));
    }

    for (final work in works) {
      List<Member> members = [];
      for (final memberId in work.memberIds) {
        members.add(Provider.of<DataController>(context, listen: false)
            .getMember(memberId));
      }
      Iterable<String> memberNames = members.map((member) => member.name);
      final workEvent = CalendarEventData(
          date: work.startDateTime,
          endDate: work.endDateTime,
          startTime: work.startDateTime,
          endTime: work.endDateTime,
          title: work.name,
          event: work.name,
          description: memberNames.join(', '));
      CalendarControllerProvider.of(context).controller.add(workEvent);
    }
    return const Scaffold(
      body: DayView(),
    );
  }
}
