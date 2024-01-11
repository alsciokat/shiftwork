import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shift_work/comp.dart';
import 'package:shift_work/pages/show_page.dart';

import '../core.dart';
import '../data.dart';
import 'edit_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: const SideBar(),
      body: Column(
        children: [
          Consumer<DataController>(
            builder: (context, dataController, child) => Expanded(
              child: ListView.builder(
                itemCount: dataController.data.shiftData.objectOrder.length + 1,
                itemExtent: 260,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 50),
                itemBuilder: (context, index) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 100.0),
                      child: index >=
                              dataController.data.shiftData.objectOrder.length
                          ? const NewShiftCard()
                          : ShiftCard(
                              shiftId: dataController
                                  .data.shiftData.objectOrder[index]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const HomeBannerAd(),
        ],
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
      width: 230,
      height: 350,
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => EditPage(
                      shiftId: genId(),
                    )));
          },
          child: const Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 124.0),
                child: Icon(
                  Icons.add,
                  weight: 100,
                  size: 42,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Text(
                  "New Shift",
                  style: TextStyle(fontSize: 16),
                ),
              )
            ],
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
      width: 230,
      height: 350,
      child: Card(
        elevation: 2,
        child:
            Consumer<DataController>(builder: (context, dataController, child) {
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
          bool created = dataController.getShift(shiftId).created;
          return InkWell(
            onTap: () {
              if (created) {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => ShowPage(shiftId)));
              } else {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => EditPage(
                          shiftId: shiftId,
                        )));
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0, right: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(
                            dataController.getShift(shiftId).title,
                            style: Theme.of(context).textTheme.titleLarge,
                            maxLines: 2,
                            overflow: TextOverflow.fade,
                          ),
                        ),
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
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(
                                            builder: (context) => EditPage(
                                                  shiftId: shiftId,
                                                )));
                                  },
                                  child: const Text('Edit')),
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
                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.only(left: 20.0, right: 20, top: 5),
                      child: Column(children: [
                        const Divider(
                          height: 0,
                        ),
                        ShiftDetail(
                            icon: const Icon(Icons.group),
                            label: 'Members',
                            detail: memberNames),
                        ShiftDetail(
                            icon: const Icon(Icons.grid_view),
                            label: 'Works',
                            detail: workNames),
                        Expanded(
                          child: Container(),
                        ),
                        created
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Created',
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  )
                                ],
                              )
                            : const Padding(
                                padding: EdgeInsets.zero,
                              )
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class ShiftDetail extends StatelessWidget {
  final Icon icon;
  final String label;
  final String detail;
  const ShiftDetail(
      {super.key,
      required this.icon,
      required this.label,
      required this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            icon,
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              detail,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
