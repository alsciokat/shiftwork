import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    AppLocalizations l10n = AppLocalizations.of(context)!;
    return Form(
      key: formKey,
      child:
          Consumer<DataController>(builder: (context, dataController, child) {
        Work work = dataController.getWork(widget.workId);
        Shift shift = dataController.getShift(widget.shiftId);
        return Scaffold(
          appBar: AppBar(actions: [
            TextButton(
              child: Text(l10n.save),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  if (widget.workId ==
                      dataController.data.workData.tempObject.id) {
                    dataController.saveTempWork();
                  }
                  if (!dataController
                      .getShift(widget.shiftId)
                      .workIds
                      .contains(widget.workId)) {
                    dataController.addWork(widget.shiftId, widget.workId);
                  }
                  if (widget.shiftId ==
                      dataController.data.shiftData.tempObject.id) {
                    dataController.saveTempShift();
                  }
                  dataController.notify().flush();
                  Navigator.of(context).pop(true);
                }
              },
            ),
          ]),
          body: ListView(cacheExtent: 800, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  StringFormField(
                    initialText: work.name,
                    hintText: l10n.name,
                    onSaved: (value) {
                      if (value == null) {
                        return;
                      }
                      work.name = value;
                    },
                  ),
                  StringFormField(
                    initialText: work.description,
                    hintText: l10n.description,
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
                      label: l10n.startAt,
                      locale: Localizations.localeOf(context),
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
                    label: l10n.endAt,
                    locale: Localizations.localeOf(context),
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
                    label: l10n.requiredMembers,
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
                    label: l10n.relativeDifficulty,
                    onSaved: (value) {
                      work.load = value.toDouble();
                    },
                  ),
                  SwitchFormField(
                    initialBool: work.allowOverlap,
                    label: l10n.allowOverlap,
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
                    label: l10n.repeatOn,
                    locale: Localizations.localeOf(context),
                    onSaved: (newValue) {
                      if (newValue != null) {
                        work.repeatOn = newValue;
                      }
                    },
                  ),
                  DateTimeFormField(
                    initialDateTime: work.endRepeatOn,
                    label: l10n.repeatUntil,
                    locale: Localizations.localeOf(context),
                    onSaved: (newValue) {
                      if (newValue != null) {
                        work.endRepeatOn = newValue;
                      }
                    },
                  ),
                  SwitchFormField(
                    initialBool: work.repeatWithSameMembers,
                    label: l10n.repeatWithSameMembers,
                    onSaved: (newValue) {
                      if (newValue != null) {
                        work.repeatWithSameMembers = newValue;
                      }
                    },
                  )
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
                                  const EdgeInsets.symmetric(vertical: 12.0),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n.fixedMembers,
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
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          state.value?.isNotEmpty == true
                                              ? state.value!
                                                  .map((memberId) =>
                                                      dataController
                                                          .getMember(memberId)
                                                          .name)
                                                  .join(', ')
                                              : l10n.noFixedMembers,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                        ),
                                      ),
                                    )
                                  ]));
                        }),
                    LeniencyFormField(
                      label: l10n.fixedMemberLeniency,
                      context: context,
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
                                  const EdgeInsets.symmetric(vertical: 12.0),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n.fixedGroups,
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
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          state.value?.isNotEmpty == true
                                              ? state.value!
                                                  .map((groupId) =>
                                                      dataController
                                                          .getGroup(groupId)
                                                          .name)
                                                  .join(', ')
                                              : l10n.noFixedGroups,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                        ),
                                      ),
                                    )
                                  ]));
                        }),
                    LeniencyFormField(
                      label: l10n.fixedGroupLeniency,
                      context: context,
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
