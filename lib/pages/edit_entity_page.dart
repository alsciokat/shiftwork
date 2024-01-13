import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core.dart';
import '../data.dart';
import '../comp.dart';

class EditEntityPage extends StatefulWidget {
  final String memberId, groupId, shiftId;
  final int initialPage;

  const EditEntityPage(
      {required this.memberId,
      required this.groupId,
      required this.shiftId,
      this.initialPage = 0,
      super.key});

  @override
  State<EditEntityPage> createState() => _EditEntityPageState();
}

class _EditEntityPageState extends State<EditEntityPage> {
  late String memberId;
  late String groupId;
  late int pageNumber;
  final memberFormKey = GlobalKey<FormState>();
  final groupFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    memberId = widget.memberId;
    groupId = widget.groupId;
    pageNumber = widget.initialPage;
  }

  @override
  Widget build(BuildContext context) {
    PageController controller =
        PageController(initialPage: pageNumber, keepPage: false);

    DataController dataController =
        Provider.of<DataController>(context, listen: false);

    return Scaffold(
        appBar: AppBar(actions: [
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              Shift shift = dataController.getShift(widget.shiftId);
              if (pageNumber == 0) {
                memberFormKey.currentState?.save();
                dataController.saveTempMember();
                if (!shift.memberIds.contains(memberId)) {
                  dataController.addMember(widget.shiftId, memberId);
                }
              } else if (pageNumber == 1) {
                groupFormKey.currentState?.save();
                dataController.saveTempGroup();
                if (!shift.groupIds.contains(groupId)) {
                  dataController.addGrouop(widget.shiftId, groupId);
                }
              } else {
                return;
              }
              dataController.saveTempShift().notify().flush();
              Future<bool?> quit = showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: const Text('Saved'),
                        content: Text(
                            'Quit or Keep editing with new ${pageNumber == 0 ? 'member' : 'group'}?'),
                        actions: [
                          TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                              child: const Text('Keep Editing')),
                          TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                              child: const Text('Quit'))
                        ],
                      ));
              quit.then(
                (value) {
                  if (value == null) {
                    return;
                  }
                  if (value) {
                    Navigator.of(context).pop();
                  } else {
                    setState(() {
                      if (pageNumber == 0) {
                        memberId = genId();
                      } else if (pageNumber == 1) {
                        groupId = genId();
                      }
                    });
                  }
                },
              );
            },
          ),
        ]),
        body: Column(children: [
          EntityHeader(
              selected: pageNumber,
              onSelectionChanged: (selected) {
                setState(() {
                  controller.animateToPage(selected,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut);
                  pageNumber = selected;
                });
              }),
          Expanded(
            child: PageView(
              controller: controller,
              onPageChanged: (value) {
                setState(() {
                  if (memberId == defaultId) {
                    memberId = genId();
                  }
                  if (groupId == defaultId) {
                    groupId = genId();
                  }
                  pageNumber = value;
                });
              },
              children: [
                EditMemberPart(
                  formKey: memberFormKey,
                  memberId: memberId,
                ),
                EditGroupPart(
                  formKey: groupFormKey,
                  groupId: groupId,
                  onMemberTap: (newMemberId) {
                    controller.animateToPage(0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                    setState(() {
                      pageNumber = 0;
                      memberId = newMemberId;
                    });
                  },
                )
              ],
            ),
          ),
        ]));
  }
}

class EntityHeader extends StatelessWidget {
  final int selected;
  final void Function(int selected) onSelectionChanged;
  const EntityHeader(
      {super.key, required this.selected, required this.onSelectionChanged});

  @override
  Widget build(BuildContext context) {
    Icon entityIcon;
    if (selected == 0) {
      entityIcon = const Icon(Icons.person);
    } else if (selected == 1) {
      entityIcon = const Icon(Icons.group);
    } else {
      throw ShiftWorkError('PageNumber $selected of EditEntityPage is invalid');
    }
    return Column(
      children: [
        Center(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 45),
              child: Transform.scale(
                scale: 4,
                child: CircleAvatar(
                  radius: 15,
                  child: entityIcon,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Transform.scale(
                scale: .7,
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment<int>(value: 0, label: Text('Member')),
                    ButtonSegment<int>(value: 1, label: Text('Group')),
                  ],
                  selected: {selected},
                  onSelectionChanged: (Set<int> selected) {
                    onSelectionChanged(selected.first);
                  },
                  showSelectedIcon: false,
                ),
              ),
            )
          ],
        )),
        const ContentDivider(),
      ],
    );
  }
}

class EditMemberPart extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String memberId;

  const EditMemberPart({
    super.key,
    required this.formKey,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context) {
    final preloadFormFieldKey = GlobalKey<FormFieldState<String>>();
    return Form(
      key: formKey,
      child:
          Consumer<DataController>(builder: (context, dataController, child) {
        Member member = dataController.getMember(memberId);
        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  StringFormField(
                    hintText: 'Name',
                    initialText: member.name,
                    onChanged: (text) {
                      member.name = text;
                    },
                    onSaved: (value) {
                      if (value == null) {
                        return;
                      }
                      member.name = value;
                    },
                  ),
                  StringFormField(
                    initialText: member.description,
                    hintText: 'Description',
                    onChanged: (text) {
                      member.description = text;
                    },
                    onSaved: (value) {
                      if (value == null) {
                        return;
                      }
                      member.description = value;
                    },
                  ),
                ],
              ),
            ),
            const ContentDivider(),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 30.0, vertical: 8),
              child: NumFormField(
                formFieldKey: preloadFormFieldKey,
                initialNum: member.preload,
                min: -10000,
                max: 10000,
                label: 'Works Done Before',
                onSaved: (value) {
                  member.preload = value.toDouble();
                },
              ),
            ),
            const ContentDivider(),
            Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: member.vacancyIds.length + 1,
                  itemBuilder: (context, index) {
                    List<String> vacancyIds = member.vacancyIds;
                    if (index >= vacancyIds.length) {
                      return NewListItem(
                        label: 'Add New Vacation',
                        onTap: () {
                          Iterable<Vacancy> otherVacancies =
                              dataController.getAllOtherVacancies(memberId);
                          if (otherVacancies.isEmpty) {
                            String vacancyId = genId();
                            Future<bool?> saved = showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) =>
                                    EditVacancyDialog(vacancyId: vacancyId));
                            saved.then((value) {
                              if (value == null) {
                                return;
                              }
                              if (value) {
                                dataController
                                    .saveTempVacancy()
                                    .addVacancy(memberId, vacancyId)
                                    .notify();
                              }
                            });
                            return;
                          }
                          Future<String?> vacancyId = showDialog<String>(
                              context: context,
                              builder: (BuildContext context) {
                                List<SimpleDialogOption> children = [];
                                children.add(SimpleDialogOption(
                                  onPressed: () {
                                    Navigator.of(context).pop(defaultId);
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('New Vacation'),
                                  ),
                                ));
                                children.addAll(otherVacancies.map(
                                  (e) => SimpleDialogOption(
                                    onPressed: () {
                                      Navigator.of(context).pop(e.id);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(e.name),
                                    ),
                                  ),
                                ));
                                return SimpleDialog(
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 24),
                                  children: children,
                                );
                              });
                          vacancyId.then((id) {
                            if (id == null || member.vacancyIds.contains(id)) {
                              return;
                            }
                            if (id == defaultId) {
                              String newId = genId();
                              Future<bool?> saved = showDialog<bool>(
                                  context: context,
                                  builder: (context) => EditVacancyDialog(
                                        vacancyId: newId,
                                      ));
                              saved.then((value) {
                                if (value == null) {
                                  return;
                                }
                                if (value) {
                                  dataController
                                      .saveTempVacancy()
                                      .addVacancy(memberId, newId)
                                      .notify();
                                }
                              });
                              return;
                            }
                            dataController.addVacancy(memberId, id).notify();
                          });
                        },
                      );
                    }
                    Vacancy vacancy =
                        dataController.getVacancy(vacancyIds[index]);
                    String description = '';
                    if (vacancy.description != '') {
                      description += '${vacancy.description}, ';
                    }
                    description += getSubtitle(vacancy);
                    return ListItem(
                      entityId: vacancy.id,
                      entityName: vacancy.name,
                      entityDescription: description,
                      entityIcon: const Icon(Icons.beach_access),
                      parentId: memberId,
                      onTap: (context) {
                        Future<bool?> saved = showDialog<bool>(
                            context: context,
                            builder: (context) => EditVacancyDialog(
                                  vacancyId: vacancy.id,
                                ));
                        saved.then((value) {
                          if (value == null) {
                            return;
                          }
                          if (value) {
                            dataController.saveTempVacancy().notify();
                          }
                        });
                      },
                      removeEntity: dataController.removeVacancy,
                      deletable: true,
                      deleteEntity: dataController.deleteVacancy,
                    );
                  }),
            )
          ],
        );
      }),
    );
  }
}

class EditGroupPart extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String groupId;
  final void Function(String memberId) onMemberTap;
  const EditGroupPart(
      {super.key,
      required this.formKey,
      required this.groupId,
      required this.onMemberTap});

  @override
  Widget build(BuildContext context) {
    var sliderFormFieldKey = GlobalKey<FormFieldState<double>>();
    return Form(
      key: formKey,
      child: Consumer<DataController>(
        builder: (context, dataController, child) {
          Group group = dataController.getGroup(groupId);
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  children: [
                    StringFormField(
                      initialText: group.name,
                      hintText: 'Name',
                      onChanged: (text) {
                        group.name = text;
                      },
                      onSaved: (value) {
                        if (value == null) {
                          return;
                        }
                        group.name = value;
                      },
                    ),
                    StringFormField(
                      initialText: group.description,
                      hintText: 'Description',
                      onChanged: (text) {
                        group.description = text;
                      },
                      onSaved: (value) {
                        if (value == null) {
                          return;
                        }
                        group.description = value;
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
                      initialInt: group.maximumAvailable,
                      max: group.memberIds.length,
                      label: "Maximum Available at Once",
                      onSaved: (newValue) {
                        if (newValue == null) {
                          return;
                        }
                        group.maximumAvailable = newValue.round();
                      },
                    ),
                    LeniencyFormField(
                      label: 'Maximum Available Leniency',
                      initialValue: group.maximumAvailableLeniency,
                      allowInherit: true,
                      onSaved: (newValue) {
                        if (newValue == null) {
                          return;
                        }
                        group.maximumAvailableLeniency = newValue;
                      },
                    )
                  ],
                ),
              ),
              const ContentDivider(),
              Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: group.memberIds.length + 1,
                    itemBuilder: (context, index) {
                      List<String> memberIds = group.memberIds;
                      if (index >= memberIds.length) {
                        return NewListItem(
                          label: 'Add a Member',
                          onTap: () {
                            Iterable<Member> otherMembers =
                                dataController.getAllOtherMembers(groupId);
                            if (otherMembers.isEmpty) {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      AlertDialog(
                                        title: const Text('Attention'),
                                        content: const Text(
                                            'There is no member to add.\nPlease create one first.'),
                                        actions: [
                                          TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop(true);
                                              },
                                              child: const Text('Close')),
                                        ],
                                      ));
                            } else {
                              Future<Set<dynamic>?> newMemberIds =
                                  showDialog<Set<dynamic>>(
                                context: context,
                                builder: (BuildContext context) => SelectDialog(
                                  ids: otherMembers.map(
                                    (e) => e.id,
                                  ),
                                  titles: otherMembers.map((e) => e.name),
                                  subtitles: otherMembers.map((e) =>
                                      (e.description == '')
                                          ? null
                                          : e.description),
                                ),
                              );
                              newMemberIds.then((ids) {
                                if (ids == null) {
                                  return;
                                }
                                dataController
                                    .getGroup(groupId)
                                    .memberIds
                                    .addAll(ids.map(
                                      (e) => e as String,
                                    ));
                                dataController.notify();
                              });
                            }
                          },
                        );
                      }

                      Member member =
                          dataController.getMember(memberIds[index]);
                      return ListItem(
                        entityId: memberIds[index],
                        entityName: member.name,
                        entityDescription: member.description,
                        entityIcon: const Icon(Icons.person),
                        parentId: groupId,
                        onTap: (context) {
                          onMemberTap(member.id);
                        },
                        removeEntity: (groupId, memberId) {
                          if (sliderFormFieldKey.currentState != null) {
                            changeIntSliderFormFieldState(
                                sliderFormFieldKey.currentState!, -1);
                          }
                          return dataController.removeMemberFromGroup(
                              groupId, memberId);
                        },
                        deletable: false,
                      );
                    }),
              )
            ],
          );
        },
      ),
    );
  }
}

class EditVacancyDialog extends StatelessWidget {
  final String vacancyId;

  const EditVacancyDialog({super.key, required this.vacancyId});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final startDateTimeFormFieldKey = GlobalKey<FormFieldState<DateTime>>();
    final endDateTimeFormFieldKey = GlobalKey<FormFieldState<DateTime>>();

    return Dialog.fullscreen(
      child: Form(
        key: formKey,
        child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  icon: const Icon(Icons.close)),
              actions: [
                TextButton(
                  onPressed: () {
                    formKey.currentState!.save();
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
            body: Consumer<DataController>(
              builder: (context, dataController, child) {
                Vacancy vacancy = dataController.getVacancy(vacancyId);
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: StringFormField(
                          initialText: vacancy.name,
                          hintText: 'Title',
                          autofocus: true,
                          onSaved: (text) {
                            if (text == null) {
                              return;
                            }
                            vacancy.name = text;
                          },
                        ),
                      ),
                      DateTimeFormField(
                        key: startDateTimeFormFieldKey,
                        initialDateTime: vacancy.startDateTime,
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
                          vacancy.startDateTime = dateTime;
                          dataController.notify();
                        },
                      ),
                      DateTimeFormField(
                        key: endDateTimeFormFieldKey,
                        initialDateTime: vacancy.endDateTime,
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
                          vacancy.endDateTime = dateTime;
                          dataController.notify();
                        },
                      ),
                      SwitchFormField(
                        initialBool: vacancy.isPaid,
                        label: 'Paid',
                        onSaved: (value) {
                          if (value == null) {
                            return;
                          }
                          vacancy.isPaid = value;
                        },
                      )
                    ]),
                  )
                ]);
              },
            )),
      ),
    );
  }
}
