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
                    autofocus: true,
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
                  )
                ],
              ),
            ),
          ]),
        );
      }),
    );
  }
}
