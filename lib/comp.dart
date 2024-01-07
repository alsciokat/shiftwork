import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core.dart';
import 'data.dart';

class StringFormField extends StatelessWidget {
  final GlobalKey<FormFieldState<String>>? formKey;
  final String? initialText, hintText, label;
  final bool? autofocus;
  final void Function(String text)? onChanged;
  final void Function(String? text) onSaved;
  const StringFormField(
      {super.key,
      this.formKey,
      this.initialText,
      this.hintText,
      this.label,
      this.autofocus,
      this.onChanged,
      required this.onSaved});

  @override
  Widget build(BuildContext context) {
    // FocusNode focusNode = FocusNode();
    TextEditingController controller = TextEditingController(text: initialText);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        key: formKey,
        controller: controller,
        // focusNode: focusNode,
        decoration: InputDecoration(
          label: (label == null) ? null : Text(label!),
          hintText: hintText,
        ),
        style: Theme.of(context).textTheme.titleMedium,
        autofocus: autofocus ?? false,
        onChanged: onChanged,
        onSaved: (newValue) {
          onSaved(newValue);
        },
      ),
    );
  }
}

class LeniencyFormField extends StatelessWidget {
  final String label;
  final Leniency initialValue;
  final void Function(Leniency? value) onChanged;
  const LeniencyFormField(
      {super.key,
      required this.label,
      required this.initialValue,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          Row(
            children: [
              Radio<Leniency>(
                  value: Leniency.force,
                  groupValue: initialValue,
                  onChanged: onChanged),
              const Text('Strict'),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 30)),
              Radio<Leniency>(
                  value: Leniency.recommend,
                  groupValue: initialValue,
                  onChanged: onChanged),
              const Text('Lenient'),
            ],
          )
        ],
      ),
    );
  }
}

// class SuffixIcon extends StatelessWidget {
//   final TextEditingController controller;
//   final FocusNode focusNode;

//   const SuffixIcon(
//       {super.key, required this.controller, required this.focusNode});

//   @override
//   Widget build(BuildContext context) {
//     if (controller.text.isEmpty) {
//       return const SizedBox(
//         width: 0,
//       );
//     }
//     return IconButton(
//         onPressed: () {
//           controller.clear();
//           focusNode.requestFocus();
//         },
//         icon: const Icon(Icons.clear));
//   }
// }

DateFormat dateFormat = DateFormat("EEE, MMM d, yyyy");
DateFormat timeFormat = DateFormat('h:mm a');

Duration? changeStartDateTimeFormFieldState(
    FormFieldState<DateTime?> startDateTimeFormFieldState,
    DateTime beforeEndDateTime,
    DateTime afterEndDateTime) {
  if (startDateTimeFormFieldState.value == null) {
    return null;
  }
  Duration duration =
      beforeEndDateTime.difference(startDateTimeFormFieldState.value!);
  if (afterEndDateTime.isBefore(startDateTimeFormFieldState.value!)) {
    startDateTimeFormFieldState.didChange(afterEndDateTime.subtract(duration));
    return duration;
  }
  return afterEndDateTime.difference(startDateTimeFormFieldState.value!);
}

Duration? changeEndDateTimeFormFieldState(
    FormFieldState<DateTime?> endDateTimeFormFieldState,
    DateTime beforeStartDateTime,
    DateTime afterStartDateTime) {
  if (endDateTimeFormFieldState.value == null) {
    return null;
  }
  Duration duration =
      endDateTimeFormFieldState.value!.difference(beforeStartDateTime);
  if (endDateTimeFormFieldState.value!.isBefore(afterStartDateTime)) {
    endDateTimeFormFieldState.didChange(afterStartDateTime.add(duration));
    return duration;
  }
  return endDateTimeFormFieldState.value!.difference(afterStartDateTime);
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
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
                    child: Padding(
                      padding:
                          const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                      child: Text(
                        dateFormat.format(state.value ?? initialDateTime),
                        style: Theme.of(state.context).textTheme.bodyLarge,
                      ),
                    )),
                GestureDetector(
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
                      padding:
                          const EdgeInsets.only(left: 8, top: 8, bottom: 8),
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

void changeNumFormFieldState(
    FormFieldState<String> numFormFieldState, Duration duration) {
  numFormFieldState.didChange(
      (duration.inHours + ((duration.inMinutes % 60) / 60)).toStringAsFixed(1));
}

class NumFormField extends StatelessWidget {
  final GlobalKey<FormFieldState<String>> formFieldKey;
  final num initialNum;
  final int min;
  final int max;
  final String label;
  final bool intOnly;
  final void Function(num value)? onSaved;

  const NumFormField(
      {super.key,
      required this.formFieldKey,
      required this.initialNum,
      this.min = 1,
      required this.max,
      required this.label,
      this.intOnly = false,
      this.onSaved});

  @override
  Widget build(BuildContext context) {
    TextEditingController controller =
        TextEditingController(text: initialNum.toStringAsFixed(1));
    TextInputType textInputType;
    if (intOnly) {
      textInputType = TextInputType.number;
    } else {
      textInputType = const TextInputType.numberWithOptions(decimal: true);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              )),
          SizedBox(
            width: 90,
            height: 50,
            child: TextFormField(
              key: formFieldKey,
              controller: controller,
              keyboardType: textInputType,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              strutStyle: const StrutStyle(height: 1.1, forceStrutHeight: true),
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.top,
              showCursor: false,
              cursorWidth: 0,
              selectionControls: EmptyTextSelectionControls(),
              onTap: () {
                controller.selection = TextSelection(
                    baseOffset: 0, extentOffset: controller.text.length);
              },
              onChanged: (value) {
                if (value == '') {
                  return;
                }
                num? numValue;
                if (intOnly) {
                  numValue = int.tryParse(value);
                } else {
                  numValue = double.tryParse(value);
                }
                if (numValue == null) {
                  informUser(context, title: 'Invalid Input');
                  controller.text = initialNum.toString();
                  return;
                }
                if (numValue < min || numValue > max) {
                  if (numValue < min) {
                    informUser(context, title: 'Too Small Number');
                  } else {
                    informUser(context, title: 'Too Large Number');
                  }
                  controller.text = initialNum.toString();
                  return;
                }
              },
              validator: (value) {
                if (value == null) {
                  controller.text = initialNum.toString();
                }
                return null;
              },
              onSaved: (newValue) {
                if (onSaved == null) {
                  return;
                }
                num newNumValue;
                if (intOnly) {
                  newNumValue = int.parse(newValue!);
                } else {
                  newNumValue = double.parse(newValue!);
                }
                onSaved!(newNumValue);
              },
            ),
          )
        ],
      ),
    );
  }
}

void changeIntSliderFormFieldState(
    FormFieldState<double> intSliderFormFieldState, int delta) {
  if (intSliderFormFieldState.value == null) {
    return;
  }
  if (delta < 0 && intSliderFormFieldState.value! + delta >= 0) {
    intSliderFormFieldState.didChange(intSliderFormFieldState.value! + delta);
  }
}

class IntSliderFormField extends StatelessWidget {
  final GlobalKey<FormFieldState<double>> formFieldKey;
  final BuildContext context;
  final int initialInt;
  final int min;
  final int max;
  final String label;
  final void Function(double? value) onSaved;
  const IntSliderFormField({
    super.key,
    required this.formFieldKey,
    required this.context,
    required this.initialInt,
    this.min = 0,
    required this.max,
    required this.label,
    required this.onSaved,
  });

  String getLabel(double value) {
    if (value.round() == max) {
      return 'max';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (min > max) {
      throw ShiftWorkError('Minimum is larger than maximum');
    }

    int division = (max - min);
    if (max - min == 0) {
      division = 1;
    }
    bool disabled = false;
    double initialValue = initialInt.toDouble();
    if (initialInt < min || max < initialInt) {
      initialValue = min.toDouble();
      disabled = true;
    }

    return _IntSliderFormField(
      key: formFieldKey,
      context: context,
      initialValue: initialValue,
      min: min,
      max: max,
      division: division,
      label: label,
      disabled: disabled,
      getLabel: getLabel,
      onSaved: onSaved,
    );
  }
}

class _IntSliderFormField extends FormField<double> {
  _IntSliderFormField({
    super.key,
    required BuildContext context,
    required double initialValue,
    required int min,
    required int max,
    required int division,
    required String label,
    required bool disabled,
    required String Function(double value) getLabel,
    super.onSaved,
  }) : super(
            initialValue: initialValue,
            builder: (FormFieldState<double> state) {
              void Function(double value)? onChanged;

              if (max > 0) {
                onChanged = (value) {
                  state.didChange(value);
                };
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(state.context).textTheme.labelLarge,
                  ),
                  Slider(
                    value: state.value ?? initialValue,
                    max: max.toDouble(),
                    divisions: division,
                    label: getLabel(state.value ?? initialValue),
                    onChanged: onChanged,
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

  const SelectDialog({
    super.key,
    required this.ids,
    required this.titles,
    required this.subtitles,
  });

  @override
  State<SelectDialog> createState() => _SelectDialogState();
}

class _SelectDialogState extends State<SelectDialog> {
  Set<String> selectedIds = {};

  @override
  Widget build(BuildContext context) {
    // double contentHeight =
    //     (59.0 * widget.ids.length < 500) ? 59.0 * widget.ids.length : 500.0;
    return AlertDialog(
      title: const Text('Select'),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.ids.length,
                itemBuilder: (context, index) {
                  String id = widget.ids.elementAt(index);
                  return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selectedIds.contains(id)) {
                            selectedIds.remove(id);
                          } else {
                            selectedIds.add(id);
                          }
                        });
                      },
                      child: CheckboxListTile(
                          contentPadding: const EdgeInsets.only(left: 10),
                          value: selectedIds.contains(id),
                          onChanged: (value) {
                            setState(() {
                              if (selectedIds.contains(id)) {
                                selectedIds.remove(id);
                              } else {
                                selectedIds.add(id);
                              }
                            });
                          },
                          title: Text(widget.titles.elementAt(index)),
                          subtitle: widget.subtitles
                              .map((e) => (e == null) ? null : Text(e))
                              .elementAt(index)));
                }),
          ),
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
              Navigator.of(context).pop(selectedIds);
            },
            child: const Text('Confirm'))
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
