import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

import 'core.dart';

// Deals with the direct access to the storage file
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

  final Data data = Data.fromDefault();

  void init() {
    ioController.read().then((value) {
      try {
        data.updateAll(jsonDecode(value));
        notifyListeners();
      } catch (error) {
        throw ShiftWorkError('Initialization Failed.');
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

  bool _tempGroup = false;
  String _tempGroupId = defaultTempId;

  Group getGroup(String id) {
    if (_tempGroup & (_tempGroupId == id)) {
      return data.groupData.tempObject as Group;
    }
    if (!data.groupData.objectMap.keys.contains(id)) {
      _tempGroup = true;
      _tempGroupId = id;
      return data.groupData.getTemp(id) as Group;
    }
    return data.groupData.getById(id) as Group;
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

  Vacancy getVacancy(String id) {
    if (_tempVacancy & (_tempVacancyId == id)) {
      return data.vacancyData.tempObject as Vacancy;
    }
    if (!data.vacancyData.objectMap.keys.contains(id)) {
      _tempVacancy = true;
      _tempVacancyId = id;
      return data.vacancyData.getTemp(id) as Vacancy;
    }
    return data.vacancyData.getById(id) as Vacancy;
  }

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

  void generateShift(String shiftId) {
    final Shift shift = getShift(shiftId);
    Leniency gFixedMemberLeniency;
    int efml = 1;
    Leniency gFixedGroupLeniency;
    int efgl = 0;
    Leniency gMaximumAvailableLeniency = shift.maximumAvailableLeniency;
    List<Work> worksLeft = shift.workIds.map<Work>((workId) {
      final work = getWork(workId);
      work.memberIds = [];
      return work;
    }).toList();
    List<Member> members =
        shift.memberIds.map<Member>((memberId) => getMember(memberId)).toList();
    List<Group> groups =
        shift.groupIds.map<Group>((groupId) => getGroup(groupId)).toList();
    Work nextWork;
    Member? maybeNextMember;
    Member nextMember;

    // Main Loop
    while (worksLeft.isNotEmpty) {
      nextWork = _getNextWork(worksLeft);
      for (Group group in groups) {
        group.availableNow =
            min(group.maximumAvailable, group.memberIds.length);
      }

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
                .where((member) => member.availablity != notAvailable)
                .length >=
            nextWork.numberOfMembersNeeded) {
          break;
        }
      }
      if (members.where((member) => member.availablity != notAvailable).length <
          nextWork.numberOfMembersNeeded) {
        throw ShiftWorkError('Not enough member for ${nextWork.name}');
      }

      // Assign a member one by one
      while (nextWork.memberIds.length >= nextWork.numberOfMembersNeeded) {
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
      // This is sus! What if a member is set to notAvailable, but not removed from the group.availableNow counter.
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
          group.availableNow -= 1;
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
        if (member1.getLoad(scheme: GetLoadScheme.plain) /
                member1.availablity <=
            member2.getLoad(scheme: GetLoadScheme.plain) /
                member2.availablity) {
          return member1;
        }
        return member2;
      });
    }
    if (scheme == GetNextMemberScheme.getLeastLoadWithFatigue) {
      return members.reduce((member1, member2) {
        if (member1.getLoad(
                    scheme: GetLoadScheme.fatigue, workStartDateTime: at) /
                member1.availablity <=
            member2.getLoad(
                    scheme: GetLoadScheme.fatigue, workStartDateTime: at) /
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
      if (vacancy.include(work.startDateTime) ||
          vacancy.include(work.endDateTime)) {
        return notAvailable;
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
