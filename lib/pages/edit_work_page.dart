import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core.dart';
import '../data.dart';
import '../comp.dart';

class EditWorkPage extends StatefulWidget {
  final String workId;
  final String shiftId;

  const EditWorkPage({required this.shiftId, required this.workId, super.key});

  @override
  State<EditWorkPage> createState() => _EditWorkPageState();
}

class _EditWorkPageState extends State<EditWorkPage> {
  final formKey = GlobalKey<FormState>();
  final startDateTimeFormFieldKey = GlobalKey<FormFieldState<DateTime>>();
  final endDateTimeFormFieldKey = GlobalKey<FormFieldState<DateTime>>();
  final sliderFormFieldKey = GlobalKey<FormFieldState<double>>();
  final numFormFieldKey = GlobalKey<FormFieldState<String>>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child:
          Consumer<DataController>(builder: (context, dataController, child) {
        Work work = dataController.getWork(widget.workId);
        Shift shift = dataController.getShift(widget.shiftId);
        return Scaffold(
          appBar: AppBar(actions: [
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  dataController.saveTempWork();
                  if (!dataController
                      .getShift(widget.shiftId)
                      .workIds
                      .contains(widget.workId)) {
                    dataController.addWork(widget.shiftId, widget.workId);
                  }
                  dataController.notify().flush();
                  Navigator.of(context).pop(widget.workId);
                }
              },
            ),
          ]),
          body: ListView(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  StringFormField(
                    initialText: work.name,
                    hintText: 'Name',
                    onSaved: (value) {
                      if (value == null) {
                        return;
                      }
                      work.name = value;
                    },
                  ),
                  StringFormField(
                    initialText: work.description,
                    hintText: 'Description',
                    onSaved: (value) {
                      if (value == null) {
                        return;
                      }
                      work.description = value;
                    },
                  ),
                ],
              ),
            ),
            const ContentDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  DateTimeFormField(
                      key: startDateTimeFormFieldKey,
                      initialDateTime: work.startDateTime,
                      label: 'Start At',
                      onChanged: (beforeDateTime, afterDateTime) {
                        if (endDateTimeFormFieldKey.currentState == null) {
                          return;
                        }
                        Duration? duration = changeEndDateTimeFormFieldState(
                            endDateTimeFormFieldKey.currentState!,
                            beforeDateTime,
                            afterDateTime);
                        if (numFormFieldKey.currentState == null ||
                            duration == null) {
                          return;
                        }
                        changeNumFormFieldState(
                            numFormFieldKey.currentState!, duration);
                      },
                      onSaved: (dateTime) {
                        if (dateTime == null) {
                          return;
                        }
                        work.startDateTime = dateTime;
                      }),
                  DateTimeFormField(
                    key: endDateTimeFormFieldKey,
                    initialDateTime: work.endDateTime,
                    label: 'End At',
                    onChanged: (beforeDateTime, afterDateTime) {
                      if (startDateTimeFormFieldKey.currentState == null) {
                        return;
                      }
                      Duration? duration = changeStartDateTimeFormFieldState(
                          startDateTimeFormFieldKey.currentState!,
                          beforeDateTime,
                          afterDateTime);
                      if (numFormFieldKey.currentState == null ||
                          duration == null) {
                        return;
                      }
                      changeNumFormFieldState(
                          numFormFieldKey.currentState!, duration);
                    },
                    onSaved: (dateTime) {
                      if (dateTime == null) {
                        return;
                      }
                      work.endDateTime = dateTime;
                    },
                  ),
                ],
              ),
            ),
            const ContentDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  IntSliderFormField(
                    formFieldKey: sliderFormFieldKey,
                    context: context,
                    initialInt: work.numberOfMembersNeeded,
                    max: dataController
                        .getShift(widget.shiftId)
                        .memberIds
                        .length,
                    label: 'Required Members',
                    onSaved: (newValue) {
                      if (newValue == null) {
                        return;
                      }
                      work.numberOfMembersNeeded = newValue.toInt();
                    },
                  ),
                  NumFormField(
                    formFieldKey: numFormFieldKey,
                    initialNum: work.load,
                    min: 0,
                    max: 10000,
                    label: 'Relative Difficulty',
                    onSaved: (value) {
                      work.load = value.toDouble();
                    },
                  ),
                  SwitchFormField(
                    initialBool: work.allowOverlap,
                    label: 'Allow Overlap',
                    onSaved: (newValue) {
                      if (newValue != null) {
                        work.allowOverlap = newValue;
                      }
                    },
                  ),
                ],
              ),
            ),
            const ContentDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DaySelectionFormField(
                    initialValue: work.repeatOn,
                    onSaved: (newValue) {
                      if (newValue != null) {
                        work.repeatOn = newValue;
                      }
                    },
                  ),
                  DateTimeFormField(
                    initialDateTime: work.endRepeatOn,
                    label: 'Repeat Until',
                    onSaved: (newValue) {
                      if (newValue != null) {
                        work.endRepeatOn = newValue;
                      }
                    },
                  ),
                ],
              ),
            ),
            const ContentDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FormField<List<String>>(
                        onSaved: (newValue) {
                          if (newValue == null) {
                            return;
                          }
                          work.fixedMemberIds = newValue;
                        },
                        initialValue: work.fixedMemberIds,
                        builder: (state) {
                          return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Fixed Members',
                                        style: Theme.of(state.context)
                                            .textTheme
                                            .labelLarge),
                                    GestureDetector(
                                      onTap: () {
                                        Iterable<Member> members = shift
                                            .memberIds
                                            .map((memberId) => dataController
                                                .getMember(memberId));
                                        Future<Set<dynamic>?> selectedIds =
                                            showDialog<Set<dynamic>>(
                                                context: context,
                                                builder: (context) =>
                                                    SelectDialog(
                                                        ids: shift.memberIds,
                                                        titles: members
                                                            .map((e) => e.name),
                                                        subtitles: members.map(
                                                            (e) => e
                                                                .description)));
                                        selectedIds.then((value) {
                                          if (value == null) {
                                            return;
                                          }
                                          state.didChange(value
                                              .map((e) => e as String)
                                              .toList());
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: Text(
                                            state.value?.isNotEmpty == true
                                                ? state.value!
                                                    .map((memberId) =>
                                                        dataController
                                                            .getMember(memberId)
                                                            .name)
                                                    .join(', ')
                                                : 'No fixed member'),
                                      ),
                                    )
                                  ]));
                        }),
                    LeniencyFormField(
                      label: 'Fixed Member Leniency',
                      initialValue: work.fixedMemberLeniency,
                      allowInherit: true,
                      onSaved: (newValue) {
                        if (newValue == null) {
                          return;
                        }
                        work.fixedMemberLeniency = newValue;
                      },
                    ),
                    FormField<List<String>>(
                        onSaved: (newValue) {
                          if (newValue == null) {
                            return;
                          }
                          work.fixedGroupIds = newValue;
                        },
                        initialValue: work.fixedGroupIds,
                        builder: (state) {
                          return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Fixed Groups',
                                        style: Theme.of(state.context)
                                            .textTheme
                                            .labelLarge),
                                    GestureDetector(
                                      onTap: () {
                                        Iterable<Group> groups = shift.groupIds
                                            .map((groupId) => dataController
                                                .getGroup(groupId));
                                        Future<Set<dynamic>?> selectedIds =
                                            showDialog<Set<dynamic>>(
                                                context: context,
                                                builder: (context) =>
                                                    SelectDialog(
                                                        ids: shift.groupIds,
                                                        titles: groups
                                                            .map((e) => e.name),
                                                        subtitles: groups.map(
                                                            (e) => e
                                                                .description)));
                                        selectedIds.then((value) {
                                          if (value == null) {
                                            return;
                                          }
                                          state.didChange(value
                                              .map((e) => e as String)
                                              .toList());
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: Text(state.value?.isNotEmpty ==
                                                true
                                            ? state.value!
                                                .map((groupId) => dataController
                                                    .getGroup(groupId)
                                                    .name)
                                                .join(', ')
                                            : 'No fixed group'),
                                      ),
                                    )
                                  ]));
                        }),
                    LeniencyFormField(
                      label: 'Fixed Group Leniency',
                      initialValue: work.fixedGroupLeniency,
                      allowInherit: true,
                      onSaved: (newValue) {
                        if (newValue == null) {
                          return;
                        }
                        work.fixedGroupLeniency = newValue;
                      },
                    ),
                  ]),
            ),
            const Padding(padding: EdgeInsets.only(bottom: 100)),
          ]),
        );
      }),
    );
  }
}
