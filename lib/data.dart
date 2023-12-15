import 'dart:convert';
import 'dart:io';

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

  Vacancy getVacancy(String vacancyId) {
    return data.vacancyData.getById(vacancyId) as Vacancy;
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
    List<Work> worksLeft = getShift(shiftId).workIds.map<Work>((workId) {
      final work = getWork(workId);
      work.memberIds = [];
      return work;
    }).toList();
    List<Member> members = getShift(shiftId)
        .memberIds
        .map<Member>((memberId) => getMember(memberId))
        .toList();
    Work nextWork;
    Member nextMember;

    // Main Loop
    while (worksLeft.isNotEmpty) {
      nextWork = _getNextWork(worksLeft);

      while (nextWork.memberIds.length >= nextWork.numberOfMemberNeeded) {
        Member? _nextMember = _getNextMember(members,
            at: nextWork.startDateTime,
            scheme: GetNextMemberScheme.getLeastLoadWithFatigue);
        if (_nextMember == null) {
          throw ShiftWorkError('No available member for ${nextWork.name}');
        }
        nextMember = _nextMember;

        if (_isAvailable(
            nextMember, nextWork.startDateTime, nextWork.endDateTime)) {
          nextWork.memberIds.add(nextMember.id);
          nextMember.addLoad(nextWork.load, at: nextWork.endDateTime);
          continue;
        } else {
          nextMember.isAvailable = false;
        }
      }

      if (nextWork.memberIds.length > nextWork.numberOfMemberNeeded) {
        throw ShiftWorkError(
            'Number of members exceeded the required while assigning members.');
      }
      for (final member in members) {
        member.isAvailable = true;
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

  Member? _getNextMember(Iterable<Member> members,
      {DateTime? at,
      GetNextMemberScheme scheme = GetNextMemberScheme.getLeastLoad}) {
    Iterable<Member> candidateMembers =
        members.where((member) => member.isAvailable);
    if (candidateMembers.isEmpty) {
      return null;
    }
    if (scheme == GetNextMemberScheme.getLeastLoad) {
      return candidateMembers.reduce((member1, member2) {
        if (member1.getLoad(scheme: GetLoadScheme.plain) <=
            member1.getLoad(scheme: GetLoadScheme.plain)) {
          return member1;
        }
        return member2;
      });
    }
    if (scheme == GetNextMemberScheme.getLeastLoadWithFatigue) {
      return candidateMembers.reduce((member1, member2) {
        if (member1.getLoad(
                scheme: GetLoadScheme.fatigue, workStartDateTime: at) <=
            member1.getLoad(
                scheme: GetLoadScheme.fatigue, workStartDateTime: at)) {
          return member1;
        }
        return member2;
      });
    }
    throw ShiftWorkError('$scheme is not implemented');
  }

  bool _isAvailable(
      Member member, DateTime startDateTime, DateTime endDateTime) {
    Iterable<Vacancy> vacancies =
        member.vacancyIDs.map<Vacancy>((vacancyID) => getVacancy(vacancyID));
    for (final vacancy in vacancies) {
      if (vacancy.include(startDateTime) || vacancy.include(endDateTime)) {
        return false;
      }
    }
    return true;
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
