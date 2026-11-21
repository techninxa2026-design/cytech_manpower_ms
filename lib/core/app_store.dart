import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'permit_evidence.dart';

String newId() => DateTime.now().microsecondsSinceEpoch.toString();
String dayKey(DateTime date) => date.toIso8601String().substring(0, 10);

class Person {
  Person({required this.id, required this.name, required this.username, this.isAdmin = false,this.hourlyRate});
  final String id, name, username;
  final bool isAdmin;
  final double? hourlyRate;
  factory Person.fromJson(Map<String, dynamic> m) => Person(
    id: m['id'] as String, name: m['name'] as String,
    username: m['username'] as String, isAdmin: m['isAdmin'] == true,
    hourlyRate:(m['hourlyRate'] as num?)?.toDouble());
  Map<String, dynamic> toJson() => {'id':id,'name':name,'username':username,'isAdmin':isAdmin,'hourlyRate':hourlyRate};
}
class CrewTeam {
  CrewTeam({required this.id, required this.name, required this.description, required this.memberIds});
  final String id, name, description;
  final List<String> memberIds;
  factory CrewTeam.fromJson(Map<String, dynamic> m) => CrewTeam(
    id:m['id'] as String, name:m['name'] as String,
    description:(m['description'] ?? '') as String,
    memberIds:List<String>.from(m['memberIds'] as List? ?? []));
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'description':description,'memberIds':memberIds};
}
class GroupMember {
  GroupMember({required this.personId, required this.role, required this.assignedOn});
  final String personId, role, assignedOn;
  factory GroupMember.fromJson(Map<String,dynamic> m)=>GroupMember(
    personId:m['personId'] as String,role:(m['role'] ?? 'member') as String,
    assignedOn:(m['assignedOn'] ?? dayKey(DateTime.now())) as String);
  Map<String,dynamic> toJson()=>{'personId':personId,'role':role,'assignedOn':assignedOn};
}
class WorkGroup {
  WorkGroup({required this.id,required this.name,required this.description,
    this.imageBase64,required this.members});
  final String id, name, description;
  final String? imageBase64;
  final List<GroupMember> members;
  factory WorkGroup.fromJson(Map<String,dynamic> m)=>WorkGroup(
    id:m['id'] as String,name:m['name'] as String,
    description:(m['description'] ?? '') as String,
    imageBase64:m['imageBase64'] as String?,
    members:(m['members'] as List? ?? []).map((e)=>GroupMember.fromJson(Map<String,dynamic>.from(e as Map))).toList());
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'description':description,
    'imageBase64':imageBase64,'members':members.map((e)=>e.toJson()).toList()};
  String roleOf(String userId) {
    for(final m in members){if(m.personId==userId)return m.role;}
    return '';
  }
}
class GroupEvent {
  GroupEvent({required this.id,required this.groupId,required this.kind,
    required this.authorId,required this.text,required this.timestamp,this.referenceId});
  final String id,groupId,kind,authorId,text,timestamp;
  final String? referenceId;
  factory GroupEvent.fromJson(Map<String,dynamic> m)=>GroupEvent(
    id:m['id'] as String,groupId:m['groupId'] as String,kind:m['kind'] as String,
    authorId:m['authorId'] as String,text:(m['text'] ?? '') as String,
    timestamp:m['timestamp'] as String,referenceId:m['referenceId'] as String?);
  Map<String,dynamic> toJson()=>{'id':id,'groupId':groupId,'kind':kind,
    'authorId':authorId,'text':text,'timestamp':timestamp,'referenceId':referenceId};
}
class AttendanceReport {
  AttendanceReport({required this.id,required this.groupId,required this.date,
    required this.authorId,required this.createdAt,required this.present,
    this.hours=const {},this.rateSnapshot=const {},this.otMultiplier=1.0,
    this.permit,this.groupName=''});
  final PermitEvidence? permit;
  final String groupName;
  final String id,groupId,date,authorId,createdAt;
  final Map<String,bool> present;
  final Map<String,double> hours;
  final Map<String,double?> rateSnapshot;
  final double otMultiplier;
  double hoursFor(String personId)=>! (present[personId]??false)?0:
    (hours[personId]??8).clamp(0,24).toDouble();
  double overtimeFor(String personId)=> (hoursFor(personId)-8).clamp(0,24).toDouble();
  double get totalHours=>present.keys.fold<double>(0,(sum,id)=>sum+hoursFor(id));
  double get totalOvertime=>present.keys.fold<double>(0,(sum,id)=>sum+overtimeFor(id));
  factory AttendanceReport.fromJson(Map<String,dynamic> m)=>AttendanceReport(
    id:m['id'] as String,groupId:m['groupId'] as String,date:m['date'] as String,
    authorId:m['authorId'] as String,createdAt:m['createdAt'] as String,
    present:Map<String,bool>.from(m['present'] as Map? ?? {}),
    hours:(m['hours'] as Map? ?? {}).map((k,v)=>MapEntry(k.toString(),(v as num).toDouble())),
    rateSnapshot:(m['rateSnapshot'] as Map? ?? {}).map((k,v)=>MapEntry(k.toString(),(v as num?)?.toDouble())),
    otMultiplier:(m['otMultiplier'] as num?)?.toDouble()??1.0,
    groupName:(m['groupName'] as String?)??'',
    permit:m['permit']==null?null:PermitEvidence.fromJson(Map<String,dynamic>.from(m['permit'] as Map)));
  Map<String,dynamic> toJson()=>{'id':id,'groupId':groupId,'date':date,
    'authorId':authorId,'createdAt':createdAt,'present':present,
    'hours':hours,'rateSnapshot':rateSnapshot,'otMultiplier':otMultiplier,
    'permit':permit?.toJson(),'groupName':groupName};
  int get presentCount=>present.values.where((v)=>v).length;
  int get absentCount=>present.values.where((v)=>!v).length;
}
class GroupComplaint {
  GroupComplaint({required this.id,required this.groupId,required this.authorId,
    required this.text,required this.status,required this.createdAt});
  final String id,groupId,authorId,text,status,createdAt;
  factory GroupComplaint.fromJson(Map<String,dynamic> m)=>GroupComplaint(
    id:m['id'] as String,groupId:m['groupId'] as String,authorId:m['authorId'] as String,
    text:m['text'] as String,status:(m['status'] ?? 'Open') as String,
    createdAt:m['createdAt'] as String);
  Map<String,dynamic> toJson()=>{'id':id,'groupId':groupId,'authorId':authorId,
    'text':text,'status':status,'createdAt':createdAt};
}

class WorkNotice {
  WorkNotice({required this.id,required this.authorId,required this.company,
    required this.location,required this.date,required this.reportingTime,
    required this.memberIds,required this.createdAt,this.instructions=''});
  final String id,authorId,company,location,date,reportingTime,createdAt,instructions;
  final List<String> memberIds;
  factory WorkNotice.fromJson(Map<String,dynamic> m)=>WorkNotice(
    id:m['id'] as String,authorId:m['authorId'] as String,
    company:m['company'] as String,location:m['location'] as String,
    date:m['date'] as String,reportingTime:m['reportingTime'] as String,
    createdAt:m['createdAt'] as String,instructions:(m['instructions']??'') as String,
    memberIds:List<String>.from(m['memberIds'] as List? ?? []));
  Map<String,dynamic> toJson()=>{'id':id,'authorId':authorId,'company':company,
    'location':location,'date':date,'reportingTime':reportingTime,
    'createdAt':createdAt,'instructions':instructions,'memberIds':memberIds};
}

class AppStore extends ChangeNotifier {
  static const storageKey='cytech_manpower_offline_v1';
  final List<Person> people=[];
  final List<CrewTeam> teams=[];
  final List<WorkGroup> groups=[];
  final List<GroupEvent> events=[];
  final List<AttendanceReport> attendance=[];
  final List<GroupComplaint> complaints=[];
  final List<WorkNotice> workNotices=[];
  double overtimeMultiplier=1.0;
  String currentUserId='admin';
  bool signedIn=false;
  String? storageError;
  SharedPreferences? _prefs;
  Person get me=>person(currentUserId);
  bool get isAdmin=>me.isAdmin;
  bool get canPublishWorkNotice=>isAdmin||groups.any((g)=>g.roleOf(currentUserId)=='supervisor');
  List<WorkNotice> get visibleWorkNotices=>workNotices.where((n)=>isAdmin||n.authorId==currentUserId||n.memberIds.contains(currentUserId)).toList()
    ..sort((a,b)=>b.createdAt.compareTo(a.createdAt));
  Person person(String id)=>people.firstWhere((p)=>p.id==id,orElse:()=>Person(id:id,name:'Unknown member',username:id));
  WorkGroup group(String id)=>groups.firstWhere((g)=>g.id==id);
  CrewTeam team(String id)=>teams.firstWhere((t)=>t.id==id);
  List<String> get allTeamMemberIds=>teams.expand((t)=>t.memberIds).toSet().toList();
  List<CrewTeam> get visibleTeams=>isAdmin?teams:teams.where((t)=>t.memberIds.contains(currentUserId)).toList();
  List<WorkGroup> get visibleGroups=>isAdmin?groups:groups.where((g)=>g.members.any((m)=>m.personId==currentUserId)).toList();
  List<GroupEvent> groupEvents(String id)=>events.where((e)=>e.groupId==id).toList()
    ..sort((a,b)=>a.timestamp.compareTo(b.timestamp));
  List<AttendanceReport> reportsFor(String id)=>attendance.where((a)=>a.groupId==id).toList()
    ..sort((a,b)=>b.createdAt.compareTo(a.createdAt));
  List<GroupComplaint> complaintsFor(String id)=>complaints.where((c)=>c.groupId==id).toList()
    ..sort((a,b)=>b.createdAt.compareTo(a.createdAt));
  bool canSee(WorkGroup g)=>isAdmin||g.members.any((m)=>m.personId==currentUserId);
  bool canPublish(WorkGroup g)=>isAdmin||g.roleOf(currentUserId)=='supervisor';
  bool canComplain(WorkGroup g)=>g.roleOf(currentUserId)=='engineer'&&!isAdmin;
  bool canReview(WorkGroup g)=>canPublish(g);
  String roleFor(WorkGroup g)=>isAdmin?'Admin':(g.roleOf(currentUserId).isEmpty?'Not assigned':g.roleOf(currentUserId));
  String get currentRole {
    if(isAdmin)return 'Admin';
    final roles=visibleGroups.map((g)=>g.roleOf(currentUserId)).toList();
    if(roles.contains('supervisor'))return 'Supervisor';
    if(roles.contains('engineer'))return 'Engineer';
    return 'Member';
  }
  Future<void> initialize() async {
    seed();
    try {
      _prefs=await SharedPreferences.getInstance();
      final json=_prefs!.getString(storageKey);
      if(json!=null) {
        final m=Map<String,dynamic>.from(jsonDecode(json) as Map);
        _load(m);
      }
    } catch(e){storageError='Local data could not be loaded: $e';}
    notifyListeners();
  }
  void seed(){
    people..clear()..addAll([
      Person(id:'admin',name:'Cytech Administrator',username:'admin',isAdmin:true),
      Person(id:'ayesha',name:'Ayesha Rahman',username:'ayesha',hourlyRate:350),
      Person(id:'fahim',name:'Fahim Ahmed',username:'fahim',hourlyRate:300),
      Person(id:'nabila',name:'Nabila Islam',username:'nabila',hourlyRate:310),
      Person(id:'rafi',name:'Rafi Hasan',username:'rafi',hourlyRate:220),
      Person(id:'tanvir',name:'Tanvir Khan',username:'tanvir',hourlyRate:235),
      Person(id:'sadia',name:'Sadia Noor',username:'sadia',hourlyRate:255),
      Person(id:'imran',name:'Imran Hossain',username:'imran',hourlyRate:290),
    ]);
    teams..clear()..addAll([
      CrewTeam(id:'team-1',name:'Site Operations',description:'Daily deployment and field operations',memberIds:['ayesha','fahim','nabila','rafi']),
      CrewTeam(id:'team-2',name:'Logistics Unit',description:'Warehouse, transportation and site movement',memberIds:['fahim','tanvir','sadia']),
      CrewTeam(id:'team-3',name:'Technical Crew',description:'Installation and engineering support',memberIds:['nabila','rafi','imran']),
    ]);
    groups..clear()..addAll([
      WorkGroup(id:'group-1',name:'Industrial Site Alpha',description:'Morning shift · Site operations',
      members:[
        GroupMember(personId:'ayesha',role:'supervisor',assignedOn:'2026-11-12'),
        GroupMember(personId:'fahim',role:'engineer',assignedOn:'2026-11-12'),
        GroupMember(personId:'nabila',role:'engineer',assignedOn:'2026-11-13'),
        GroupMember(personId:'rafi',role:'member',assignedOn:'2026-11-13'),
      ]),
      WorkGroup(id:'group-2',name:'Warehouse Rotation',description:'Logistics and daily warehouse coverage',
      members:[GroupMember(personId:'fahim',role:'supervisor',assignedOn:'2026-11-12'),GroupMember(personId:'tanvir',role:'member',assignedOn:'2026-11-12'),GroupMember(personId:'sadia',role:'engineer',assignedOn:'2026-11-13')]),
      WorkGroup(id:'group-3',name:'Project Delta',description:'Commissioning and field engineering',
      members:[GroupMember(personId:'nabila',role:'supervisor',assignedOn:'2026-11-11'),GroupMember(personId:'imran',role:'engineer',assignedOn:'2026-11-11'),GroupMember(personId:'rafi',role:'member',assignedOn:'2026-11-12')]),
    ]);
    events..clear()..addAll([
      GroupEvent(id:'ev1',groupId:'group-1',kind:'chat',authorId:'ayesha',text:'Good morning team. Please confirm when you reach the site.',timestamp:'2026-11-13T08:31:00'),
      GroupEvent(id:'ev2',groupId:'group-1',kind:'chat',authorId:'fahim',text:'Engineering equipment checked and ready.',timestamp:'2026-11-13T08:39:00'),
      GroupEvent(id:'ev3',groupId:'group-1',kind:'attendance',authorId:'ayesha',text:'Attendance notice for today',timestamp:'2026-11-13T09:00:00',referenceId:'att-1'),
      GroupEvent(id:'ev4',groupId:'group-1',kind:'complaint',authorId:'fahim',text:'The safety equipment needs replacement before the next shift.',timestamp:'2026-11-13T09:18:00',referenceId:'cmp-1'),
    ]);
    attendance..clear()..add(AttendanceReport(id:'att-1',groupId:'group-1',date:'2026-11-13',authorId:'ayesha',createdAt:'2026-11-13T09:00:00',present:{'ayesha':true,'fahim':true,'nabila':true,'rafi':false},
      hours:{'ayesha':9,'fahim':8,'nabila':10,'rafi':0},
      rateSnapshot:{'ayesha':350,'fahim':300,'nabila':310,'rafi':220}));
    complaints..clear()..add(GroupComplaint(id:'cmp-1',groupId:'group-1',authorId:'fahim',text:'The safety equipment needs replacement before the next shift.',status:'Open',createdAt:'2026-11-13T09:18:00'));
    workNotices..clear()..add(WorkNotice(id:'work-1',authorId:'ayesha',company:'Cytech Engineering',location:'North Industrial Plant',date:'2026-11-16',reportingTime:'08:00',memberIds:['fahim','rafi'],createdAt:'2026-11-13T10:10:00',instructions:'Bring safety equipment and report to the site supervisor.'));
  }
  void _load(Map<String,dynamic> m){
    List<T> parse<T>(String key,T Function(Map<String,dynamic>) f)=>
      (m[key] as List? ?? []).map((x)=>f(Map<String,dynamic>.from(x as Map))).toList();
    // Migrate the original v3 sample accounts, which did not have wage fields.
    // Never override any rate explicitly saved by an admin.
    const demoRates=<String,double>{'ayesha':350,'fahim':300,'nabila':310,
      'rafi':220,'tanvir':235,'sadia':255,'imran':290};
    final oldPeople=(m['people'] as List? ?? []).map((value){
      final row=Map<String,dynamic>.from(value as Map);
      if(!row.containsKey('hourlyRate')&&demoRates.containsKey(row['id'])){
        row['hourlyRate']=demoRates[row['id']];
      }
      return Person.fromJson(row);
    });
    people..clear()..addAll(oldPeople);
    teams..clear()..addAll(parse('teams',CrewTeam.fromJson));
    groups..clear()..addAll(parse('groups',WorkGroup.fromJson));
    events..clear()..addAll(parse('events',GroupEvent.fromJson));
    attendance..clear()..addAll(parse('attendance',AttendanceReport.fromJson));
    complaints..clear()..addAll(parse('complaints',GroupComplaint.fromJson));
    workNotices..clear()..addAll(parse('workNotices',WorkNotice.fromJson));
    overtimeMultiplier=(m['overtimeMultiplier'] as num?)?.toDouble()??1.0;
    if(people.isEmpty)seed();
  }
  Map<String,dynamic> _toJson()=>{
    'people':people.map((x)=>x.toJson()).toList(),
    'teams':teams.map((x)=>x.toJson()).toList(),
    'groups':groups.map((x)=>x.toJson()).toList(),
    'events':events.map((x)=>x.toJson()).toList(),
    'attendance':attendance.map((x)=>x.toJson()).toList(),
    'complaints':complaints.map((x)=>x.toJson()).toList(),
    'workNotices':workNotices.map((x)=>x.toJson()).toList(),
    'overtimeMultiplier':overtimeMultiplier,
  };
  void changed(){
    notifyListeners();
    if(_prefs!=null){
      unawaited(_prefs!.setString(storageKey,jsonEncode(_toJson())).then((_) {}).catchError((Object e){
        storageError='Unable to save local data: $e';notifyListeners();}));
    }
  }
  void enter({String username='',bool registering=false}){
    if(registering){
      String candidate=username.trim().isEmpty?'newmember':username.trim().toLowerCase();
      if(people.any((p)=>p.username==candidate)){
        candidate=candidate+people.length.toString();
      }
      final id='user-'+newId();
      people.add(Person(id:id,name:username.trim().isEmpty?'New Member':username.trim(),username:candidate));
      currentUserId=id;
      changed();
    } else {
      final match=people.where((p)=>p.username.toLowerCase()==username.trim().toLowerCase());
      currentUserId=match.isNotEmpty?match.first.id:'admin';
    }
    signedIn=true;notifyListeners();
  }
  void demoAs(String id){if(people.any((p)=>p.id==id)){currentUserId=id;signedIn=true;notifyListeners();}}
  void signOut(){signedIn=false;currentUserId='admin';notifyListeners();}
  void saveTeam({String? id,required String name,required String description,required List<String> members}){
    final item=CrewTeam(id:id??newId(),name:name.trim(),description:description.trim(),memberIds:members.toSet().toList());
    final index=teams.indexWhere((t)=>t.id==id);
    if(index<0){teams.insert(0,item);}else{teams[index]=item;}
    changed();
  }
  void deleteTeam(String id){teams.removeWhere((t)=>t.id==id);changed();}
  String saveGroup({String? id,required String name,required String description,String? imageBase64}){
    final key=id??newId();
    final old=id==null?null:group(id);
    final item=WorkGroup(id:key,name:name.trim(),description:description.trim(),
      imageBase64:imageBase64??old?.imageBase64,members:old?.members??[]);
    final index=groups.indexWhere((x)=>x.id==key);
    if(index<0){groups.insert(0,item);}else{groups[index]=item;}
    changed();return key;
  }
  void deleteGroup(String id){
    if(!isAdmin)throw StateError('Admin only');
    final groupName=group(id).name;
    // Attendance is an independent financial/evidence record. Deleting a group
    // must not erase past scans or the payroll history.
    for(int i=0;i<attendance.length;i++){
      final entry=attendance[i];
      if(entry.groupId==id&&entry.groupName.isEmpty){
        attendance[i]=AttendanceReport.fromJson({...entry.toJson(),'groupName':groupName});
      }
    }
    groups.removeWhere((g)=>g.id==id);
    events.removeWhere((e)=>e.groupId==id);
    complaints.removeWhere((e)=>e.groupId==id);changed();
  }
  void saveAssignments(String groupId,List<GroupMember> members){
    final i=groups.indexWhere((x)=>x.id==groupId);if(i<0)return;
    final g=groups[i];
    groups[i]=WorkGroup(id:g.id,name:g.name,description:g.description,imageBase64:g.imageBase64,
      members:members.fold<List<GroupMember>>([], (acc,m){
        acc.removeWhere((e)=>e.personId==m.personId);
        acc.add(m);return acc;
      }));
    changed();
  }
  void postMessage(String groupId,String text){
    if(text.trim().isEmpty||!canSee(group(groupId)))return;
    events.add(GroupEvent(id:newId(),groupId:groupId,kind:'chat',authorId:currentUserId,
      text:text.trim(),timestamp:DateTime.now().toIso8601String()));changed();
  }
  Future<void> postAttendance(String groupId,DateTime date,Map<String,bool> status,
    {Map<String,double>? hours,PermitEvidence? permit}) async {
    if(!signedIn)throw StateError('Sign in first');
    final g=group(groupId);
    if(!canPublish(g))throw StateError('Only assigned supervisors and admins can publish');
    if(status.isEmpty)throw ArgumentError('Select attendance members');
    if(permit==null||!permit.isValid)throw StateError('A verified Work Permit scan is required');
    if(status.keys.any((id)=>!g.members.any((m)=>m.personId==id))){
      throw StateError('Attendance contains an unassigned worker');
    }
    final cleanHours=<String,double>{};
    for(final item in status.entries){
      final raw=hours?[item.key]??8.0;
      if(!raw.isFinite||raw<0||raw>24)throw ArgumentError('Hours must be between 0 and 24');
      final h=item.value?raw:0.0;
      cleanHours[item.key]=h;
    }
    final now=DateTime.now().toIso8601String(),id=newId();
    final report=AttendanceReport(id:id,groupId:groupId,date:dayKey(date),
      authorId:currentUserId,createdAt:now,present:Map.of(status),
      hours:cleanHours,rateSnapshot:{for(final personId in status.keys)personId:person(personId).hourlyRate},
      otMultiplier:overtimeMultiplier,permit:permit,groupName:g.name);
    final event=GroupEvent(id:'event-'+id,groupId:groupId,kind:'attendance',
      authorId:currentUserId,text:'Official attendance report',timestamp:now,referenceId:id);
    attendance.insert(0,report);events.add(event);
    try {
      final prefs=_prefs;
      if(prefs==null||!await prefs.setString(storageKey,jsonEncode(_toJson()))) {
        throw StateError('Could not save attendance on this device');
      }
    } catch (_) {
      attendance.remove(report);events.remove(event);rethrow;
    }
    notifyListeners();
  }
  void sendComplaint(String groupId,String text){
    final g=group(groupId);if(!canComplain(g)||text.trim().isEmpty)return;
    final now=DateTime.now().toIso8601String(),id=newId();
    complaints.insert(0,GroupComplaint(id:id,groupId:groupId,authorId:currentUserId,
      text:text.trim(),status:'Open',createdAt:now));
    events.add(GroupEvent(id:'event-'+id,groupId:groupId,kind:'complaint',
      authorId:currentUserId,text:text.trim(),timestamp:now,referenceId:id));changed();
  }

  String registerWorker({required String name,required String username,required double hourlyRate}){
    if(!isAdmin)throw StateError('Admin only');
    if(name.trim().isEmpty||username.trim().isEmpty)throw ArgumentError('Worker name and username required');
    if(!hourlyRate.isFinite||hourlyRate<0||hourlyRate>1000000)throw ArgumentError('Hourly rate out of range');
    if(people.any((p)=>p.username.toLowerCase()==username.trim().toLowerCase()))throw StateError('Username already exists');
    final id='worker-'+newId();
    people.add(Person(id:id,name:name.trim(),username:username.trim().toLowerCase(),hourlyRate:hourlyRate));
    changed();return id;
  }
  void setWorkerRate(String id,{required String name,required String username,required double rate}){
    if(!isAdmin)throw StateError('Admin only');
    if(name.trim().isEmpty||username.trim().isEmpty)throw ArgumentError('Worker name and username required');
    if(!rate.isFinite||rate<0||rate>1000000)throw ArgumentError('Hourly rate out of range');
    if(people.any((p)=>p.id!=id&&p.username.toLowerCase()==username.trim().toLowerCase()))throw StateError('Username already exists');
    final i=people.indexWhere((p)=>p.id==id&& !p.isAdmin);
    if(i<0)throw StateError('Worker not found');
    people[i]=Person(id:id,name:name.trim(),username:username.trim().toLowerCase(),hourlyRate:rate);
    changed();
  }
  void setOvertimeMultiplier(double value){
    if(!isAdmin)throw StateError('Admin only');
    if(![1.0,1.5,2.0].contains(value))throw ArgumentError('Unsupported overtime rate');
    overtimeMultiplier=value;changed();
  }
  void createWorkNotice({required String company,required String location,required DateTime date,
    required String reportingTime,required List<String> memberIds,String instructions=''}){
    if(!canPublishWorkNotice)throw StateError('Supervisor or Admin only');
    if(company.trim().isEmpty||location.trim().isEmpty||reportingTime.trim().isEmpty||memberIds.isEmpty){
      throw ArgumentError('Company, location, reporting time and selected members required');
    }
    if(memberIds.any((id)=>!allTeamMemberIds.contains(id)))throw StateError('Workers must be registered team members');
    workNotices.insert(0,WorkNotice(id:newId(),authorId:currentUserId,company:company.trim(),
      location:location.trim(),date:dayKey(date),reportingTime:reportingTime,
      memberIds:memberIds.toSet().toList(),createdAt:DateTime.now().toIso8601String(),
      instructions:instructions.trim()));
    changed();
  }

  void setComplaintStatus(String groupId,String id,String status){
    if(!canReview(group(groupId)))return;
    final i=complaints.indexWhere((c)=>c.id==id&&c.groupId==groupId);
    if(i<0)return;final c=complaints[i];
    complaints[i]=GroupComplaint(id:c.id,groupId:c.groupId,authorId:c.authorId,
      text:c.text,status:status,createdAt:c.createdAt);changed();
  }
}
