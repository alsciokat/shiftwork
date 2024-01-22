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

class DateTimeInterval {
  DateTime _start;
  DateTime _end;
  bool allowZeroInterval = false;

  DateTimeInterval(DateTime start, DateTime end,
      {this.allowZeroInterval = false})
      : _start = start,
        _end = end;

  DateTime get start {
    return _start;
  }

  DateTime get end {
    return _end;
  }

  set start(DateTime value) {
    if (value.isAfter(_end) ||
        (value.isAtSameMomentAs(_end) && !allowZeroInterval)) {
      Duration intervalLength = _end.difference(_start);
      _end = value.add(intervalLength);
    }
    _start = value;
  }

  set end(DateTime value) {
    if (value.isBefore(_start) ||
        (value.isAtSameMomentAs(_start) && !allowZeroInterval)) {
      Duration intervalLength = _end.difference(_start);
      _start = value.subtract(intervalLength);
    }
    _end = value;
  }

  Duration get duration {
    return _end.difference(_start);
  }

  bool intersect(DateTimeInterval other) {
    if (((other._start.isAfter(_start) ||
                other._start.isAtSameMomentAs(_start)) &&
            other._start.isBefore(_end)) ||
        (other._start.isBefore(_start) && other._end.isAfter(_start))) {
      return true;
    }
    return false;
  }
}

class ShiftWorkError extends Error {
  String description;
  ShiftWorkError(String? description)
      : description = description ?? 'Something went wrong 😢';
}

abstract class IObject {
  static String nameDefault = 'Unnamed';
  final String id;

  IObject({required this.id});

  IObject fromJson(String id, Map<String, dynamic> objectJson);

  dynamic toJson();
  IObject create({required String id});
}

// A wrapper object for each DataType
class ObjectData<T extends IObject> {
  T tempObject;

  List<String> objectOrder;
  T defaultObject;
  Map<String, T> objectMap;

  ObjectData({
    required this.defaultObject,
    required this.objectOrder,
    required this.objectMap,
  }) : tempObject = defaultObject.create(id: defaultId) as T;

  T create(String id) {
    objectMap[id] = defaultObject.create(id: id) as T;
    objectOrder.add(id);
    return objectMap[id]!;
  }

  T getTemp(String id) {
    tempObject = defaultObject.create(id: id) as T;
    return tempObject;
  }

  ObjectData saveTemp() {
    objectMap[tempObject.id] = tempObject;
    objectOrder.add(tempObject.id);
    return this;
  }

  T getById(String id) {
    if (!objectMap.keys.contains(id)) {
      throw RangeError('getById: Given Id is not present!');
    }
    return objectMap[id]!;
  }

  T getByOrder(int index) {
    if (index >= objectOrder.length) {
      throw IndexError.withLength(index, objectOrder.length);
    }
    return getById(objectOrder[index]);
  }

  ObjectData.fromJson(
      {required T defaultObject, required Map<String, dynamic> objectJson})
      : defaultObject =
            defaultObject.fromJson(defaultId, objectJson[defaultId]) as T,
        objectOrder = List<String>.from(objectJson['objectOrder']),
        objectMap = Map<String, T>.from(objectJson['objectIds'].map((id,
                value) =>
            MapEntry<String, T>(id, defaultObject.fromJson(id, value) as T))),
        tempObject = defaultObject.create(id: defaultId) as T;

  Map toJson() => {
        'objectOrder': objectOrder,
        defaultId: defaultObject.toJson(),
        'objectIds': objectMap
            .map<String, Map>((id, value) => MapEntry(id, value.toJson())),
      };
}

// The model of the entire database
class Data {
  late ObjectData<Shift> shiftData;
  late ObjectData<Member> memberData;
  late ObjectData<Group> groupData;
  late ObjectData<Work> workData;
  late ObjectData<Vacancy> vacancyData;

  Data(
      {required this.shiftData,
      required this.memberData,
      required this.groupData,
      required this.workData,
      required this.vacancyData});

  Data.fromDefault()
      : shiftData = ObjectData<Shift>(
            defaultObject: Shift(id: defaultId),
            objectOrder: [],
            objectMap: {}),
        memberData = ObjectData<Member>(
            defaultObject: Member(id: defaultId),
            objectOrder: [],
            objectMap: {}),
        groupData = ObjectData<Group>(
            defaultObject: Group(id: defaultId),
            objectOrder: [],
            objectMap: {}),
        workData = ObjectData<Work>(
            defaultObject: Work(id: defaultId), objectOrder: [], objectMap: {}),
        vacancyData = ObjectData<Vacancy>(
            defaultObject: Vacancy(id: defaultId),
            objectOrder: [],
            objectMap: {});

  Data.fromJson(Map<String, dynamic> dataJson) {
    Map<String, dynamic>? metaShiftJson = dataJson[DataType.shift.name];
    if (metaShiftJson != null) {
      Shift.setDefault(metaShiftJson[defaultId]);
      shiftData = ObjectData<Shift>.fromJson(
          defaultObject: Shift(id: defaultId), objectJson: metaShiftJson);
    }

    Map<String, dynamic>? metaMemberJson = dataJson[DataType.member.name];
    if (metaMemberJson != null) {
      Member.setDefault(metaMemberJson[defaultId]);
      memberData = ObjectData<Member>.fromJson(
          defaultObject: Member(id: defaultId), objectJson: metaMemberJson);
    }
    Map<String, dynamic>? metaGroupJson = dataJson[DataType.group.name];
    if (metaGroupJson != null) {
      Group.setDefault(metaGroupJson[defaultId]);
      groupData = ObjectData<Group>.fromJson(
          defaultObject: Group(id: defaultId), objectJson: metaGroupJson);
    }

    Map<String, dynamic>? metaWorkJson = dataJson[DataType.work.name];

    if (metaWorkJson != null) {
      Work.setDefault(metaWorkJson[defaultId]);
      workData = ObjectData<Work>.fromJson(
          defaultObject: Work(id: defaultId), objectJson: metaWorkJson);
    }
    Map<String, dynamic>? metaVacancyJson = dataJson[DataType.vacancy.name];
    if (metaVacancyJson != null) {
      Vacancy.setDefault(metaVacancyJson[defaultId]);
      vacancyData = ObjectData<Vacancy>.fromJson(
          defaultObject: Vacancy(id: defaultId), objectJson: metaVacancyJson);
    }
  }

  Map toJson() => {
        DataType.shift.name: shiftData.toJson(),
        DataType.member.name: memberData.toJson(),
        DataType.group.name: groupData.toJson(),
        DataType.work.name: workData.toJson(),
        DataType.vacancy.name: vacancyData.toJson(),
      };
}

class Shift extends IObject {
  static String nameDefault = "Untitled";
  static List<String> memberIdsDefault = [];
  static List<String> groupIdsDefault = [];
  static List<String> workIdsDefault = [];
  static Leniency fixedMemberLeniencyDefault = Leniency.force;
  static Leniency fixedGroupLeniencyDefault = Leniency.recommend;
  static Leniency excludedMemberLeniencyDefault = Leniency.force;
  static Leniency excludedGroupLeniencyDefault = Leniency.recommend;
  static Leniency maximumAvailableLeniencyDefault = Leniency.force;
  static String descriptionDefault = "";

  String title;
  List<String> memberIds;
  List<String> groupIds;
  List<String> workIds;

  Leniency fixedMemberLeniency;
  Leniency fixedGroupLeniency;
  Leniency excludedMemberLeniency;
  Leniency excludedGroupLeniency;
  Leniency maximumAvailableLeniency;
  bool shuffleMembers;
  String description;
  bool created = false;

  Shift(
      {required super.id,
      String? title,
      List<String>? memberIds,
      List<String>? groupIds,
      List<String>? workIds,
      Leniency? fixedMemberLeniency,
      Leniency? fixedGroupLeniency,
      Leniency? excludedMemberLeniency,
      Leniency? excludedGroupLeniency,
      Leniency? maximumAvailableLeniency,
      bool? shuffleMembers,
      String? description})
      : title = title ?? nameDefault,
        memberIds = memberIds ?? List.from(memberIdsDefault),
        groupIds = groupIds ?? List.from(groupIdsDefault),
        workIds = workIds ?? List.from(workIdsDefault),
        fixedMemberLeniency = fixedMemberLeniency ?? fixedMemberLeniencyDefault,
        fixedGroupLeniency = fixedGroupLeniency ?? fixedGroupLeniencyDefault,
        excludedMemberLeniency =
            excludedMemberLeniency ?? excludedMemberLeniencyDefault,
        excludedGroupLeniency =
            excludedGroupLeniency ?? excludedGroupLeniencyDefault,
        maximumAvailableLeniency =
            maximumAvailableLeniency ?? maximumAvailableLeniencyDefault,
        shuffleMembers = shuffleMembers ?? true,
        description = description ?? descriptionDefault;

  @override
  Shift create({required String id}) {
    return Shift(id: id);
  }

  static setDefault(Map<String, dynamic> shiftJson) {
    nameDefault = shiftJson['title'];
    memberIdsDefault = List<String>.from(shiftJson['memberIds']);
    groupIdsDefault = List<String>.from(shiftJson['groupIds']);
    workIdsDefault = List<String>.from(shiftJson['workIds']);
    fixedMemberLeniencyDefault =
        Leniency.values[shiftJson['fixedMemberLeniency']];
    fixedGroupLeniencyDefault =
        Leniency.values[shiftJson['fixedGroupLeniency']];
    excludedMemberLeniencyDefault = Leniency.values[
        shiftJson['excludedMemberLeniency'] ??
            excludedMemberLeniencyDefault.index];
    excludedGroupLeniencyDefault = Leniency.values[
        shiftJson['excludedGroupLeniency'] ??
            excludedGroupLeniencyDefault.index];
    maximumAvailableLeniencyDefault =
        Leniency.values[shiftJson['maximumAvailableLeniency']];
    descriptionDefault = shiftJson['description'];
  }

  @override
  Shift fromJson(String id, Map<String, dynamic> objectJson) {
    Shift newShift = Shift(
      id: id,
      title: objectJson['title'] ?? nameDefault,
      memberIds: List<String>.from(objectJson['memberIds'] ?? memberIdsDefault),
      groupIds: List<String>.from(objectJson['groupIds'] ?? groupIdsDefault),
      workIds: List<String>.from(objectJson['workIds'] ?? workIdsDefault),
      fixedMemberLeniency: Leniency.values[objectJson['fixedMemberLeniency'] ??
          fixedMemberLeniencyDefault.index],
      fixedGroupLeniency: Leniency.values[
          objectJson['fixedGroupLeniency'] ?? fixedGroupLeniencyDefault.index],
      excludedMemberLeniency: Leniency.values[
          objectJson['excludedMemberLeniency'] ??
              excludedMemberLeniencyDefault.index],
      excludedGroupLeniency: Leniency.values[
          objectJson['excludedGroupLeniency'] ??
              excludedGroupLeniencyDefault.index],
      maximumAvailableLeniency: Leniency.values[
          objectJson['maximumAvailableLeniency'] ??
              maximumAvailableLeniencyDefault.index],
      shuffleMembers: objectJson['shuffleMembers'],
      description: objectJson['description'] ?? descriptionDefault,
    );
    newShift.created = objectJson['created'] ?? false;
    return newShift;
  }

  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'memberIds': memberIds,
        'groupIds': groupIds,
        'workIds': workIds,
        'fixedMemberLeniency': fixedMemberLeniency.index,
        'fixedGroupLeniency': fixedGroupLeniency.index,
        'excludedMemberLeniency': excludedMemberLeniency.index,
        'excludedGroupLeniency': excludedGroupLeniency.index,
        'maximumAvailableLeniency': maximumAvailableLeniency.index,
        'shuffleMembers': shuffleMembers,
        'description': description,
        'created': created,
      };
}

// weight of fatigue just after the work finished
double initialWeight = 2;

// the attenuation time of fatigue in minutes
double tau = 60;

enum GetLoadScheme { plain, fatigue }

class Member extends IObject {
  static String nameDefault = 'Unnamed';
  static double preloadDefault = 0;
  static List<String> vacancyIdsDefault = [];
  static String descriptionDefault = "";

  String name;
  double preload = 0;
  List<String> vacancyIds;
  String description;

  double previousTotalLoad = 0;
  double previousLoad = 0;

  double availablity = 1;
  List<DateTimeInterval> assignedIntervals = [];

  Member(
      {required super.id,
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
      return preload + previousTotalLoad + previousLoad;
    }
    if (scheme == GetLoadScheme.fatigue) {
      if (workStartDateTime == null) {
        throw ShiftWorkError(
            '@param workStartTime is required when GetLoadScheme.fatigue is used in getLoad method');
      }
      DateTime previousLoadEndDateTime =
          assignedIntervals.fold(DateTime(0), (dateTime, interval) {
        if (interval.end.isAfter(workStartDateTime)) {
          return dateTime;
        } else if (interval.end.isAfter(dateTime)) {
          return interval.end;
        } else {
          return dateTime;
        }
      });
      return _calculateLoad(
          workStartDateTime.difference(previousLoadEndDateTime));
    }
    throw ShiftWorkError('$scheme is not implemented');
  }

  void addLoad(double load) {
    previousTotalLoad += previousLoad;
    previousLoad = load;
  }

  double _calculateLoad(Duration duration) {
    return preload +
        previousTotalLoad +
        previousLoad * weight(duration.inMinutes);
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
    vacancyIdsDefault = List<String>.from(memberJson['vacancyIds']);
    descriptionDefault = memberJson['description'];
  }

  @override
  Member fromJson(String id, Map<String, dynamic> objectJson) {
    return Member(
      id: id,
      name: objectJson['name'] ?? nameDefault,
      preload: objectJson['preload'] ?? preloadDefault,
      vacancyIds:
          List<String>.from(objectJson['vacancyIds'] ?? vacancyIdsDefault),
      description: objectJson['description'] ?? descriptionDefault,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'name': name,
        'preload': preload,
        'vacancyIds': vacancyIds,
        'description': description,
      };
}

class Group extends IObject {
  static String nameDefault = 'Unnamed';
  static List<String> memberIdsDefault = [];
  static int maximumAvailableDefault = -1;
  static Leniency maximumAvailableLeniencyDefault = Leniency.inherit;
  static String descriptionDefault = '';

  String name;
  int maximumAvailable;
  Leniency maximumAvailableLeniency;
  String description;

  List<String> memberIds;

  int availableNow = 0;

  Group(
      {required super.id,
      String? name,
      List<String>? memberIds,
      int? maximumAvailable,
      Leniency? maximumAvailableLeniency,
      String? description})
      : name = name ?? nameDefault,
        memberIds = memberIds ?? List.from(memberIdsDefault),
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
    memberIdsDefault = List<String>.from(groupJson['memberIds']);
    maximumAvailableDefault = groupJson['maximumAvailable'];
    maximumAvailableLeniencyDefault =
        Leniency.values[groupJson['maximumAvailableLeniency']];
    descriptionDefault = groupJson['description'];
  }

  @override
  Group fromJson(String id, Map<String, dynamic> objectJson) {
    return Group(
        id: id,
        name: objectJson['name'] ?? nameDefault,
        memberIds:
            List<String>.from(objectJson['memberIds'] ?? memberIdsDefault),
        maximumAvailable:
            objectJson['maximumAvailable'] ?? maximumAvailableDefault,
        maximumAvailableLeniency: Leniency.values[
            objectJson['maximumAvailableLeniency'] ??
                maximumAvailableLeniencyDefault.index],
        description: objectJson['description'] ?? descriptionDefault);
  }

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

class Work extends IObject {
  // TODO: remove defaults for dynamic values such as DateTime
  //       since they are fixed at the compile time.
  static String nameDefault = "Unnamed";
  static double loadDefault = 1;
  static int numberOfMembersNeededDefault = 1;
  static List<String> fixedMemberIdsDefault = [];
  static Leniency fixedMemberLeniencyDefault = Leniency.inherit;
  static List<String> fixedGroupIdsDefault = [];
  static Leniency fixedGroupLeniencyDefault = Leniency.inherit;
  static List<String> excludedMemberIdsDefault = [];
  static Leniency excludedMemberLeniencyDefault = Leniency.inherit;
  static List<String> excludedGroupIdsDefault = [];
  static Leniency excludedGroupLeniencyDefault = Leniency.inherit;
  static List<String> memberIdsDefault = [];
  static bool allowOverlapDefault = false;
  static bool repeatWithSameMembersDefault = false;
  static String descriptionDefault = "";

  String name;

  double load;
  int numberOfMembersNeeded;
  DateTimeInterval dateTimeInterval;
  DateTime get startDateTime {
    return dateTimeInterval.start;
  }

  set startDateTime(DateTime start) {
    dateTimeInterval.start = start;
  }

  DateTime get endDateTime {
    return dateTimeInterval.end;
  }

  set endDateTime(DateTime end) {
    dateTimeInterval.end = end;
  }

  List<String> fixedMemberIds;
  Leniency fixedMemberLeniency;
  List<String> fixedGroupIds;
  Leniency fixedGroupLeniency;

  List<String> excludedMemberIds;
  Leniency excludedMemberLeniency;
  List<String> excludedGroupIds;
  Leniency excludedGroupLeniency;

  List<String> memberIds;
  bool allowOverlap;
  String description;

  List<bool> repeatOn;
  DateTime endRepeatOn;
  bool repeatWithSameMembers;
  List<Work> repeatedWorks;

  Work(
      {required super.id,
      String? name,
      double? load,
      int? numberOfMembersNeeded,
      DateTime? startDateTime,
      DateTime? endDateTime,
      List<String>? fixedMemberIds,
      Leniency? fixedMemberLeniency,
      List<String>? fixedGroupIds,
      Leniency? fixedGroupLeniency,
      List<String>? excludedMemberIds,
      Leniency? excludedMemberLeniency,
      List<String>? excludedGroupIds,
      Leniency? excludedGroupLeniency,
      List<String>? memberIds,
      bool? allowOverlap,
      String? description = "",
      List<bool>? repeatOn,
      DateTime? endRepeatOn,
      bool? repeatWithSameMembers,
      List<Work>? repeatedWorks})
      : name = name ?? nameDefault,
        load = load ?? loadDefault,
        numberOfMembersNeeded =
            numberOfMembersNeeded ?? numberOfMembersNeededDefault,
        dateTimeInterval = DateTimeInterval(startDateTime ?? DateTime.now(),
            endDateTime ?? DateTime.now().add(const Duration(hours: 1))),
        fixedMemberIds = fixedMemberIds ?? List.from(fixedMemberIdsDefault),
        fixedMemberLeniency = fixedMemberLeniency ?? fixedMemberLeniencyDefault,
        fixedGroupIds = fixedGroupIds ?? List.from(fixedGroupIdsDefault),
        fixedGroupLeniency = fixedGroupLeniency ?? fixedGroupLeniencyDefault,
        excludedMemberIds =
            excludedMemberIds ?? List.from(excludedMemberIdsDefault),
        excludedMemberLeniency =
            excludedMemberLeniency ?? excludedMemberLeniencyDefault,
        excludedGroupIds =
            excludedGroupIds ?? List.from(excludedGroupIdsDefault),
        excludedGroupLeniency =
            excludedGroupLeniency ?? excludedGroupLeniencyDefault,
        memberIds = memberIds ?? List.from(memberIdsDefault),
        allowOverlap = allowOverlap ?? allowOverlapDefault,
        description = description ?? descriptionDefault,
        repeatOn = repeatOn ?? List.filled(7, false),
        endRepeatOn = endRepeatOn ?? DateTime.now(),
        repeatWithSameMembers =
            repeatWithSameMembers ?? repeatWithSameMembersDefault,
        repeatedWorks = repeatedWorks ?? List<Work>.empty(growable: true);

  @override
  Work create({required String id}) {
    return Work(id: id);
  }

  double getLoad() {
    if (repeatWithSameMembers) {
      return load * repeatedWorks.length;
    }
    return load;
  }

  List<DateTimeInterval> getIntervals() {
    List<DateTimeInterval> intervals = [dateTimeInterval];
    if (repeatWithSameMembers) {
      intervals.addAll(repeatedWorks.map((e) => e.dateTimeInterval));
    }
    return intervals;
  }

  static setDefault(Map<String, dynamic> workJson) {
    nameDefault = workJson['name'];
    loadDefault = workJson['load'];
    numberOfMembersNeededDefault = workJson['numberOfMembersNeeded'];
    fixedMemberIdsDefault = List<String>.from(workJson['fixedMemberIds']);
    fixedMemberLeniencyDefault =
        Leniency.values[workJson['fixedMemberLeniency']];
    fixedGroupIdsDefault = List<String>.from(workJson['fixedGroupIds']);
    fixedGroupLeniencyDefault = Leniency.values[workJson['fixedGroupLeniency']];
    excludedMemberIdsDefault = List<String>.from(
        workJson['excludedMemberIds'] ?? excludedMemberIdsDefault);
    excludedMemberLeniencyDefault = Leniency.values[
        workJson['excludedMemberLeniency'] ??
            excludedMemberLeniencyDefault.index];
    excludedGroupIdsDefault = List<String>.from(
        workJson['excludedGroupIds'] ?? excludedGroupIdsDefault);
    excludedGroupLeniencyDefault = Leniency.values[
        workJson['excludedGroupLeniency'] ??
            excludedGroupLeniencyDefault.index];
    memberIdsDefault = List<String>.from(workJson['memberIds']);
    allowOverlapDefault = workJson['allowOverlap'] ?? allowOverlapDefault;
    repeatWithSameMembersDefault =
        workJson['repeatWithSameMembers'] ?? repeatWithSameMembersDefault;
    descriptionDefault = workJson['description'];
  }

  @override
  Work fromJson(String id, Map<String, dynamic> objectJson) {
    return Work(
        id: id,
        name: objectJson['name'] ?? nameDefault,
        load: objectJson['load'] ?? loadDefault,
        numberOfMembersNeeded:
            objectJson['numberOfMembersNeeded'] ?? numberOfMembersNeededDefault,
        startDateTime: DateTime.parse(objectJson['startDateTime']),
        endDateTime: DateTime.parse(objectJson['endDateTime']),
        fixedMemberIds: List<String>.from(
            objectJson['fixedMemberIds'] ?? fixedMemberIdsDefault),
        fixedMemberLeniency: Leniency.values[objectJson['fixedMemberLeniency'] ??
            fixedMemberLeniencyDefault.index],
        fixedGroupIds: List<String>.from(
            objectJson['fixedGroupIds'] ?? fixedGroupIdsDefault),
        fixedGroupLeniency: Leniency.values[objectJson['fixedGroupLeniency'] ??
            fixedGroupLeniencyDefault.index],
        excludedMemberIds: List<String>.from(
            objectJson['excludedMemberIds'] ?? excludedMemberIdsDefault),
        excludedMemberLeniency: Leniency.values[
            objectJson['excludedMemberLeniency'] ??
                excludedMemberLeniencyDefault.index],
        excludedGroupIds: List<String>.from(
            objectJson['excludedGroupIds'] ?? excludedGroupIdsDefault),
        excludedGroupLeniency: Leniency.values[
            objectJson['excludedGroupLeniency'] ??
                excludedGroupLeniencyDefault.index],
        memberIds:
            List<String>.from(objectJson['memberIds'] ?? memberIdsDefault),
        allowOverlap: objectJson['allowOverlap'] ?? allowOverlapDefault,
        description: objectJson['description'] ?? descriptionDefault,
        repeatOn: List.from(objectJson['repeatOn']),
        endRepeatOn: DateTime.parse(objectJson['endRepeatOn']),
        repeatWithSameMembers: objectJson['repeatWithSameMembers'],
        repeatedWorks: List.from(
            objectJson['repeatedWorks']?.map((workJson) => fromJson(genId(), workJson))));
  }

  @override
  Map<String, dynamic> toJson() => {
        'name': name,
        'load': load,
        'numberOfMembersNeeded': numberOfMembersNeeded,
        'startDateTime': startDateTime.toString(),
        'endDateTime': endDateTime.toString(),
        'fixedMemberIds': fixedMemberIds,
        'fixedMemberLeniency': fixedMemberLeniency.index,
        'fixedGroupIds': fixedGroupIds,
        'fixedGroupLeniency': fixedGroupLeniency.index,
        'excludedMemberIds': excludedMemberIds,
        'excludedMemberLeniency': excludedMemberLeniency.index,
        'excludedGroupIds': excludedGroupIds,
        'excludedGroupLeniency': excludedGroupLeniency.index,
        'memberIds': memberIds,
        'allowOverlap': allowOverlap,
        'description': description,
        'repeatOn': repeatOn,
        'endRepeatOn': endRepeatOn.toString(),
        'repeatWithSameMembers': repeatWithSameMembers,
        'repeatedWorks': repeatedWorks.map((work) => work.toJson()).toList(),
      };
}

class Vacancy extends IObject {
  static String nameDefault = "Unnamed";
  static DateTime startDateTimeDefault =
      DateTime.now().copyWith(hour: 0, minute: 0);
  static DateTime endDateTimeDefault =
      DateTime.now().copyWith(hour: 0, minute: 0).add(const Duration(days: 1));
  static bool isPaidDefault = false;
  static String descriptionDefault = "";

  String name;

  DateTimeInterval dateTimeInterval;
  DateTime get startDateTime {
    return dateTimeInterval.start;
  }

  DateTime get endDateTime {
    return dateTimeInterval.end;
  }

  set startDateTime(DateTime dateTime) {
    dateTimeInterval.start = dateTime;
  }

  set endDateTime(DateTime dateTime) {
    dateTimeInterval.end = dateTime;
  }

  bool isPaid;
  String description;

  Vacancy(
      {required super.id,
      String? name,
      DateTime? startDateTime,
      DateTime? endDateTime,
      bool? isPaid,
      String? description})
      : name = name ?? nameDefault,
        dateTimeInterval = DateTimeInterval(
            startDateTime ?? startDateTimeDefault,
            endDateTime ?? endDateTimeDefault),
        isPaid = isPaid ?? isPaidDefault,
        description = description ?? descriptionDefault;

  @override
  Vacancy create({required String id}) {
    return Vacancy(id: id);
  }

  Duration get duration {
    return endDateTime.difference(startDateTime);
  }

  static setDefault(Map<String, dynamic> vacancyJson) {
    nameDefault = vacancyJson['name'];
    startDateTimeDefault = DateTime.parse(vacancyJson['startDateTime']);
    endDateTimeDefault = DateTime.parse(vacancyJson['endDateTime']);
    isPaidDefault = vacancyJson['isPaid'];
    descriptionDefault = vacancyJson['description'];
  }

  @override
  Vacancy fromJson(String id, Map<String, dynamic> objectJson) {
    return Vacancy(
        id: id,
        name: objectJson['name'],
        startDateTime: DateTime.parse(objectJson['startDateTime']),
        endDateTime: DateTime.parse(objectJson['endDateTime']),
        isPaid: objectJson['isPaid'],
        description: objectJson['description']);
  }

  @override
  Map<String, dynamic> toJson() => {
        'name': name,
        'startDateTime': startDateTime.toString(),
        'endDateTime': endDateTime.toString(),
        'isPaid': isPaid,
        'description': description,
      };
}
