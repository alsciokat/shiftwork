import 'dart:math';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

enum DataType {
  shift,
  member,
  work,
  vacancy,
  group,
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

// weight of fatigue just after the work finished
double initialWeight = 2;
// the attenuation time of fatigue in minutes
double tau = 60;

class DataObject {
  dynamic toJson() {}
}

class Data implements DataObject {
  Map<String, Shift> shifts;
  Map<String, Member> members;
  Map<String, Work> works;
  Map<String, Vacancy> vacancies;

  Data(
      {required this.shifts,
      required this.members,
      required this.works,
      required this.vacancies});

  Data.fromDefault()
      : shifts = {'default': Shift.fromDefault(id: 'default')},
        members = {'default': Member.fromDefault(id: 'default')},
        works = {'default': Work.fromDefault(id: 'default')},
        vacancies = {'default': Vacancy.fromDefault(id: 'default')};

  Data update(Map<String, Map<String, dynamic>> json) {
    json[DataType.shift.name]?.forEach((id, shift) {
      if (id == 'default') {
        Shift.titleDefault = shift['title'];
        Shift.memberIDsDefault = shift['memberIDs'];
        Shift.workIDsDefault = shift['workIDs'];
        Shift.descriptionDefault = shift['description'];
      }
      shifts[id] = Shift(
          id: id,
          title: shift['title'],
          memberIDs: shift['memberIDs'],
          workIDs: shift['workIDs'],
          description: shift['description']);
    });
    json[DataType.member.name]?.forEach((id, member) {
      if (id == 'default') {
        Member.nameDefault = member['name'];
        Member.preloadDefault = member['preload'];
        Member.vacancyIDsDefault = member['vacancyIDs'];
        Member.descriptionDefault = member['description'];
      }
      members[id] = Member(
          id: id,
          name: member['name'],
          preload: member['preload'],
          vacancyIDs: member['vacancyIDs'],
          description: member['description']);
    });
    json[DataType.work.name]?.forEach((id, work) {
      if (id == 'default') {
        Work.nameDefault = work['name'];
        Work.loadDefault = work['load'];
        Work.fixedMemberIDsDefault = work['fixedMemberIDs'];
        Work.memberIDsDefault = work['memberIDs'];
        Work.descriptionDefault = work['description'];
      }
      works[id] = Work(
          id: id,
          name: work['name'],
          load: work['load'],
          fixedMemberIDs: work['fixedMemberIDs'],
          memberIDs: work['memberIDs'],
          description: work['description']);
    });
    json[DataType.vacancy.name]?.forEach((id, vacancy) {
      if (id == 'default') {
        Vacancy.nameDefault = vacancy['name'];
        Vacancy.startDateTimeDefault = DateTime.parse(vacancy['startDateTime']);
        Vacancy.endDateTimeDefault = DateTime.parse(vacancy['endDateTime']);
        Vacancy.descriptionDefault = vacancy['description'];
      }
      vacancies[id] = Vacancy(
          id: id,
          name: vacancy['name'],
          startDateTime: DateTime.parse(vacancy['startDateTime']),
          endDateTime: DateTime.parse(vacancy['endDateTime']),
          description: vacancy['description']);
    });
    return this;
  }

  @override
  Map toJson() => {
        DataType.shift.name: shifts
            .map<String, Map>((id, value) => MapEntry(id, value.toJson())),
        DataType.member.name: members
            .map<String, Map>((id, value) => MapEntry(id, value.toJson())),
        DataType.work.name:
            works.map<String, Map>((id, value) => MapEntry(id, value.toJson())),
        DataType.vacancy.name: vacancies
            .map<String, Map>((id, value) => MapEntry(id, value.toJson())),
      };
}

class Member implements DataObject {
  static String nameDefault = 'Unnamed';
  static double preloadDefault = 0;
  static List<String> vacancyIDsDefault = [];
  static String descriptionDefault = "";

  final String id;
  String name;
  double preload = 0;
  List<String> vacancyIDs;
  String description;

  double previousToTalLoad = 0;
  double previousLoad = 0;
  DateTime previousLoadEndDateTime = DateTime(1970);

  Member(
      {required this.id,
      required this.name,
      required this.vacancyIDs,
      this.preload = 0,
      this.description = ""});

  Member.fromDefault({required this.id})
      : name = nameDefault,
        vacancyIDs = List.from(vacancyIDsDefault),
        preload = preloadDefault,
        description = descriptionDefault;

  bool isAvailable(List<Vacancy> vacancies, DateTime dateTime) {
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

  @override
  Map<String, dynamic> toJson() => {
        'name': name,
        'preload': preload,
        'vacancyIDs': vacancyIDs,
        'description': description,
      };
}

class Vacancy implements DataObject {
  static String nameDefault = "Unnamed";
  static DateTime startDateTimeDefault = DateTime.now();
  static DateTime endDateTimeDefault = DateTime.now();
  static String descriptionDefault = "";

  final String id;
  String name;
  DateTime startDateTime;
  DateTime endDateTime;
  String description;

  Vacancy(
      {required this.id,
      required this.name,
      required this.startDateTime,
      required this.endDateTime,
      this.description = ""});

  Vacancy.fromDefault({required this.id})
      : name = nameDefault,
        startDateTime = startDateTimeDefault,
        endDateTime = endDateTimeDefault,
        description = descriptionDefault;

  Duration get duration {
    return endDateTime.difference(startDateTime);
  }

  bool include(DateTime dateTime) {
    return (startDateTime.isBefore(dateTime) ||
            startDateTime.isAtSameMomentAs(dateTime)) &&
        (endDateTime.isAfter(dateTime) ||
            endDateTime.isAtSameMomentAs(dateTime));
  }

  @override
  Map<String, dynamic> toJson() => {
        'name': name,
        'startDateTime': startDateTime.toString(),
        'endDataTime': endDateTime.toString(),
        'description': description,
      };
}

class Shift implements DataObject {
  static String titleDefault = "Untitled";
  static List<String> memberIDsDefault = [];
  static List<String> workIDsDefault = [];
  static String descriptionDefault = "";

  final String id;
  String title;
  List<String> memberIDs;
  List<String> workIDs;
  String description;

  Shift(
      {required this.id,
      required this.title,
      required this.memberIDs,
      required this.workIDs,
      this.description = ""});

  Shift.fromDefault({required this.id})
      : title = titleDefault,
        memberIDs = List.from(memberIDsDefault),
        workIDs = List.from(workIDsDefault),
        description = descriptionDefault;

  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'memberIDs': memberIDs,
        'workIDs': workIDs,
        'description': description,
      };
}

class Work implements DataObject {
  static String nameDefault = "Unnamed";
  static double loadDefault = 0;
  static List<String> fixedMemberIDsDefault = [];
  static List<String> memberIDsDefault = [];
  static String descriptionDefault = "";

  final String id;
  String name;
  double load;
  List<String> fixedMemberIDs;
  List<String> memberIDs;
  String description;

  Work(
      {required this.id,
      required this.name,
      required this.load,
      required this.fixedMemberIDs,
      required this.memberIDs,
      this.description = ""});

  Work.fromDefault({required this.id})
      : name = nameDefault,
        load = loadDefault,
        fixedMemberIDs = List.from(fixedMemberIDsDefault),
        memberIDs = List.from(memberIDsDefault),
        description = "";

  @override
  Map<String, dynamic> toJson() => {
        'name': name,
        'load': load,
        'fixedMemberIDs': fixedMemberIDs,
        'memberIDs': memberIDs,
        'description': description,
      };
}

String genId() {
  final id = DateTime.now().millisecondsSinceEpoch.toString();
  return id;
}
