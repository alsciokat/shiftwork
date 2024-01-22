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
    return Form(
      key: formKey,
      child:
          Consumer<DataController>(builder: (context, dataController, child) {
        Work work = dataController.getWork(widget.workId);
        Shift shift = dataController.getShift(widget.shiftId);
        return Scaffold(
          appBar: AppBar(actions: [
            TextButton(
              child: Text(AppLocalizations.of(context)!.save),
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
                    hintText: AppLocalizations.of(context)!.name,
                    onSaved: (value) {
                      if (value == null) {
                        return;
                      }
                      work.name = value;
                    },
                  ),
                  StringFormField(
                    initialText: work.description,
                    hintText: AppLocalizations.of(context)!.description,
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
                      label: AppLocalizations.of(context)!.startAt,
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
                    label: AppLocalizations.of(context)!.endAt,
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
                    label: AppLocalizations.of(context)!.requiredMembers,
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
                    label: AppLocalizations.of(context)!.relativeDifficulty,
                    onSaved: (value) {
                      work.load = value.toDouble();
                    },
                  ),
                  SwitchFormField(
                    initialBool: work.allowOverlap,
                    label: AppLocalizations.of(context)!.allowOverlap,
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
                    label: AppLocalizations.of(context)!.repeatOn,
                    locale: Localizations.localeOf(context),
                    onSaved: (newValue) {
                      if (newValue != null) {
                        work.repeatOn = newValue;
                      }
                    },
                  ),
                  DateTimeFormField(
                    initialDateTime: work.endRepeatOn,
                    label: AppLocalizations.of(context)!.repeatUntil,
                    locale: Localizations.localeOf(context),
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
                                  const EdgeInsets.symmetric(vertical: 12.0),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        AppLocalizations.of(context)!
                                            .fixedMembers,
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
                                              : AppLocalizations.of(context)!
                                                  .noFixedMembers,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                        ),
                                      ),
                                    )
                                  ]));
                        }),
                    LeniencyFormField(
                      label: AppLocalizations.of(context)!.fixedMemberLeniency,
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
                                    Text(
                                        AppLocalizations.of(context)!
                                            .fixedGroups,
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
                                              : AppLocalizations.of(context)!
                                                  .noFixedGroups,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                        ),
                                      ),
                                    )
                                  ]));
                        }),
                    LeniencyFormField(
                      label: AppLocalizations.of(context)!.fixedGroupLeniency,
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
