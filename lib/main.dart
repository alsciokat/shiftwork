import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'lib.dart';

final logger = Logger('global');

void main() {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(ChangeNotifierProvider(
    create: (context) => DataController(),
    child: const ShiftWork(),
  ));
}

class ShiftWork extends StatelessWidget {
  const ShiftWork({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShiftWork',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: const SideBar(),
      body: Consumer<DataController>(
        builder: (context, dataController, child) => ListView.builder(
          itemCount: dataController.data.shiftData.objectOrder.length + 1,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          itemBuilder: ((context, index) {
            if (index >= dataController.data.shiftData.objectOrder.length) {
              return const Center(child: NewShiftCard());
            }
            return Center(
              child: ShiftCard(
                  shiftId: dataController.data.shiftData.objectOrder[index]),
            );
          }),
        ),
      ),
    );
  }
}

class SideBar extends StatelessWidget {
  const SideBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
            ),
            child: Text(
              'Drawer Header',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.message),
            title: Text('Messages'),
          ),
          ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('Profile'),
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
          ),
        ],
      ),
    );
  }
}

class NewShiftCard extends StatelessWidget {
  const NewShiftCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      height: 600,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 15),
        elevation: 2,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => EditPage(
                      shiftId: genId(),
                    )));
          },
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(
              child: SizedBox(
                width: 100,
                height: 100,
                child: Column(
                  children: [
                    Icon(Icons.add, opticalSize: 48),
                    Text("New Shift")
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ShiftCard extends StatelessWidget {
  final String shiftId;

  const ShiftCard({required this.shiftId, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      height: 600,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 15),
        elevation: 2,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => EditPage(
                      shiftId: shiftId,
                    )));
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Consumer<DataController>(
                          builder: (context, dataController, child) => Text(
                                dataController.getShift(shiftId).name,
                                style:
                                    Theme.of(context).textTheme.headlineLarge,
                              )),
                      Expanded(child: Container()),
                      MenuAnchor(
                          builder: (context, controller, child) => IconButton(
                              onPressed: () {
                                if (controller.isOpen) {
                                  controller.close();
                                } else {
                                  controller.open(
                                      position: const Offset(-20, 45));
                                }
                              },
                              icon: const Icon(Icons.more_vert)),
                          menuChildren: [
                            MenuItemButton(
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                            title: const Text('Delete Shift'),
                                            content: const Text(
                                                'Are you sure you want to delete this shift?'),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                  child: const Text('Cancel')),
                                              TextButton(
                                                  onPressed: () {
                                                    Provider.of<DataController>(
                                                            context,
                                                            listen: false)
                                                        .deleteShift(shiftId)
                                                        .notify()
                                                        .flush();
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                        color: Colors.red),
                                                  ))
                                            ],
                                          ));
                                },
                                child: const Text('Delete'))
                          ]),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.chevron_right),
                  title: const Text("Members"),
                  subtitle: Consumer<DataController>(
                      builder: (context, dataController, child) => Text(() {
                            final String str = dataController
                                .getMemberNames(
                                    dataController.getShift(shiftId).memberIds)
                                .join(", ");
                            if (str == "") {
                              return "No Members";
                            } else {
                              return str;
                            }
                          }())),
                ),
                ListTile(
                  leading: const Icon(Icons.chevron_right),
                  title: Text("Works"),
                  subtitle: Consumer<DataController>(
                      builder: (context, dataController, child) => Text(() {
                            final String str = dataController
                                .getWorkNames(
                                    dataController.getShift(shiftId).workIds)
                                .join(", ");
                            if (str == "") {
                              return "No Works";
                            } else {
                              return str;
                            }
                          }())),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
            hintText: dataController.data.shiftData.defaultObject.name,
          ),
          controller: TextEditingController(
              text: dataController.getShift(widget.shiftId).name),
          style: Theme.of(context).textTheme.titleLarge,
          onSubmitted: (value) {
            dataController.getShift(widget.shiftId).name = value;
            dataController.notify().flush();
          },
        ),
      )),
      body: <Widget>[
        Consumer<DataController>(
          builder: (context, dataController, child) => ListView.builder(
            itemCount: dataController.getShift(widget.shiftId).memberIds.length,
            itemBuilder: ((context, index) {
              return MemberListItem(
                  shiftId: widget.shiftId,
                  member: dataController.getMember(dataController
                      .getShift(widget.shiftId)
                      .memberIds[index]));
            }),
          ),
        ),
        Container(
          color: Theme.of(context).colorScheme.secondary,
          child: Center(child: Text('Under Construction')),
        ),
        // Consumer<DataController>(
        //   builder: (context, dataController, child) => ListView.builder(
        //     itemCount: dataController.getShift(widget.shiftId).workIds.length,
        //     itemBuilder: ((context, index) {
        //       return WorkListItem(
        //           shiftId: widget.shiftId,
        //           work: dataController.getWork(dataController
        //               .getShift(widget.shiftId)
        //               .workIds[index]));
        //     }),
        //   ),
        // ),
        Container(
          color: Theme.of(context).colorScheme.secondary,
          child: Center(child: Text('Under Construction')),
        )
      ][currentPageIndex],
      floatingActionButton: FloatingActionButton(
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
        onPressed: () {
          if (currentPageIndex == 0) {
            Navigator.of(context).push<String>(MaterialPageRoute(
              builder: (context) =>
                  EditMemberPage(shiftId: widget.shiftId, memberId: genId()),
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

class EditMemberPage extends StatefulWidget {
  final String memberId;
  final String shiftId;

  const EditMemberPage(
      {required this.shiftId, required this.memberId, super.key});

  @override
  State<EditMemberPage> createState() => _EditMemberPageState();
}

class _EditMemberPageState extends State<EditMemberPage> {
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Scaffold(
        appBar: AppBar(actions: [
          Consumer<DataController>(
            builder: (context, dataController, child) => TextButton(
              child: const Text('Save'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  dataController.saveTemp();
                  if (!dataController
                      .getShift(widget.shiftId)
                      .memberIds
                      .contains(widget.memberId)) {
                    dataController.addMember(widget.shiftId, widget.memberId);
                  }
                  dataController.notify().flush();
                  Navigator.of(context).pop(widget.memberId);
                }
              },
            ),
          )
        ]),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Consumer<DataController>(
            builder: (context, dataController, child) => Column(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  decoration: const InputDecoration(helperText: 'Name'),
                  initialValue: dataController.getMember(widget.memberId).name,
                  validator: (value) {
                    dataController.getMember(widget.memberId).name =
                        value ?? '';
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  decoration: const InputDecoration(helperText: 'Description'),
                  initialValue:
                      dataController.getMember(widget.memberId).description,
                  validator: (value) {
                    dataController.getMember(widget.memberId).description =
                        value ?? '';
                    return null;
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class MemberListItem extends StatelessWidget {
  final Member member;
  final String shiftId;

  const MemberListItem(
      {required this.shiftId, required this.member, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.person),
      title: Text(member.name),
      subtitle: Text(member.description),
      trailing: MenuAnchor(
          builder: (context, controller, child) => IconButton(
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open(position: const Offset(-20, 45));
                }
              },
              icon: const Icon(Icons.more_vert)),
          menuChildren: [
            MenuItemButton(
                onPressed: () {
                  Provider.of<DataController>(context, listen: false)
                      .removeMember(shiftId, member.id)
                      .notify()
                      .flush();
                },
                child: const Text('Remove')),
            MenuItemButton(
                onPressed: () {
                  Provider.of<DataController>(context, listen: false)
                      .removeMember(shiftId, member.id)
                      .deleteMember(member.id)
                      .notify()
                      .flush();
                },
                child: const Text('Delete')),
          ]),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) =>
              EditMemberPage(shiftId: shiftId, memberId: member.id),
        ));
      },
    );
  }
}

// class WorkListItem extends StatelessWidget {
//   final Work work;
//   final String shiftId;

//   const WorkListItem({required this.shiftId, required this.work, super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       leading: const Icon(Icons.notes),
//       title: Text(work.name),
//       subtitle: Text(work.description),
//       trailing: MenuAnchor(
//           builder: (context, controller, child) => IconButton(
//               onPressed: () {
//                 if (controller.isOpen) {
//                   controller.close();
//                 } else {
//                   controller.open(position: const Offset(-20, 45));
//                 }
//               },
//               icon: const Icon(Icons.more_vert)),
//           menuChildren: [
//             MenuItemButton(
//                 onPressed: () {
//                   Provider.of<DataController>(context, listen: false)
//                       .removeWork(shiftId, work.id)
//                       .notify()
//                       .flush();
//                 },
//                 child: const Text('Remove')),
//             MenuItemButton(
//                 onPressed: () {
//                   Provider.of<DataController>(context, listen: false)
//                       .removeWork(shiftId, work.id)
//                       .deleteWork(work.id)
//                       .notify()
//                       .flush();
//                 },
//                 child: const Text('Delete')),
//           ]),
//       onTap: () {
//         Navigator.of(context).push(MaterialPageRoute(
//           builder: (context) =>
//               EditWorkPage(shiftId: shiftId, workId: work.id),
//         ));
//       },
//     );
//   }
// }

class DataController extends ChangeNotifier {
  final IOController ioController = IOController();

  DataController() {
    init();
  }

  final Data data = Data.fromDefault();

  void init() {
    ioController.read().then((value) {
      try {
        data.updateAll(jsonDecode(value));
        notifyListeners();
      } catch (error) {
        logger.severe(error);
      }
    });
  }

  T get<T>(String id) {
    switch (T) {
      case Shift:
        return getShift(id) as T;
      case Member:
        return getMember(id) as T;
      // case Work:
      //   return getWork(id) as T;
      // case Vacancy:
      //   return getVacancy(id) as T;
    }
    throw TypeError();
  }

  bool _tempShift = false;
  String _tempShiftId = defaultTempId;

  Shift getShift(String id) {
    if (_tempShift & (_tempShiftId == id)) {
      return data.shiftData.tempObject as Shift;
    }
    if (!data.shiftData.objectMap.keys.contains(id)) {
      _tempShift = true;
      _tempShiftId = id;
      return data.shiftData.getTemp(id) as Shift;
    }
    return data.shiftData.getById(id) as Shift;
  }

  DataController deleteShift(String shiftId) {
    data.shiftData.objectOrder.remove(shiftId);
    data.shiftData.objectMap.remove(shiftId);
    return this;
  }

  bool _tempMember = false;
  String _tempMemberId = defaultTempId;

  Member getMember(String id) {
    if (_tempMember & (_tempMemberId == id)) {
      return data.memberData.tempObject as Member;
    }
    if (!data.memberData.objectMap.keys.contains(id)) {
      _tempMember = true;
      _tempMemberId = id;
      return data.memberData.getTemp(id) as Member;
    }
    return data.memberData.getById(id) as Member;
  }

  List<String> getMemberNames(List<String> ids) {
    List<String> names = [];
    for (final id in ids) {
      names.add(data.memberData.getName(id));
    }
    return names;
  }

  DataController addMember(String shiftId, String memberId) {
    getShift(shiftId).memberIds.add(memberId);
    return this;
  }

  DataController removeMember(String shiftId, String memberId) {
    getShift(shiftId).memberIds.remove(memberId);
    return this;
  }

  DataController deleteMember(String memberId) {
    data.memberData.objectOrder.remove(memberId);
    data.memberData.objectMap.remove(memberId);
    return this;
  }

  bool _tempWork = false;
  String _tempWorkId = defaultTempId;

  Work getWork(String id) {
    if (_tempWork & (_tempWorkId == id)) {
      return data.workData.tempObject as Work;
    }
    if (!data.workData.objectMap.keys.contains(id)) {
      _tempWork = true;
      _tempWorkId = id;
      return data.workData.getTemp(id) as Work;
    }
    return data.workData.getById(id) as Work;
  }

  List<String> getWorkNames(List<String> ids) {
    List<String> names = [];
    for (final id in ids) {
      names.add(data.workData.getName(id));
    }
    return names;
  }

  // Vacancy getVacancy(String id) {
  //   return data.vacancyData.getById(id) as Vacancy;
  // }

  DataController saveTemp() {
    if (_tempMember) {
      data.memberData.saveTemp();
      _tempMember = false;
    }
    if (_tempWork) {
      data.workData.saveTemp();
      _tempWork = false;
    }
    if (_tempShift) {
      data.shiftData.saveTemp();
      _tempShift = false;
    }
    return this;
  }

  DataController notify() {
    notifyListeners();
    return this;
  }

  DataController flush() {
    ioController.write(jsonEncode(data));
    return this;
  }
}
