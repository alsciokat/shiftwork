import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

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
      drawer: Drawer(
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
      ),
      body: Center(
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [NewShiftCard()],
        ),
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
              hintText: dataController.get('title', id: shiftId)),
          onChanged: (value) {
            dataController.set('title', value, id: shiftId).flush();
          },
        ),
      )),
    );
  }
}

class IOController {
  Future<File> get dataFile async {
    // /data/user/0/com.example.shift/app_flutter
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/shift_data.json');
    if (!file.existsSync()) {
      file.create(recursive: true);
    }
    return file;
  }

  Future<File> write(String data) async {
    final file = await dataFile;
    return file.writeAsString(data);
  }

  Future<String> read() async {
    final file = await dataFile;
    return file.readAsString();
  }
}

class DataController extends ChangeNotifier {
  final IOController ioController = IOController();

  DataController() {
    init();
  }

  Map<String, Map<String, String>> data = {
    'default': {'title': 'Untitled'}
  };

  void init() {
    ioController.read().then((value) {
      try {
        data = jsonDecode(value);
        notifyListeners();
      } catch (error) {
        logger.severe(error);
      }
    });
  }

  dynamic get(String key, {required String id}) {
    return data[id]?[key] ?? data['default']?[key];
  }

  DataController set(String key, var value, {required String id}) {
    data[id] ??= {};
    data[id]?[key] = value;
    notifyListeners();
    return this;
  }

  void flush() {
    ioController.write(jsonEncode(data));
  }
}

// weight of fatigue just after the work finished
double initialWeight = 2;
// the attenuation time of fatigue in minutes
double tau = 60;

class Member {
  final String id;
  String name;
  double preload = 0;
  List<Vacancy> vacancies = [];

  double previousToTalLoad = 0;
  double previousLoad = 0;
  DateTime previousLoadEndDateTime = DateTime(1970);

  Member(
      {required this.id,
      required this.name,
      required this.vacancies,
      this.preload = 0});

  bool isAvailable(DateTime dateTime) {
    for (final vacancy in vacancies) {
      if (vacancy.include(dateTime)) {
        return false;
      }
    }
    return true;
  }

  double getLoad(Duration duration) {
    return previousToTalLoad + previousLoad * weight(duration.inMinutes);
  }

  double weight(int t) {
    if (t >= 3600) return 1;

    return max(
        1,
        initialWeight -
            (1 - 1 / e) *
                characteristicFuction(t) /
                characteristicFuction(tau) *
                (initialWeight - 1));
  }

  double characteristicFuction(num t) {
    return exp(t) - 1;
  }
}

class Vacancy {
  DateTime startDateTime;
  DateTime endDateTime;
  String description;

  Vacancy(
      {required this.startDateTime,
      required this.endDateTime,
      this.description = ""});

  Duration get duration {
    return endDateTime.difference(startDateTime);
  }

  bool include(DateTime dateTime) {
    return (startDateTime.isBefore(dateTime) ||
            startDateTime.isAtSameMomentAs(dateTime)) &&
        (endDateTime.isAfter(dateTime) ||
            endDateTime.isAtSameMomentAs(dateTime));
  }
}

class Shift {
  final String id;
  String title;
  List<Member> members = [];
  List<Work> works = [];

  Shift({required this.id, this.title = "Untitled"});
}

class Work {
  final String id;
  double load;
  List<Member> fixedMembers = [];
  List<Member> members = [];

  Work({required this.id, required this.load, required this.fixedMembers});
}

String genId() {
  final id = DateTime.now().millisecondsSinceEpoch.toString();
  logger.info('New ID generated: $id');
  return id;
}
