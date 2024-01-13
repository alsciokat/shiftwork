import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core.dart';

// Deals with the direct access to the storage file
class IOController {
  Future<File> get dataFile async {
    // /data/user/0/com.example.shift/app_flutter
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/shift_data.json');
    final exists = await file.exists();
    if (!exists) {
      await file.create(recursive: true);
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

  Future<bool> writeToExternalStorage(String fileName, String data) async {
    final preferences = await SharedPreferences.getInstance();
    if (Platform.isAndroid) {
      final documentDirectory = Directory(
          preferences.getString('exportDirectory') ??
              '/storage/emulated/0/Documents');
      final exists = await documentDirectory.exists();
      if (!exists) {
        await documentDirectory.create();
      }
      final exportFile = File('${documentDirectory.path}/$fileName');
      if (!exportFile.existsSync()) {
        await exportFile.create();
      }
      await exportFile.writeAsString(data);
      return true;
    }
    return false;
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
      // try {
      if (value == "") {
        return;
      }
      data = Data.fromJson(jsonDecode(value));
      notifyListeners();
      // } catch (error) {
      //   throw ShiftWorkError('Initialization Failed.');
      // }
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

  bool _tempShift = false;
  String _tempShiftId = defaultTempId;

  Shift getShift(String id) {
    if (_tempShift & (_tempShiftId == id)) {
      return data.shiftData.tempObject;
    }
    if (!data.shiftData.objectMap.keys.contains(id)) {
      _tempShift = true;
      _tempShiftId = id;
      return data.shiftData.getTemp(id);
    }
    return data.shiftData.getById(id);
  }

  DataController deleteShift(String shiftId) {
    data.shiftData.objectOrder.remove(shiftId);
    data.shiftData.objectMap.remove(shiftId);
    return this;
  }

  Iterable<Member> getAllOtherMembers(String groupId) {
    Iterable<Member> allMembers = data.memberData.objectMap.values;
    return allMembers
        .where((member) => !getGroup(groupId).memberIds.contains(member.id));
  }

  bool _tempMember = false;
  String _tempMemberId = defaultTempId;

  Member getMember(String id) {
    if (_tempMember & (_tempMemberId == id)) {
      return data.memberData.tempObject;
    }
    if (!data.memberData.objectMap.keys.contains(id)) {
      _tempMember = true;
      _tempMemberId = id;
      return data.memberData.getTemp(id);
    }
    return data.memberData.getById(id);
  }

  DataController addMember(String shiftId, String memberId) {
    getShift(shiftId).memberIds.add(memberId);
    return this;
  }

  DataController addMemberToGroup(String groupId, String memberId) {
    getGroup(groupId).memberIds.add(memberId);
    return this;
  }

  DataController removeMember(String shiftId, String memberId) {
    getShift(shiftId).memberIds.remove(memberId);
    return this;
  }

  DataController removeMemberFromGroup(String groupId, String memberId) {
    getGroup(groupId).memberIds.remove(memberId);
    return this;
  }

  DataController deleteMember(String memberId) {
    data.memberData.objectOrder.remove(memberId);
    data.memberData.objectMap.remove(memberId);
    return this;
  }

  bool _tempGroup = false;
  String _tempGroupId = defaultTempId;

  Group getGroup(String id) {
    if (_tempGroup & (_tempGroupId == id)) {
      return data.groupData.tempObject;
    }
    if (!data.groupData.objectMap.keys.contains(id)) {
      _tempGroup = true;
      _tempGroupId = id;
      return data.groupData.getTemp(id);
    }
    return data.groupData.getById(id);
  }

  DataController addGrouop(String shiftId, String groupId) {
    getShift(shiftId).groupIds.add(groupId);
    return this;
  }

  DataController removeGroup(String shiftId, String groupId) {
    getShift(shiftId).groupIds.remove(groupId);
    return this;
  }

  DataController deleteGroup(String groupId) {
    data.groupData.objectOrder.remove(groupId);
    data.groupData.objectMap.remove(groupId);
    return this;
  }

  bool _tempWork = false;
  String _tempWorkId = defaultTempId;

  Work getWork(String id) {
    if (_tempWork & (_tempWorkId == id)) {
      return data.workData.tempObject;
    }
    if (!data.workData.objectMap.keys.contains(id)) {
      _tempWork = true;
      _tempWorkId = id;
      return data.workData.getTemp(id);
    }
    return data.workData.getById(id);
  }

  DataController addWork(String shiftId, String workId) {
    getShift(shiftId).workIds.add(workId);
    return this;
  }

  DataController removeWork(String shiftId, String workId) {
    getShift(shiftId).workIds.remove(workId);
    return this;
  }

  DataController deleteWork(String workId) {
    data.workData.objectOrder.remove(workId);
    data.workData.objectMap.remove(workId);
    return this;
  }

  bool _tempVacancy = false;
  String _tempVacancyId = defaultTempId;

  Iterable<Vacancy> getAllOtherVacancies(String memberId) {
    Iterable<Vacancy> allVacancy = data.vacancyData.objectMap.values;
    return allVacancy.where(
        (vacancy) => !getMember(memberId).vacancyIds.contains(vacancy.id));
  }

  Vacancy getVacancy(String id) {
    if (_tempVacancy & (_tempVacancyId == id)) {
      return data.vacancyData.tempObject;
    }
    if (!data.vacancyData.objectMap.keys.contains(id)) {
      _tempVacancy = true;
      _tempVacancyId = id;
      return data.vacancyData.getTemp(id);
    }
    return data.vacancyData.getById(id);
  }

  DataController addVacancy(String memberId, String vacancyId) {
    getMember(memberId).vacancyIds.add(vacancyId);
    return this;
  }

  DataController removeVacancy(String memberId, String vacancyId) {
    getMember(memberId).vacancyIds.remove(vacancyId);
    return this;
  }

  DataController deleteVacancy(String vacancyId) {
    data.vacancyData.objectOrder.remove(vacancyId);
    data.vacancyData.objectMap.remove(vacancyId);
    return this;
  }

  DataController resetLoads() {
    Iterable<Member> allMembers = data.memberData.objectMap.values;
    for (Member member in allMembers) {
      member.assignedIntervals.clear();
      member.previousLoad = 0;
      member.previousTotalLoad = 0;
      member.previousLoadEndDateTime = DateTime(0);
    }
    return this;
  }

  DataController saveTempMember() {
    if (_tempMember) {
      data.memberData.saveTemp();
      _tempMember = false;
    }
    return this;
  }

  DataController saveTempGroup() {
    if (_tempGroup) {
      data.groupData.saveTemp();
      _tempGroup = false;
    }
    return this;
  }

  DataController saveTempVacancy() {
    if (_tempVacancy) {
      data.vacancyData.saveTemp();
      _tempVacancy = false;
    }
    return this;
  }

  DataController saveTempWork() {
    if (_tempWork) {
      data.workData.saveTemp();
      _tempWork = false;
    }
    return this;
  }

  DataController saveTempShift() {
    if (_tempShift) {
      data.shiftData.saveTemp();
      _tempShift = false;
    }
    return this;
  }

  // DataController saveTemp() {
  //   if (_tempMember) {
  //     data.memberData.saveTemp();
  //     _tempMember = false;
  //   }
  //   if (_tempGroup) {
  //     data.groupData.saveTemp();
  //     _tempGroup = false;
  //   }
  //   if (_tempVacancy) {
  //     data.vacancyData.saveTemp();
  //     _tempVacancy = false;
  //   }
  //   if (_tempWork) {
  //     data.workData.saveTemp();
  //     _tempWork = false;
  //   }
  //   if (_tempShift) {
  //     data.shiftData.saveTemp();
  //     _tempShift = false;
  //   }
  //   return this;
  // }

  DataController generateShift(String shiftId) {
    final Shift shift = getShift(shiftId);
    Leniency gFixedMemberLeniency;
    int efml = 1;
    Leniency gFixedGroupLeniency;
    int efgl = 0;
    Leniency gMaximumAvailableLeniency = shift.maximumAvailableLeniency;
    List<Work> worksLeft = [];

    // Find all the works that need to be done
    for (Work work in shift.workIds.map((workId) => getWork(workId))) {
      work.memberIds = [];
      work.repeatedWorks = [];
      worksLeft.add(work);

      if (work.repeatOn.any((element) => element)) {
        for (DateTime date = work.startDateTime.add(const Duration(days: 1));
            date.isBefore(work.endRepeatOn) ||
                date.isAtSameMomentAs(work.endRepeatOn);
            date = date.add(const Duration(days: 1))) {
          if (work.repeatOn[date.weekday - 1]) {
            Work repeatedWork = Work(
                id: genId(),
                name: work.name,
                description: 'Repeated',
                load: work.load,
                numberOfMembersNeeded: work.numberOfMembersNeeded,
                startDateTime: date.copyWith(
                    hour: work.startDateTime.hour,
                    minute: work.startDateTime.minute),
                endDateTime: date
                    .copyWith(
                        hour: work.startDateTime.hour,
                        minute: work.startDateTime.minute)
                    .add(work.dateTimeInterval.duration),
                fixedMemberIds: work.fixedMemberIds,
                fixedMemberLeniency: work.fixedMemberLeniency,
                fixedGroupIds: work.fixedGroupIds,
                fixedGroupLeniency: work.fixedGroupLeniency,
                memberIds: [],
                allowOverlap: work.allowOverlap);

            work.repeatedWorks.add(repeatedWork);
            worksLeft.add(repeatedWork);
          }
        }
      }
    }
    List<Member> members =
        shift.memberIds.map<Member>((memberId) => getMember(memberId)).toList();
    if (shift.shuffleMembers) {
      members.shuffle();
    }
    List<Group> groups =
        shift.groupIds.map<Group>((groupId) => getGroup(groupId)).toList();
    Work nextWork;
    Member? maybeNextMember;
    Member nextMember;

    resetLoads();

    // Main Loop
    while (worksLeft.isNotEmpty) {
      nextWork = _getNextWork(worksLeft);

      // Get the list of available members by iterating over all possible configurations.
      for (int i = 0; i < 4; i++) {
        if (i & (1 << efml) == (1 << efml)) {
          if (nextWork.fixedMemberLeniency == Leniency.force ||
              (nextWork.fixedMemberLeniency == Leniency.inherit &&
                  shift.fixedMemberLeniency == Leniency.force)) {
            continue;
          }
          gFixedMemberLeniency = Leniency.recommend;
        } else {
          gFixedMemberLeniency = Leniency.force;
        }
        if (i & (1 << efgl) == (1 << efgl)) {
          if (nextWork.fixedGroupLeniency == Leniency.force ||
              (nextWork.fixedGroupLeniency == Leniency.inherit &&
                  shift.fixedGroupLeniency == Leniency.force)) {
            continue;
          }
          gFixedGroupLeniency = Leniency.recommend;
        } else {
          gFixedGroupLeniency = Leniency.force;
        }

        for (Member member in members) {
          member.availablity = _calculateAvailablity(
              member, nextWork, gFixedMemberLeniency, gFixedGroupLeniency);
        }
        if (members
                .where((member) => member.availablity > notAvailable)
                .length >=
            nextWork.numberOfMembersNeeded) {
          break;
        }
      }
      if (members.where((member) => member.availablity > notAvailable).length <
          nextWork.numberOfMembersNeeded) {
        throw ShiftWorkError('Not enough member for ${nextWork.name}');
      }
      // Calculate availableNow
      for (Group group in groups) {
        if (!nextWork.allowOverlap) {
          if (group.maximumAvailable == -1) {
            group.availableNow = group.memberIds.length;
          } else {
            group.availableNow = group.maximumAvailable;
          }
          Iterable<Member> groupMembers =
              members.where((member) => group.memberIds.contains(member.id));
          for (Member groupMember in groupMembers) {
            if (groupMember.assignedIntervals.any(
                (interval) => interval.intersect(nextWork.dateTimeInterval))) {
              group.availableNow -= 1;
            }
          }
        } else {
          group.availableNow = group.memberIds.length;
        }
      }

      // Assign a member one by one. Severe mistake at a90c675. It was '>='
      while (nextWork.memberIds.length < nextWork.numberOfMembersNeeded) {
        // Get a member for the work
        maybeNextMember = _getNextMember(
            members,
            groups,
            nextWork.startDateTime,
            GetNextMemberScheme.getLeastLoadWithFatigue,
            gMaximumAvailableLeniency);

        if (maybeNextMember == null) {
          throw ShiftWorkError("Not enough members for ${nextWork.name}.");
        }
        nextMember = maybeNextMember;

        // Assign
        nextWork.memberIds.add(nextMember.id);
        nextMember.addLoad(nextWork.load, at: nextWork.endDateTime);
        if (!nextWork.allowOverlap) {
          nextMember.assignedIntervals.add(nextWork.dateTimeInterval);
        }
        nextMember.availablity = notAvailable;
      }

      // This is just for safety. Just in case the availablity is used out of this function.
      for (Member member in members) {
        member.availablity = 1;
      }
      if (nextWork.memberIds.length > nextWork.numberOfMembersNeeded) {
        throw ShiftWorkError(
            'Number of members exceeded the required while assigning members.');
      }
      worksLeft.remove(nextWork);
    }
    return this;
  }

  Work _getNextWork(Iterable<Work> works,
      {GetNextWorkScheme scheme = GetNextWorkScheme.getHighestLoad}) {
    if (scheme == GetNextWorkScheme.getFirst) {
      return works.first;
    }
    if (scheme == GetNextWorkScheme.getHighestLoad) {
      return works.reduce((work1, work2) {
        if (work1.load >= work2.load) {
          return work1;
        }
        return work2;
      });
    }
    if (scheme == GetNextWorkScheme.getLowestLoad) {
      return works.reduce((work1, work2) {
        if (work1.load <= work2.load) {
          return work1;
        }
        return work2;
      });
    }
    if (scheme == GetNextWorkScheme.getChronologically) {
      return works.reduce((work1, work2) {
        if (work1.startDateTime.isBefore(work2.startDateTime) ||
            (work1.startDateTime.isAtSameMomentAs(work2.startDateTime) &&
                work1.load >= work2.load)) {
          return work1;
        }
        return work2;
      });
    }
    throw ShiftWorkError('$scheme is not implemented');
  }

  Member? _getNextMember(
      Iterable<Member> members,
      Iterable<Group> groups,
      DateTime? at,
      GetNextMemberScheme scheme,
      Leniency gMaximumAvailableLeniency) {
    new_candidate:
    while (!members.every((member) => member.availablity == notAvailable)) {
      Member candidate = _getCandidateMember(members, at, scheme);
      if (groups.every((group) => group.availableNow <= 0)) {
        return candidate;
      }
      // What if a member is set to notAvailable, but not removed from the group.availableNow counter.
      // ADD: This is actually desirable behavior. It means the group is not constraining but other factors are.
      for (final group in groups) {
        if (group.memberIds.contains(candidate.id)) {
          if (group.availableNow <= 0) {
            if (group.maximumAvailableLeniency == Leniency.force ||
                (group.maximumAvailableLeniency == Leniency.inherit &&
                    gMaximumAvailableLeniency == Leniency.force)) {
              candidate.availablity = notAvailable;
            } else {
              candidate.availablity = 0.5;
            }
            continue new_candidate;
          }
          // the candidate member is available. Decreasing the availableNow
          group.availableNow -= 1;
          // mark all the other members in the group notavailable.
          if (group.availableNow == 0) {
            for (Member member in group.memberIds
                .map<Member>((memberId) => getMember(memberId))) {
              if (group.maximumAvailableLeniency == Leniency.force ||
                  (group.maximumAvailableLeniency == Leniency.inherit &&
                      gMaximumAvailableLeniency == Leniency.force)) {
                member.availablity = notAvailable;
              } else {
                member.availablity = 0.5;
              }
            }
          }
        }
      }
      return candidate;
    }
    return null;
  }

  Member _getCandidateMember(
      Iterable<Member> members, DateTime? at, GetNextMemberScheme scheme) {
    if (scheme == GetNextMemberScheme.getLeastLoad) {
      return members.reduce((member1, member2) {
        if ((member1.getLoad(scheme: GetLoadScheme.plain) + .1) /
                member1.availablity <=
            (member2.getLoad(scheme: GetLoadScheme.plain) + .1) /
                member2.availablity) {
          return member1;
        }
        return member2;
      });
    }
    if (scheme == GetNextMemberScheme.getLeastLoadWithFatigue) {
      return members.reduce((member1, member2) {
        if ((member1.getLoad(
                        scheme: GetLoadScheme.fatigue, workStartDateTime: at) +
                    .1) /
                member1.availablity <=
            (member2.getLoad(
                        scheme: GetLoadScheme.fatigue, workStartDateTime: at) +
                    .1) /
                member2.availablity) {
          return member1;
        }
        return member2;
      });
    }
    throw ShiftWorkError('$scheme is not implemented');
  }

  final double notAvailable = 0.0001;
  final double absolutely = 10000;

  double _calculateAvailablity(Member member, Work work,
      Leniency fixedMemberLeniency, Leniency fixedGroupLeniency) {
    Iterable<Vacancy> vacancies =
        member.vacancyIds.map<Vacancy>((vacancyId) => getVacancy(vacancyId));
    for (final vacancy in vacancies) {
      if (vacancy.dateTimeInterval.intersect(work.dateTimeInterval)) {
        return notAvailable;
      }
    }
    if (!work.allowOverlap) {
      for (final dateTimeInterval in member.assignedIntervals) {
        if (dateTimeInterval.intersect(work.dateTimeInterval)) {
          return notAvailable;
        }
      }
    }
    if (work.fixedMemberIds.contains(member.id)) {
      if (fixedMemberLeniency == Leniency.force) {
        return absolutely;
      } else if (fixedMemberLeniency == Leniency.recommend) {
        return 1.5;
      }
    }
    for (final group
        in work.fixedGroupIds.map<Group>((groupId) => getGroup(groupId))) {
      if (group.memberIds.contains(member.id)) {
        if (fixedGroupLeniency == Leniency.force) {
          return absolutely;
        } else if (fixedGroupLeniency == Leniency.recommend) {
          return 1.5;
        }
      }
    }
    return 1;
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

enum GetNextWorkScheme {
  getFirst,
  getHighestLoad,
  getLowestLoad,
  getChronologically
}

enum GetNextMemberScheme { getLeastLoad, getLeastLoadWithFatigue }
