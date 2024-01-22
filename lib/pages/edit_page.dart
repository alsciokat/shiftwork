import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../core.dart';
import '../data.dart';
import '../comp.dart';
import 'edit_entity_page.dart';
import 'edit_work_page.dart';
import 'show_page.dart';

class EditPage extends StatefulWidget {
  const EditPage({required this.shiftId, super.key});

  final String shiftId;

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<DataController>(
          builder: (context, dataController, child) => TextField(
            decoration: InputDecoration(
              border: const OutlineInputBorder(borderSide: BorderSide.none),
              hintText: dataController.data.shiftData.defaultObject.title,
            ),
            controller: TextEditingController(
                text: dataController.getShift(widget.shiftId).title),
            style: Theme.of(context).textTheme.titleLarge,
            onSubmitted: (value) {
              dataController.getShift(widget.shiftId).title = value;
              if (widget.shiftId ==
                  dataController.data.shiftData.tempObject.id) {
                dataController.saveTempShift();
              }
              dataController.notify().flush();
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () {
                DataController dataController =
                    Provider.of<DataController>(context, listen: false);
                Shift shift = dataController.getShift(widget.shiftId);
                AppLocalizations l10n = AppLocalizations.of(context)!;
                if (shift.id == dataController.data.shiftData.tempObject.id) {
                  dataController.saveTempShift();
                }
                if (shift.memberIds.isEmpty) {
                  informUser(context,
                      title: l10n.attention, content: l10n.pleaseAddMember);
                  setState(() {
                    currentPageIndex = 0;
                  });
                  return;
                }
                if (shift.workIds.isEmpty) {
                  informUser(context,
                      title: l10n.attention, content: l10n.pleaseAddWork);
                  setState(() {
                    currentPageIndex = 1;
                  });
                  return;
                }
                Future<Object?> error =
                    Navigator.of(context).push<Object?>(MaterialPageRoute(
                        builder: (context) => ShowPage(
                              widget.shiftId,
                              generate: true,
                            )));
                error.then(
                  (value) {
                    if (value == null) {
                      return;
                    }
                    if (value is ShiftWorkError) {
                      informUser(context,
                          title: AppLocalizations.of(context)!.error,
                          content: value.description);
                    } else {
                      informUser(context,
                          title: AppLocalizations.of(context)!.error,
                          content:
                              "${AppLocalizations.of(context)!.sorryError}\n$value");
                    }
                  },
                );
              },
              child: Text(AppLocalizations.of(context)!.generate))
        ],
      ),
      body: <Widget>[
        Consumer<DataController>(builder: (context, dataController, child) {
          Shift shift = dataController.getShift(widget.shiftId);
          int groupLength = shift.groupIds.length;
          int memberLength = shift.memberIds.length;
          bool otherGroup = dataController.data.groupData.objectOrder
              .any((element) => !shift.groupIds.contains(element));
          bool otherMember = dataController.data.memberData.objectOrder
              .any((element) => !shift.memberIds.contains(element));
          List<Widget> children = [];
          children.add(const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child:
                BannerAdUnit(unitId: 'ca-app-pub-7340749292526171/1494772810'),
          ));
          if (groupLength > 0) {
            children.add(ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: groupLength,
              itemBuilder: ((context, index) {
                Group group = dataController.getGroup(shift.groupIds[index]);
                return ListItem(
                  entityId: group.id,
                  entityName: group.name,
                  entityDescription: group.description,
                  entityIcon: const Icon(Icons.group),
                  parentId: widget.shiftId,
                  onTap: (context) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => EditEntityPage(
                        memberId: genId(),
                        groupId: group.id,
                        shiftId: widget.shiftId,
                        initialPage: 1,
                        isEditing: true,
                      ),
                    ));
                  },
                  removeEntity: dataController.removeGroup,
                  deletable: true,
                  deleteEntity: dataController.deleteGroup,
                );
              }),
            ));
          }
          if (otherGroup) {
            children.add(NewListItem(
                onTap: () {
                  if (dataController.data.groupData.objectOrder.isEmpty) {
                    informUser(context,
                        title: AppLocalizations.of(context)!.noGroupExists);
                    return;
                  }
                  Future<Set<dynamic>?> newGroupIds = showDialog<Set<dynamic>>(
                      context: context,
                      builder: (context) {
                        Iterable<Group> groups = dataController
                            .data.groupData.objectOrder
                            .where(
                                (element) => !shift.groupIds.contains(element))
                            .map(
                              (e) => dataController.getGroup(e),
                            );
                        return SelectDialog(
                          ids: groups.map((e) => e.id),
                          titles: groups.map((e) => e.name),
                          subtitles: groups.map((e) =>
                              (e.description == '') ? null : e.description),
                        );
                      });
                  newGroupIds.then((ids) {
                    if (ids == null) {
                      return;
                    }
                    dataController
                        .getShift(widget.shiftId)
                        .groupIds
                        .addAll(ids.map((e) => e as String));
                    if (widget.shiftId ==
                        dataController.data.shiftData.tempObject.id) {
                      dataController.saveTempShift();
                    }
                    dataController.notify();
                  });
                },
                label: AppLocalizations.of(context)!.selectGroup));
          }
          if ((groupLength > 0 || otherGroup) &&
              (memberLength > 0 || otherGroup)) {
            children.add(const ContentDivider());
          }
          if (memberLength > 0) {
            children.add(
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: memberLength,
                itemBuilder: ((context, index) {
                  Member member =
                      dataController.getMember(shift.memberIds[index]);
                  return ListItem(
                    entityId: member.id,
                    entityName: member.name,
                    entityDescription: member.description,
                    entityIcon: const Icon(Icons.person),
                    parentId: widget.shiftId,
                    onTap: (context) {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => EditEntityPage(
                          memberId: member.id,
                          groupId: genId(),
                          shiftId: widget.shiftId,
                          initialPage: 0,
                          isEditing: true,
                        ),
                      ));
                    },
                    removeEntity: dataController.removeMember,
                    deletable: true,
                    deleteEntity: dataController.deleteMember,
                  );
                }),
              ),
            );
          }
          if (otherMember) {
            children.add(NewListItem(
                onTap: () {
                  if (dataController.data.memberData.objectOrder.isEmpty) {
                    informUser(context,
                        title: AppLocalizations.of(context)!.noMemberExists);
                    return;
                  }
                  Future<Set<dynamic>?> newMemberIds = showDialog<Set<dynamic>>(
                      context: context,
                      builder: (context) {
                        Iterable<Member> members = dataController
                            .data.memberData.objectOrder
                            .where(
                                (element) => !shift.memberIds.contains(element))
                            .map(
                              (e) => dataController.getMember(e),
                            );
                        return SelectDialog(
                          ids: members.map((e) => e.id),
                          titles: members.map((e) => e.name),
                          subtitles: members.map((e) =>
                              (e.description == '') ? null : e.description),
                        );
                      });
                  newMemberIds.then((ids) {
                    if (ids == null) {
                      return;
                    }
                    dataController
                        .getShift(widget.shiftId)
                        .memberIds
                        .addAll(ids.map((e) => e as String));
                    if (widget.shiftId ==
                        dataController.data.shiftData.tempObject.id) {
                      dataController.saveTempShift();
                    }
                    dataController.notify();
                  });
                },
                label: AppLocalizations.of(context)!.selectMember));
          }
          children.add(const Padding(padding: EdgeInsets.only(bottom: 100)));
          return ListView(
            children: children,
          );
        }),
        Consumer<DataController>(builder: (context, dataController, child) {
          Shift shift = dataController.getShift(widget.shiftId);
          bool otherWork = false;
          if (dataController.data.workData.objectOrder
              .any((workId) => !shift.workIds.contains(workId))) {
            otherWork = true;
          }
          return ListView(children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: BannerAdUnit(
                  unitId: 'ca-app-pub-7340749292526171/4711128947'),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: shift.workIds.length,
              itemBuilder: ((context, index) {
                Work work = dataController.getWork(shift.workIds[index]);
                return ListItem(
                  entityId: work.id,
                  entityName: work.name,
                  entityDescription: work.description,
                  entityIcon: const Icon(Icons.notes),
                  parentId: widget.shiftId,
                  onTap: (context) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => EditWorkPage(
                          shiftId: widget.shiftId, workId: work.id),
                    ));
                  },
                  removeEntity: dataController.removeWork,
                  deletable: true,
                  deleteEntity: dataController.deleteWork,
                );
              }),
            ),
            otherWork
                ? NewListItem(
                    onTap: () {
                      if (dataController.data.workData.objectOrder.isEmpty) {
                        informUser(context,
                            title: AppLocalizations.of(context)!.noWorkExists);
                        return;
                      }
                      Future<Set<dynamic>?> newWorkIds =
                          showDialog<Set<dynamic>>(
                              context: context,
                              builder: (context) {
                                Iterable<Work> works = dataController
                                    .data.workData.objectOrder
                                    .where((element) =>
                                        !shift.workIds.contains(element))
                                    .map(
                                      (e) => dataController.getWork(e),
                                    );
                                return SelectDialog(
                                  ids: works.map((e) => e.id),
                                  titles: works.map((e) => e.name),
                                  subtitles: works.map((e) =>
                                      (e.description == '')
                                          ? null
                                          : e.description),
                                );
                              });
                      newWorkIds.then((ids) {
                        if (ids == null) {
                          return;
                        }
                        shift.workIds.addAll(ids.map((e) => e as String));
                        if (widget.shiftId ==
                            dataController.data.shiftData.tempObject.id) {
                          dataController.saveTempShift();
                        }
                        dataController.notify();
                      });
                    },
                    label: AppLocalizations.of(context)!.selectWork)
                : const SizedBox(),
            const Padding(padding: EdgeInsets.only(bottom: 100))
          ]);
        }),
        Consumer<DataController>(builder: (context, dataController, child) {
          Shift shift = dataController.getShift(widget.shiftId);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(children: [
              LeniencyFormField(
                  context: context,
                  label:
                      AppLocalizations.of(context)!.fixedMemberLeniencyDefault,
                  initialValue: shift.fixedMemberLeniency,
                  onChanged: (value) {
                    if (value != null) {
                      shift.fixedMemberLeniency = value;
                    }
                  }),
              LeniencyFormField(
                  context: context,
                  label:
                      AppLocalizations.of(context)!.fixedGroupLeniencyDefault,
                  initialValue: shift.fixedGroupLeniency,
                  onChanged: (value) {
                    if (value != null) {
                      shift.fixedGroupLeniency = value;
                    }
                  }),
              LeniencyFormField(
                  context: context,
                  label: AppLocalizations.of(context)!
                      .excludedMemberLeniencyDefault,
                  initialValue: shift.excludedMemberLeniency,
                  onChanged: (value) {
                    if (value != null) {
                      shift.excludedMemberLeniency = value;
                    }
                  }),
              LeniencyFormField(
                  context: context,
                  label: AppLocalizations.of(context)!
                      .excludedGroupLeniencyDefault,
                  initialValue: shift.excludedGroupLeniency,
                  onChanged: (value) {
                    if (value != null) {
                      shift.excludedGroupLeniency = value;
                    }
                  }),
              LeniencyFormField(
                  context: context,
                  label: AppLocalizations.of(context)!
                      .maximumAvailableLeniencyDefault,
                  initialValue: shift.maximumAvailableLeniency,
                  onChanged: (value) {
                    if (value != null) {
                      shift.maximumAvailableLeniency = value;
                    }
                  }),
              SwitchFormField(
                initialBool: shift.shuffleMembers,
                label: AppLocalizations.of(context)!.shuffleMembers,
                onChanged: (value) {
                  shift.shuffleMembers = value;
                },
              )
            ]),
          );
        })
      ][currentPageIndex],
      floatingActionButton: currentPageIndex == 2
          ? null
          : FloatingActionButton(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.add),
              onPressed: () {
                if (currentPageIndex == 0) {
                  Navigator.of(context)
                      .push<String>(MaterialPageRoute(builder: (context) {
                    return EditEntityPage(
                        memberId: genId(),
                        groupId: genId(),
                        shiftId: widget.shiftId,
                        initialPage: 0);
                  }));
                } else if (currentPageIndex == 1) {
                  Navigator.of(context).push<bool>(MaterialPageRoute(
                    builder: (context) =>
                        EditWorkPage(shiftId: widget.shiftId, workId: genId()),
                  ));
                }
              },
            ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Theme.of(context).colorScheme.primary,
        selectedIndex: currentPageIndex,
        destinations: <Widget>[
          NavigationDestination(
            selectedIcon: Icon(
              Icons.group,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            icon: const Icon(Icons.group_outlined),
            label: AppLocalizations.of(context)!.members,
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.grid_view,
                color: Theme.of(context).colorScheme.onPrimary),
            icon: const Icon(Icons.grid_view_outlined),
            label: AppLocalizations.of(context)!.works,
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.tune,
                color: Theme.of(context).colorScheme.onPrimary),
            icon: const Icon(Icons.tune_outlined),
            label: AppLocalizations.of(context)!.options,
          ),
        ],
      ),
    );
  }
}
