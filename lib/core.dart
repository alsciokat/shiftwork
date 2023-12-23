import 'dart:math';

const defaultId = 'default';
const defaultTempId = 'temp';

enum DataType {
  shift,
  member,
  work,
  vacancy,
  group,
}

// Used for every DataType
String genId() {
  final id = DateTime.now().millisecondsSinceEpoch.toString();
  return id;
}

class ShiftWorkError extends Error {
  String description;
  ShiftWorkError(String? description)
      : description = description ?? 'Something went wrong 😢';
}

abstract class IObject {
  static String nameDefault = 'Unnamed';
  final String id;
  String name;

  IObject({required this.id}) : name = nameDefault;

  dynamic toJson();
  IObject create({required String id});
}

// A wrapper object for each DataType
class ObjectData {
  static List<String> objectOrderDefault = [];
  static Map<String, IObject> objectMapDefault = {};
  IObject tempObject;

  List<String> objectOrder;
  IObject defaultObject;
  Map<String, IObject> objectMap;

  ObjectData(
      {required this.defaultObject,
      List<String>? objectOrder,
      Map<String, IObject>? objectMap})
      : objectOrder = objectOrder ?? List.from(objectOrderDefault),
        objectMap = objectMap ?? Map.from(objectMapDefault),
        tempObject = defaultObject.create(id: 'temp');

  IObject create(String id) {
    objectMap[id] = defaultObject.create(id: id);
    objectOrder.add(id);
    return objectMap[id]!;
  }

  IObject getTemp(String id) {
    tempObject = defaultObject.create(id: id);
    return tempObject;
  }

  ObjectData saveTemp() {
    objectMap[tempObject.id] = tempObject;
    objectOrder.add(tempObject.id);
    return this;
  }

  IObject getById(String id) {
    if (!objectMap.keys.contains(id)) {
      throw RangeError('getById: Given Id is not present!');
    }
    return objectMap[id]!;
  }

  IObject getByOrder(int index) {
    if (index >= objectOrder.length) {
      throw IndexError.withLength(index, objectOrder.length);
    }
    return getById(objectOrder[index]);
  }

  String getName(String id) {
    if (!objectMap.keys.contains(id)) {
      throw RangeError('getName: Given Id is not present!');
    }
    return objectMap[id]!.name;
  }

  Map toJson() => {
        'objectOrder': objectOrder,
        defaultId: defaultObject.toJson(),
        'objectIds': objectMap
            .map<String, Map>((id, value) => MapEntry(id, value.toJson())),
      };
}

// The model of the entire database
class Data {
  ObjectData shiftData;
  ObjectData memberData;
  ObjectData groupData;
  ObjectData workData;
  ObjectData vacancyData;

  Data(
      {required this.shiftData,
      required this.memberData,
      required this.groupData,
      required this.workData,
      required this.vacancyData});

  Data.fromDefault()
      : shiftData = ObjectData(defaultObject: Shift(id: defaultId)),
        memberData = ObjectData(defaultObject: Member(id: defaultId)),
        groupData = ObjectData(defaultObject: Group(id: defaultId)),
        workData = ObjectData(defaultObject: Work(id: defaultId)),
        vacancyData = ObjectData(defaultObject: Vacancy(id: defaultId));

  Data updateAll(Map<String, Map> dataJson) {
    dataJson[DataType.shift.name]?.forEach((key, json) {
      if (key == 'objectOrder') {
        shiftData.objectOrder = json;
      } else if (key == defaultId) {
        Shift.setDefault(json);
        shiftData.defaultObject = Shift.fromJson(defaultId, json);
      } else if (key == 'objectIds') {
        json.forEach((id, shiftJson) {
          shiftData.objectMap[id] = Shift.fromJson(id, shiftJson);
        });
      }
    });
    dataJson[DataType.member.name]?.forEach((key, json) {
      if (key == 'objectOrder') {
        memberData.objectOrder = json;
      } else if (key == defaultId) {
        Member.setDefault(json);
        memberData.defaultObject = Member.fromJson(defaultId, json);
      } else if (key == 'objectIds') {
        json.forEach((id, memberJson) {
          memberData.objectMap[id] = Member.fromJson(id, memberJson);
        });
      }
    });
    dataJson[DataType.group.name]?.forEach((key, json) {
      if (key == 'objectOrder') {
        groupData.objectOrder = json;
      } else if (key == defaultId) {
        Group.setDefault(json);
        groupData.defaultObject = Group.fromJson(defaultId, json);
      } else if (key == 'objectIds') {
        json.forEach((id, groupJson) {
          groupData.objectMap[id] = Group.fromJson(id, groupJson);
        });
      }
    });
    dataJson[DataType.work.name]?.forEach((key, json) {
      if (key == 'objectOrder') {
        workData.objectOrder = json;
      } else if (key == defaultId) {
        Work.setDefault(json);
        workData.defaultObject = Work.fromJson(defaultId, json);
      } else if (key == 'objectIds') {
        json.forEach((id, workJson) {
          workData.objectMap[id] = Work.fromJson(id, workJson);
        });
      }
    });
    dataJson[DataType.vacancy.name]?.forEach((key, json) {
      if (key == 'objectOrder') {
        vacancyData.objectOrder = json;
      } else if (key == defaultId) {
        Vacancy.setDefault(json);
        vacancyData.defaultObject = Vacancy.fromJson(defaultId, json);
      } else if (key == 'objectIds') {
        json.forEach((id, vacancyJson) {
          vacancyData.objectMap[id] = Vacancy.fromJson(id, vacancyJson);
        });
      }
    });
    return this;
  }

  Map toJson() => {
        DataType.shift.name: shiftData.toJson(),
        DataType.member.name: memberData.toJson(),
        DataType.group.name: groupData.toJson(),
        DataType.work.name: workData.toJson(),
        DataType.vacancy.name: vacancyData.toJson(),
      };
}

class Shift implements IObject {
  static String nameDefault = "Untitled";
  static List<String> memberIdsDefault = [];
  static List<String> groupIdsDefault = [];
  static List<String> workIdsDefault = [];
  static Leniency fixedMemberLeniencyDefault = Leniency.force;
  static Leniency fixedGroupLeniencyDefault = Leniency.recommend;
  static Leniency maximumAvailableLeniencyDefault = Leniency.force;
  static String descriptionDefault = "";

  @override
  final String id;
  @override
  String name;
  List<String> memberIds;
  List<String> groupIds;
  List<String> workIds;

  Leniency fixedMemberLeniency;
  Leniency fixedGroupLeniency;
  Leniency maximumAvailableLeniency;
  String description;

  Shift(
      {required this.id,
      String? title,
      List<String>? memberIds,
      List<String>? groupIds,
      List<String>? workIDs,
      Leniency? fixedMemberLeniency,
      Leniency? fixedGroupLeniency,
      Leniency? maximumAvailableLeniency,
      String? description})
      : name = title ?? nameDefault,
        memberIds = memberIds ?? List.from(memberIdsDefault),
        groupIds = groupIds ?? List.from(groupIdsDefault),
        workIds = workIDs ?? List.from(workIdsDefault),
        fixedMemberLeniency = fixedMemberLeniency ?? fixedGroupLeniencyDefault,
        fixedGroupLeniency = fixedGroupLeniency ?? fixedGroupLeniencyDefault,
        maximumAvailableLeniency =
            maximumAvailableLeniency ?? maximumAvailableLeniencyDefault,
        description = description ?? descriptionDefault;

  @override
  Shift create({required String id}) {
    return Shift(id: id);
  }

  static setDefault(Map<String, dynamic> shiftJson) {
    nameDefault = shiftJson['title'];
    memberIdsDefault = shiftJson['memberIds'];
    groupIdsDefault = shiftJson['groupIds'];
    workIdsDefault = shiftJson['workIds'];
    fixedMemberLeniencyDefault =
        Leniency.values[shiftJson['fixedMemberLeniency']];
    fixedGroupLeniencyDefault =
        Leniency.values[shiftJson['fixedGroupLeniency']];
    maximumAvailableLeniencyDefault =
        Leniency.values[shiftJson['maximumAvailableLeniency']];
    descriptionDefault = shiftJson['description'];
  }

  Shift.fromJson(this.id, Map<String, dynamic> shiftJson)
      : name = shiftJson['title'] ?? nameDefault,
        memberIds = shiftJson['memberIds'] ?? List.from(memberIdsDefault),
        groupIds = shiftJson['groupIds'] ?? List.from(groupIdsDefault),
        workIds = shiftJson['workIds'] ?? List.from(workIdsDefault),
        fixedMemberLeniency = Leniency.values[
            shiftJson['fixedMemberLeniency'] ??
                fixedMemberLeniencyDefault.index],
        fixedGroupLeniency = Leniency.values[
            shiftJson['fixedGroupLeniency'] ?? fixedGroupLeniencyDefault.index],
        maximumAvailableLeniency = Leniency.values[
            shiftJson['maximumAvailableLeniency'] ??
                maximumAvailableLeniencyDefault.index],
        description = shiftJson['description'] ?? descriptionDefault;

  @override
  Map<String, dynamic> toJson() => {
        'title': name,
        'memberIds': memberIds,
        'groupIds': groupIds,
        'workIds': workIds,
        'fixedMemberLeniency': fixedMemberLeniency.index,
        'fixedGroupLeniency': fixedGroupLeniency.index,
        'maximumAvailableLeniency': maximumAvailableLeniency.index,
        'description': description,
      };
}

// weight of fatigue just after the work finished
double initialWeight = 2;

// the attenuation time of fatigue in minutes
double tau = 60;

enum GetLoadScheme { plain, fatigue }

class Member implements IObject {
  static String nameDefault = 'Unnamed';
  static double preloadDefault = 0;
  static List<String> vacancyIdsDefault = [];
  static String descriptionDefault = "";

  @override
  final String id;
  @override
  String name;
  double preload = 0;
  List<String> vacancyIds;
  String description;

  double previousTotalLoad = 0;
  double previousLoad = 0;
  DateTime previousLoadEndDateTime = DateTime(0);

  double availablity = 1;

  Member(
      {required this.id,
      String? name,
      List<String>? vacancyIds,
      double? preload,
      String? description})
      : name = name ?? nameDefault,
        vacancyIds = vacancyIds ?? List.from(vacancyIdsDefault),
        preload = preload ?? preloadDefault,
        description = description ?? descriptionDefault;

  @override
  Member create({required String id}) {
    return Member(id: id);
  }

  double getLoad(
      {GetLoadScheme scheme = GetLoadScheme.plain,
      DateTime? workStartDateTime}) {
    if (scheme == GetLoadScheme.plain) {
      return previousTotalLoad + previousLoad;
    }
    if (scheme == GetLoadScheme.fatigue) {
      if (workStartDateTime == null) {
        throw ShiftWorkError(
            '@param workStartTime is required when GetLoadScheme.fatigue is used in getLoad method');
      }
      return _calculateLoad(
          workStartDateTime.difference(previousLoadEndDateTime));
    }
    throw ShiftWorkError('$scheme is not implemented');
  }

  void addLoad(double load, {DateTime? at}) {
    previousTotalLoad += previousLoad;
    previousLoad = load;
    previousLoadEndDateTime = at ?? previousLoadEndDateTime;
  }

  double _calculateLoad(Duration duration) {
    return previousTotalLoad + previousLoad * weight(duration.inMinutes);
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

  static setDefault(Map<String, dynamic> memberJson) {
    nameDefault = memberJson['name'];
    preloadDefault = memberJson['preload'];
    vacancyIdsDefault = memberJson['vacancyIds'];
    descriptionDefault = memberJson['description'];
  }

  Member.fromJson(this.id, Map<String, dynamic> memberJson)
      : name = memberJson['name'] ?? nameDefault,
        preload = memberJson['preload'] ?? preloadDefault,
        vacancyIds = memberJson['vacancyIds'] ?? List.from(vacancyIdsDefault),
        description = memberJson['description'] ?? descriptionDefault;

  @override
  Map<String, dynamic> toJson() => {
        'name': name,
        'preload': preload,
        'vacancyIds': vacancyIds,
        'description': description,
      };
}

class Group implements IObject {
  static String nameDefault = 'Unnamed';
  static List<String> memberIdsDefault = [];
  static int maximumAvailableDefault = -1;
  static Leniency maximumAvailableLeniencyDefault = Leniency.inherit;
  static String descriptionDefault = '';

  @override
  final String id;
  @override
  String name;
  int maximumAvailable;
  Leniency maximumAvailableLeniency;
  String description;

  List<String> memberIds;

  int availableNow = 0;

  Group(
      {required this.id,
      String? name,
      List<String>? memberIds,
      int? maximumAvailable,
      Leniency? maximumAvailableLeniency,
      String? description})
      : name = name ?? nameDefault,
        memberIds = memberIds ?? memberIdsDefault,
        maximumAvailable = maximumAvailable ?? maximumAvailableDefault,
        maximumAvailableLeniency =
            maximumAvailableLeniency ?? maximumAvailableLeniencyDefault,
        description = description ?? descriptionDefault;

  @override
  Group create({required String id}) {
    return Group(id: id);
  }

  static setDefault(Map<String, dynamic> groupJson) {
    nameDefault = groupJson['name'];
    memberIdsDefault = groupJson['memberIds'];
    maximumAvailableDefault = groupJson['maximumAvailable'];
    maximumAvailableLeniencyDefault =
        Leniency.values[groupJson['maximumAvailableLeniency']];
    descriptionDefault = groupJson['description'];
  }

  Group.fromJson(this.id, Map<String, dynamic> groupJson)
      : name = groupJson['name'] ?? nameDefault,
        memberIds = groupJson['memberIds'] ?? List.from(memberIdsDefault),
        maximumAvailable =
            groupJson['maximumAvailable'] ?? maximumAvailableDefault,
        maximumAvailableLeniency = Leniency.values[
            groupJson['maximumAvailableLeniency'] ??
                maximumAvailableLeniencyDefault.index],
        description = groupJson['description'] ?? descriptionDefault;

  @override
  Map<String, dynamic> toJson() => {
        'name': name,
        'memberIds': memberIds,
        'maximumAvailable': maximumAvailable,
        'maximumAvailableLeniency': maximumAvailableLeniency.index,
        'description': description,
      };
}

enum Leniency { inherit, force, recommend }

class Work implements IObject {
  static String nameDefault = "Unnamed";
  static double loadDefault = 1;
  static int numberOfMembersNeededDefault = 1;
  static List<String> fixedMemberIdsDefault = [];
  static Leniency fixedMemberLeniencyDefault = Leniency.inherit;
  static List<String> fixedGroupIdsDefault = [];
  static Leniency fixedGroupLeniencyDefault = Leniency.inherit;
  static List<String> memberIdsDefault = [];
  static String descriptionDefault = "";
  static DateTime startDateTimeDefault = DateTime.now();
  static DateTime endDateTimeDefault = DateTime.now();

  @override
  final String id;

  @override
  String name;

  double load;
  int numberOfMembersNeeded;
  DateTime startDateTime;
  DateTime endDateTime;

  List<String> fixedMemberIds;
  Leniency fixedMemberLeniency;
  List<String> fixedGroupIds;
  Leniency fixedGroupLeniency;

  List<String> memberIds;
  String description;

  Work(
      {required this.id,
      String? name,
      double? load,
      int? numberOfMemberNeeded,
      DateTime? startDateTime,
      DateTime? endDateTime,
      List<String>? fixedMemberIds,
      Leniency? fixedMemberLeniency,
      List<String>? fixedGroupIds,
      Leniency? fixedGroupLeniency,
      List<String>? memberIds,
      String? description = ""})
      : name = name ?? nameDefault,
        load = load ?? loadDefault,
        numberOfMembersNeeded =
            numberOfMemberNeeded ?? numberOfMembersNeededDefault,
        startDateTime = startDateTime ?? startDateTimeDefault,
        endDateTime = endDateTime ?? endDateTimeDefault,
        fixedMemberIds = fixedMemberIds ?? List.from(fixedMemberIdsDefault),
        fixedMemberLeniency = fixedMemberLeniency ?? fixedMemberLeniencyDefault,
        fixedGroupIds = fixedGroupIds ?? List.from(fixedGroupIdsDefault),
        fixedGroupLeniency = fixedGroupLeniency ?? fixedGroupLeniencyDefault,
        memberIds = memberIds ?? List.from(memberIdsDefault),
        description = description ?? descriptionDefault;

  @override
  Work create({required String id}) {
    return Work(id: id);
  }

  static setDefault(Map<String, dynamic> workJson) {
    nameDefault = workJson['name'];
    loadDefault = workJson['load'];
    numberOfMembersNeededDefault = workJson['numberOfMembersNeeded'];
    startDateTimeDefault = DateTime.parse(workJson['startDateTime']);
    endDateTimeDefault = DateTime.parse(workJson['endDateTime']);
    fixedMemberIdsDefault = workJson['fixedMemberIds'];
    fixedMemberLeniencyDefault =
        Leniency.values[workJson['fixedMemberLeniency']];
    fixedGroupIdsDefault = workJson['fixedGroupIds'];
    fixedGroupLeniencyDefault = Leniency.values[workJson['fixedGroupLeniency']];
    memberIdsDefault = workJson['memberIds'];
    descriptionDefault = workJson['description'];
  }

  Work.fromJson(this.id, Map<String, dynamic> workJson)
      : name = workJson['name'] ?? nameDefault,
        load = workJson['load'] ?? loadDefault,
        numberOfMembersNeeded =
            workJson['numberOfMembersNeeded'] ?? numberOfMembersNeededDefault,
        startDateTime = DateTime.parse(workJson['startDateTime']),
        endDateTime = DateTime.parse(workJson['endDateTime']),
        fixedMemberIds =
            workJson['fixedMemberIds'] ?? List.from(fixedMemberIdsDefault),
        fixedMemberLeniency = Leniency.values[workJson['fixedMemberLeniency'] ??
            fixedMemberLeniencyDefault.index],
        fixedGroupIds =
            workJson['fixedGroupIds'] ?? List.from(fixedGroupIdsDefault),
        fixedGroupLeniency = Leniency.values[
            workJson['fixedGroupLeniency'] ?? fixedGroupLeniencyDefault.index],
        memberIds = workJson['memberIds'] ?? List.from(memberIdsDefault),
        description = workJson['description'] ?? descriptionDefault;

  @override
  Map<String, dynamic> toJson() => {
        'name': name,
        'load': load,
        'numberOfMembersNeeded': numberOfMembersNeeded,
        'startDateTime': startDateTime.toString(),
        'endDateTime': endDateTime.toString(),
        'fixedMemberIds': fixedMemberIds,
        'fixedfixedMemberLeniency': fixedMemberLeniency.index,
        'fixedGroupIds': fixedGroupIds,
        'fixedGroupLeniency': fixedGroupLeniency.index,
        'memberIds': memberIds,
        'description': description,
      };
}

class Vacancy implements IObject {
  static String nameDefault = "Unnamed";
  static DateTime startDateTimeDefault =
      DateTime.now().copyWith(hour: 0, minute: 0);
  static DateTime endDateTimeDefault =
      DateTime.now().copyWith(hour: 0, minute: 0).add(const Duration(days: 1));
  static bool isPaidDefault = false;
  static String descriptionDefault = "";

  @override
  final String id;
  @override
  String name;
  DateTime startDateTime;
  DateTime endDateTime;
  bool isPaid;
  String description;

  Vacancy(
      {required this.id,
      String? name,
      DateTime? startDateTime,
      DateTime? endDateTime,
      bool? isPaid,
      String? description})
      : name = name ?? nameDefault,
        startDateTime = startDateTime ?? startDateTimeDefault,
        endDateTime = endDateTime ?? endDateTimeDefault,
        isPaid = isPaid ?? isPaidDefault,
        description = description ?? descriptionDefault;

  @override
  Vacancy create({required String id}) {
    return Vacancy(id: id);
  }

  Duration get duration {
    return endDateTime.difference(startDateTime);
  }

  bool include(DateTime dateTime) {
    return (startDateTime.isBefore(dateTime) ||
            startDateTime.isAtSameMomentAs(dateTime)) &&
        (endDateTime.isAfter(dateTime) ||
            endDateTime.isAtSameMomentAs(dateTime));
  }

  static setDefault(Map<String, dynamic> vacancyJson) {
    nameDefault = vacancyJson['name'];
    startDateTimeDefault = DateTime.parse(vacancyJson['startDateTime']);
    endDateTimeDefault = DateTime.parse(vacancyJson['endDateTime']);
    isPaidDefault = vacancyJson['isPaid'];
    descriptionDefault = vacancyJson['description'];
  }

  Vacancy.fromJson(this.id, Map<String, dynamic> vacancyJson)
      : name = vacancyJson['name'] ?? nameDefault,
        startDateTime = DateTime.parse(vacancyJson['startDateTime']),
        endDateTime = DateTime.parse(vacancyJson['endDateTime']),
        isPaid = vacancyJson['isPaid'],
        description = vacancyJson['description'] ?? descriptionDefault;

  @override
  Map<String, dynamic> toJson() => {
        'name': name,
        'startDateTime': startDateTime.toString(),
        'endDataTime': endDateTime.toString(),
        'isPaid': isPaid,
        'description': description,
      };
}
