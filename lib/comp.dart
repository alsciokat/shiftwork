import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core.dart';
import 'data.dart';

class StringFormField extends StatelessWidget {
  final String? initialText;
  final String? hintText;
  final String? label;
  final bool? autofocus;
  final void Function(String text)? onChanged;
  final void Function(String? text)? onSaved;

  const StringFormField({
    super.key,
    this.initialText,
    this.hintText,
    this.label,
    this.autofocus,
    this.onChanged,
    this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    Text? labelWidget;
    if (label != null) {
      labelWidget = Text(label!);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        key: key,
        initialValue: initialText,
        decoration: InputDecoration(label: labelWidget, hintText: hintText),
        autofocus: autofocus ?? false,
        onChanged: (value) {
          if (onChanged != null) {
            onChanged!(value);
          }
        },
        onSaved: onSaved,
      ),
    );
  }
}

DateFormat dateFormat = DateFormat("EEE, MMM d, yyyy");
DateFormat timeFormat = DateFormat('h:mm a');

void changeStartDateTimeFormFieldState(
    FormFieldState<DateTime?> startDateTimeFormFieldState,
    DateTime beforeEndDateTime,
    DateTime afterEndDateTime) {
  if (startDateTimeFormFieldState.value == null) {
    return;
  }
  Duration duration =
      beforeEndDateTime.difference(startDateTimeFormFieldState.value!);
  if (afterEndDateTime.isBefore(startDateTimeFormFieldState.value!)) {
    startDateTimeFormFieldState.didChange(afterEndDateTime.subtract(duration));
  }
}

void changeEndDateTimeFormFieldState(
    FormFieldState<DateTime?> endDateTimeFormFieldState,
    DateTime beforeStartDateTime,
    DateTime afterStartDateTime) {
  if (endDateTimeFormFieldState.value == null) {
    return;
  }
  Duration duration =
      endDateTimeFormFieldState.value!.difference(beforeStartDateTime);
  if (endDateTimeFormFieldState.value!.isBefore(afterStartDateTime)) {
    endDateTimeFormFieldState.didChange(afterStartDateTime.add(duration));
  }
}

class DateTimeFormField extends FormField<DateTime> {
  final DateTime initialDateTime;
  final String? label;
  final void Function(DateTime beforeDateTime, DateTime afterDateTime)?
      onChanged;

  DateTimeFormField({
    super.key,
    required this.initialDateTime,
    this.label,
    this.onChanged,
    super.onSaved,
  }) : super(
          initialValue: initialDateTime.copyWith(
              second: 0, millisecond: 0, microsecond: 0),
          builder: (FormFieldState<DateTime> state) {
            List<Widget> children = [];
            if (label != null) {
              children.add(Text(
                label,
                style: Theme.of(state.context).textTheme.labelLarge,
              ));
            }

            children.add(Row(
              children: [
                InkWell(
                    onTap: () {
                      final Future<DateTime?> date = showDatePicker(
                        context: state.context,
                        initialDate: state.value ?? initialDateTime,
                        firstDate: DateTime(DateTime.now().year - 10),
                        lastDate: DateTime(DateTime.now().year + 10),
                      );

                      date.then((dateTime) {
                        if (dateTime == null) {
                          return;
                        }
                        dateTime = dateTime.copyWith(
                            hour: state.value?.hour,
                            minute: state.value?.minute);
                        if (onChanged != null) {
                          onChanged(state.value ?? initialDateTime, dateTime);
                        }
                        state.didChange(dateTime);
                      });
                    },
                    child: SizedBox(
                      width: 170,
                      child: Padding(
                        padding:
                            const EdgeInsets.only(left: 8, top: 8, bottom: 8),
                        child: Text(
                          dateFormat.format(state.value ?? initialDateTime),
                          style: Theme.of(state.context).textTheme.bodyLarge,
                        ),
                      ),
                    )),
                InkWell(
                    onTap: () {
                      final Future<TimeOfDay?> time = showTimePicker(
                        context: state.context,
                        initialTime: TimeOfDay.fromDateTime(
                            state.value ?? initialDateTime),
                      );
                      time.then((timeOfDay) {
                        if (timeOfDay == null) {
                          return;
                        }
                        DateTime dateTime = state.value?.copyWith(
                              hour: timeOfDay.hour,
                              minute: timeOfDay.minute,
                            ) ??
                            initialDateTime;
                        if (onChanged != null) {
                          onChanged(state.value ?? initialDateTime, dateTime);
                        }
                        state.didChange(dateTime);
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 24.0, right: 8, top: 8, bottom: 8),
                      child: Text(
                          timeFormat.format(state.value ?? initialDateTime),
                          style: Theme.of(state.context).textTheme.bodyLarge),
                    ))
              ],
            ));
            return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children));
          },
        );
}

class IntSliderFormField extends FormField<double> {
  final int? min;
  final int max;
  final String label;
  IntSliderFormField({
    super.key,
    required int initialInt,
    this.min,
    required this.max,
    required this.label,
    super.onSaved,
  }) : super(
            initialValue: initialInt.toDouble(),
            builder: (FormFieldState<double> state) {
              String getLabel(double value) {
                if (value.round() == max) {
                  return 'max';
                }
                return value.toString();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(state.context).textTheme.bodyLarge,
                  ),
                  Slider(
                    value: (state.value ?? initialInt).toDouble(),
                    max: max.toDouble(),
                    divisions: (max <= 0) ? 1 : max,
                    label: getLabel(state.value ?? initialInt.toDouble()),
                    onChanged: (value) {
                      state.didChange(value);
                    },
                  )
                ],
              );
            });
}

class SwitchFormField extends FormField<bool> {
  final bool initialBool;
  final String label;

  SwitchFormField(
      {super.key,
      required this.initialBool,
      required this.label,
      super.onSaved})
      : super(
            initialValue: initialBool,
            builder: (FormFieldState<bool> state) {
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(state.context).textTheme.bodyLarge,
                    ),
                  ),
                  Switch(
                      value: state.value ?? initialBool,
                      onChanged: (value) {
                        state.didChange(value);
                      })
                ],
              );
            });
}

DateFormat vacancyFormat = DateFormat("EE, MM/d");

String getSubtitle(Vacancy vacancy) {
  return '${vacancyFormat.format(vacancy.startDateTime)} - ${vacancyFormat.format(vacancy.endDateTime)}';
}

class NewListItem extends StatelessWidget {
  final String label;
  final void Function() onTap;

  const NewListItem({super.key, required this.onTap, required this.label});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 30),
        leading: const Icon(Icons.add),
        title: Text(label),
      ),
    );
  }
}

// entityId, entityName, entityDescription, entityIcon, parentType, parentId
class ListItem extends StatelessWidget {
  final String entityId, entityName, entityDescription, parentId;
  final Icon? entityIcon;
  final void Function(BuildContext context)? onTap;
  final DataController Function(String parentId, String childId) removeEntity;
  final bool deletable;
  final DataController Function(String childId)? deleteEntity;

  const ListItem({
    super.key,
    required this.entityId,
    required this.entityName,
    required this.entityDescription,
    this.entityIcon,
    required this.parentId,
    this.onTap,
    required this.removeEntity,
    required this.deletable,
    this.deleteEntity,
  });

  @override
  Widget build(BuildContext context) {
    List<MenuItemButton> menuItem = [
      MenuItemButton(
          onPressed: () {
            removeEntity(parentId, entityId).notify().flush();
          },
          child: const Text('Remove'))
    ];
    if (deletable) {
      menuItem.add(MenuItemButton(
          onPressed: () {
            removeEntity(parentId, entityId);
            if (deleteEntity == null) {
              throw ShiftWorkError(
                  'deleteEntity must be present when deletable = true');
            }
            deleteEntity!(entityId).notify().flush();
          },
          child: const Text('Delete')));
    }

    Text? description;
    if (entityDescription == "") {
      description = null;
    } else {
      description = Text(entityDescription);
    }
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 30, right: 15),
      leading: entityIcon ?? const Icon(Icons.person),
      title: Text(entityName),
      subtitle: description,
      trailing: MenuAnchor(
          builder: (context, controller, child) => IconButton(
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open(position: const Offset(-35, 45));
                }
              },
              icon: const Icon(Icons.more_vert)),
          menuChildren: menuItem),
      onTap: () {
        if (onTap == null) {
          return;
        }
        onTap!(context);
      },
    );
  }
}

void informUser(BuildContext context, {String? title, String? content}) {
  Text? titleWidget;
  Text? contentWidget;
  if (title != null) {
    titleWidget = Text(title);
  }
  if (content != null) {
    contentWidget = Text(content);
  }

  showDialog(
      context: context,
      builder: ((context) => AlertDialog(
            title: titleWidget,
            content: contentWidget,
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'))
            ],
          )));
}

// ids, titles, subtitles, newEntity, newEntityText
class SelectDialog extends StatefulWidget {
  final Iterable<String> ids, titles;
  final Iterable<String?> subtitles;
  final bool newEntity;
  final String? newEntityText;

  const SelectDialog(
      {super.key,
      required this.ids,
      required this.titles,
      required this.subtitles,
      required this.newEntity,
      this.newEntityText});

  @override
  State<SelectDialog> createState() => _SelectDialogState();
}

class _SelectDialogState extends State<SelectDialog> {
  late String radioValue;
  late int listLength;
  late int indexShift;

  @override
  void initState() {
    if (widget.newEntity) {
      radioValue = defaultId;
      listLength = widget.ids.length + 1;
      indexShift = 1;
    } else {
      radioValue = widget.ids.first;
      listLength = widget.ids.length;
      indexShift = 0;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select'),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(),
          ListView.builder(
              shrinkWrap: true,
              itemCount: listLength,
              itemBuilder: (context, index) {
                if (index == 0 && widget.newEntity) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        radioValue = defaultId;
                      });
                    },
                    child: ListTile(
                        contentPadding: const EdgeInsets.all(0),
                        horizontalTitleGap: 0,
                        leading: Radio<String>(
                          value: defaultId,
                          groupValue: radioValue,
                          onChanged: (value) {
                            setState(() {
                              radioValue = value ?? defaultId;
                            });
                          },
                        ),
                        title: Text(widget.newEntityText ?? 'Add New Entity')),
                  );
                }
                return InkWell(
                  onTap: () {
                    setState(() {
                      radioValue = widget.ids.elementAt(index - indexShift);
                    });
                  },
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(0),
                    horizontalTitleGap: 0,
                    leading: Radio<String>(
                      value: widget.ids.elementAt(index - indexShift),
                      groupValue: radioValue,
                      onChanged: (value) {
                        setState(() {
                          radioValue = value ?? defaultId;
                        });
                      },
                    ),
                    title: Text(widget.titles.elementAt(index - indexShift)),
                    subtitle: widget.subtitles.map((e) {
                      if (e == null) {
                        return null;
                      }
                      return Text(e);
                    }).elementAt(index - indexShift),
                  ),
                );
              }),
          const Divider(),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.of(context).pop(null);
            },
            child: const Text('Cancel')),
        TextButton(
            onPressed: () {
              Navigator.of(context).pop(radioValue);
            },
            child: const Text('Select'))
      ],
    );
  }
}

class ContentDivider extends StatelessWidget {
  const ContentDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 30,
      indent: 10,
      endIndent: 10,
    );
  }
}
