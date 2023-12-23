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
                  dataController.saveTemp();
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
            Divider(),
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
                        changeEndDateTimeFormFieldState(
                            endDateTimeFormFieldKey.currentState!,
                            beforeDateTime,
                            afterDateTime);
                      },
                      onSaved: (dateTime) {
                        if (dateTime == null) {
                          return;
                        }
                        work.startDateTime = dateTime;
                        dataController.notify();
                      }),
                  DateTimeFormField(
                    initialDateTime: work.endDateTime,
                    label: 'End At',
                    onChanged: (beforeDateTime, afterDateTime) {
                      if (startDateTimeFormFieldKey.currentState == null) {
                        return;
                      }
                      changeStartDateTimeFormFieldState(
                          startDateTimeFormFieldKey.currentState!,
                          beforeDateTime,
                          afterDateTime);
                    },
                    onSaved: (dateTime) {
                      if (dateTime == null) {
                        return;
                      }
                      work.endDateTime = dateTime;
                      dataController.notify();
                    },
                  ),
                ],
              ),
            ),
          ]),
        );
      }),
    );
  }
}
