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
      drawer: SideBar(),
      body: Center(
        child: Consumer<DataController>(
          builder: (context, dataController, child) => ListView.builder(
            scrollDirection: Axis.horizontal,
            itemBuilder: ((context, index) {
              return NewShiftCard();
            }),
          ),
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
    return Center(
      child: SizedBox(
        width: 400,
        height: 600,
        child: Card(
          margin: EdgeInsets.symmetric(vertical: 40, horizontal: 15),
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
      ),
    );
  }
}

class ShiftCard extends StatelessWidget {
  final String shiftId;

  const ShiftCard({required this.shiftId, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 400,
        height: 600,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => EditPage(
                      shiftId: shiftId,
                    )));
          },
          child: Card(
            margin: EdgeInsets.symmetric(vertical: 40, horizontal: 15),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Long Title",
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        Expanded(child: Container()),
                        IconButton(
                            onPressed: () {}, icon: Icon(Icons.more_vert)),
                      ],
                    ),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.chevron_right),
                    title: Text("groupMembers"),
                    subtitle: Text("Person, Person, ..."),
                  ),
                  ListTile(
                    leading: Icon(Icons.chevron_right),
                    title: Text("Works"),
                    subtitle: Text("Work, Work, ..."),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EditPage extends StatelessWidget {
  const EditPage({required this.shiftId, super.key});

  final String shiftId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Consumer<DataController>(
        builder: (context, dataController, child) => TextField(
          decoration: InputDecoration(
            hintText: dataController.getShift(shiftId).title,
          ),
          onChanged: (value) {
            dataController.getShift(shiftId).title = value;
            dataController.notify().flush();
          },
        ),
      )),
    );
  }
}

class DataController extends ChangeNotifier {
  final IOController ioController = IOController();

  DataController() {
    init();
  }

  Data data = Data.fromDefault();

  void init() {
    ioController.read().then((value) {
      try {
        data.update(jsonDecode(value));
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
      case Work:
        return getWork(id) as T;
      case Vacancy:
        return getVacancy(id) as T;
    }
    throw TypeError();
  }

  Shift getShift(String id) {
    if (data.shifts[id] == null) {
      data.shifts[id] = Shift.fromDefault(id: id);
    }
    return data.shifts[id]!;
  }

  Member getMember(String id) {
    if (data.members[id] == null) {
      data.members[id] = Member.fromDefault(id: id);
    }
    return data.members[id]!;
  }

  Work getWork(String id) {
    if (data.works[id] == null) {
      data.works[id] = Work.fromDefault(id: id);
    }
    return data.works[id]!;
  }

  Vacancy getVacancy(String id) {
    if (data.vacancies[id] == null) {
      data.vacancies[id] = Vacancy.fromDefault(id: id);
    }
    return data.vacancies[id]!;
  }

  DataController notify() {
    notifyListeners();
    return this;
  }

  void flush() {
    ioController.write(jsonEncode(data));
  }
}
