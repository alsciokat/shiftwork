import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
              dataController.saveTempShift().notify().flush();
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () {
                try {
                  Provider.of<DataController>(context, listen: false)
                      .saveTempShift()
                      .resetLoads()
                      .generateShift(widget.shiftId);
                } catch (error) {
                  if (error is ShiftWorkError) {
                    informUser(context,
                        title: 'Error', content: error.description);
                  } else {
                    informUser(context,
                        title: 'Error',
                        content: "I'm sorry. Something went wrong.\n$error");
                  }
                  return;
                }
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ShowPage(widget.shiftId)));
              },
              child: const Text('Create'))
        ],
      ),
      body: <Widget>[
        Consumer<DataController>(builder: (context, dataController, child) {
          Shift shift = dataController.getShift(widget.shiftId);
          int groupLength = shift.groupIds.length;
          int memberLength = shift.memberIds.length;
          bool otherGroup = dataController.data.groupData.objectOrder
              .where((element) => !shift.groupIds.contains(element))
              .isNotEmpty;
          bool otherMember = dataController.data.memberData.objectOrder
              .where((element) => !shift.memberIds.contains(element))
              .isNotEmpty;
          List<Widget> children = [];
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
                        memberId: defaultId,
                        groupId: group.id,
                        shiftId: widget.shiftId,
                        initialPage: 1,
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
                    informUser(context, title: 'No Group Exists');
                    return;
                  }
                  Future<Set<String>?> newGroupIds = showDialog<Set<String>>(
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
                        .addAll(ids);
                    dataController.notify();
                  });
                },
                label: 'Select Group'));
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
                          groupId: defaultId,
                          shiftId: widget.shiftId,
                          initialPage: 0,
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
                    informUser(context, title: 'No Member Exists');
                    return;
                  }
                  Future<Set<String>?> newMemberIds = showDialog<Set<String>>(
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
                        .addAll(ids);
                    dataController.notify();
                  });
                },
                label: 'Select Member'));
          }
          children.add(const Padding(padding: EdgeInsets.only(bottom: 100)));
          return ListView(
            children: children,
          );
        }),
        Consumer<DataController>(
          builder: (context, dataController, child) => ListView(children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dataController.getShift(widget.shiftId).workIds.length,
              itemBuilder: ((context, index) {
                Work work = dataController.getWork(
                    dataController.getShift(widget.shiftId).workIds[index]);
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
            const Padding(padding: EdgeInsets.only(bottom: 100))
          ]),
        ),
        Consumer<DataController>(
            builder: (context, dataController, child) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(children: [
                    LeniencyFormField(
                        label: 'Fixed Member Leniency',
                        initialValue: dataController
                            .getShift(widget.shiftId)
                            .fixedMemberLeniency,
                        onChanged: (value) {
                          if (value != null) {
                            dataController
                                .getShift(widget.shiftId)
                                .fixedMemberLeniency = value;
                            dataController.notify();
                          }
                        }),
                    LeniencyFormField(
                        label: 'Fixed Group Leniency',
                        initialValue: dataController
                            .getShift(widget.shiftId)
                            .fixedGroupLeniency,
                        onChanged: (value) {
                          if (value != null) {
                            dataController
                                .getShift(widget.shiftId)
                                .fixedGroupLeniency = value;
                            dataController.notify();
                          }
                        }),
                  ]),
                ))
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
                  Navigator.of(context).push<String>(MaterialPageRoute(
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
            label: 'Members',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.grid_view,
                color: Theme.of(context).colorScheme.onPrimary),
            icon: const Icon(Icons.grid_view_outlined),
            label: 'Works',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.tune,
                color: Theme.of(context).colorScheme.onPrimary),
            icon: const Icon(Icons.tune_outlined),
            label: 'Options',
          ),
        ],
      ),
    );
  }
}
