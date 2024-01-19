import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../core.dart';
import '../data.dart';
import '../comp.dart';
import 'edit_page.dart';
import 'about_page.dart';
import 'show_page.dart';
import 'settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ShiftWork'),
      ),
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
          const BannerAdUnit(
            unitId: "ca-app-pub-7340749292526171/4946793048",
          ),
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
        physics: const NeverScrollableScrollPhysics(),
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: Image(image: AssetImage('assets/icon.png')),
          ),
          InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const SettingsPage()));
            },
            child: ListTile(
              leading: const Icon(Icons.settings),
              title: Text(AppLocalizations.of(context)!.settings),
            ),
          ),
          InkWell(
            onTap: () {
              final Uri url =
                  Uri.parse('https://github.com/alsciaukat/ShiftWork');
              launchUrl(url);
            },
            child: ListTile(
              leading: const Icon(Icons.help),
              title: Text(AppLocalizations.of(context)!.help),
            ),
          ),
          InkWell(
            onTap: () {
              final Uri url = Uri.parse(
                  'mailto:alsciokat@gmail.com?subject=ShiftWork Feedback&body=${AppLocalizations.of(context)!.thanks}');
              launchUrl(url);
            },
            child: ListTile(
              leading: const Icon(Icons.feedback),
              title: Text(AppLocalizations.of(context)!.feedback),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutPage(),
                  ));
            },
            child: ListTile(
              leading: const Icon(Icons.info),
              title: Text(AppLocalizations.of(context)!.about),
            ),
          )
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
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 124.0),
                child: Icon(
                  Icons.add,
                  weight: 100,
                  size: 42,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text(
                  AppLocalizations.of(context)!.newShift,
                  style: const TextStyle(fontSize: 16),
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
            memberNames = AppLocalizations.of(context)!.noMembers;
          }
          String workNames = dataController
              .getShift(shiftId)
              .workIds
              .map((id) => dataController.getWork(id).name)
              .join(", ");
          if (workNames == "") {
            workNames = AppLocalizations.of(context)!.noWorks;
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
                                  child:
                                      Text(AppLocalizations.of(context)!.edit)),
                              MenuItemButton(
                                  onPressed: () {
                                    showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                              title: Text(
                                                  AppLocalizations.of(context)!
                                                      .deleteShift),
                                              content: Text(
                                                  AppLocalizations.of(context)!
                                                      .sureDeleteShift),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(),
                                                    child: Text(
                                                        AppLocalizations.of(
                                                                context)!
                                                            .cancel)),
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
                                                    child: Text(
                                                      AppLocalizations.of(
                                                              context)!
                                                          .delete,
                                                      style: const TextStyle(
                                                          color: Colors.red),
                                                    ))
                                              ],
                                            ));
                                  },
                                  child: Text(
                                      AppLocalizations.of(context)!.delete))
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
                            label: AppLocalizations.of(context)!.members,
                            detail: memberNames),
                        ShiftDetail(
                            icon: const Icon(Icons.grid_view),
                            label: AppLocalizations.of(context)!.works,
                            detail: workNames),
                        Expanded(
                          child: Container(),
                        ),
                        created
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.generated,
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
