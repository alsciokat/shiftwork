import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core.dart';
import '../data.dart';
import 'edit_page.dart';

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
        children: const <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.lightBlue,
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
            child: Consumer<DataController>(
                builder: (context, dataController, child) {
              String memberNames = dataController
                  .getShift(shiftId)
                  .memberIds
                  .map((id) => dataController.getMember(id).name)
                  .join(", ");
              if (memberNames == "") {
                memberNames = "No Members";
              }
              String workNames = dataController
                  .getShift(shiftId)
                  .workIds
                  .map((id) => dataController.getWork(id).name)
                  .join(", ");
              if (workNames == "") {
                workNames = "No Works";
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          dataController.getShift(shiftId).title,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
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
                                                    child:
                                                        const Text('Cancel')),
                                                TextButton(
                                                    onPressed: () {
                                                      Provider.of<DataController>(
                                                              context,
                                                              listen: false)
                                                          .deleteShift(shiftId)
                                                          .notify()
                                                          .flush();
                                                      Navigator.of(context)
                                                          .pop();
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
                    subtitle: Text(memberNames),
                  ),
                  ListTile(
                    leading: const Icon(Icons.chevron_right),
                    title: const Text("Works"),
                    subtitle: Text(workNames),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
