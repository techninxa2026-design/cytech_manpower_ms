import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cytech_mms/main.dart';
import 'package:cytech_mms/core/app_store.dart';
import 'package:cytech_mms/core/cytech_theme.dart';
import 'package:cytech_mms/screens/group_room.dart';
import 'package:cytech_mms/core/payroll.dart';
import 'package:cytech_mms/core/payroll_pdf.dart';

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(()=>SharedPreferences.setMockInitialValues({}));

  test('seeded project data contains people, teams, groups and group events',()async{
    final store=AppStore();await store.initialize();
    expect(store.people.length,greaterThan(4));
    expect(store.teams.length,3);
    expect(store.groups.length,3);
    expect(store.groupEvents('group-1'),isNotEmpty);
  });
  test('only admin creates groups and teams; supervisor can post attendance',()async{
    final store=AppStore();await store.initialize();
    store.enter(username:'ayesha');
    final group=store.group('group-1');
    expect(store.isAdmin,isFalse);
    expect(store.canPublish(group),isTrue);
    expect(store.canComplain(group),isFalse);
    final before=store.reportsFor(group.id).length;
    store.postAttendance(group.id,DateTime(2026,11,14),{'ayesha':true,'fahim':false});
    expect(store.reportsFor(group.id).length,before+1);
    store.enter(username:'fahim');
    expect(store.canPublish(group),isFalse);
    expect(store.canComplain(group),isTrue);
    final old=store.complaintsFor(group.id).length;
    store.sendComplaint(group.id,'Field electrical panel needs inspection');
    expect(store.complaintsFor(group.id).length,old+1);
    store.enter(username:'admin');
    store.setComplaintStatus(group.id,store.complaintsFor(group.id).first.id,'Resolved');
    expect(store.complaintsFor(group.id).first.status,'Resolved');
  });
  test('offline store supports team creation and role-based group assignment',()async{
    final store=AppStore();await store.initialize();
    store.enter(username:'admin');
    store.saveTeam(name:'New Night Crew',description:'Night shift',members:['fahim','sadia']);
    expect(store.teams.first.memberIds,contains('sadia'));
    final id=store.saveGroup(name:'Night Site',description:'Test group');
    store.saveAssignments(id,[
      GroupMember(personId:'fahim',role:'supervisor',assignedOn:'2026-11-14'),
      GroupMember(personId:'sadia',role:'engineer',assignedOn:'2026-11-14')
    ]);
    expect(store.group(id).members.length,2);
    store.demoAs('fahim');
    expect(store.canPublish(store.group(id)),isTrue);
    store.demoAs('sadia');
    expect(store.canComplain(store.group(id)),isTrue);
  });
  testWidgets('branded splash opens sign-in and bypasses demo authentication',(tester)async{
    final store=AppStore();await store.initialize();
    await tester.pumpWidget(MyApp(store:store));
    expect(find.text('YOUR PEOPLE.\nONE POWERFUL\nWORKSPACE.'),findsOneWidget);
    final open=find.text('I ALREADY HAVE AN ACCOUNT');
    await tester.ensureVisible(open);
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(find.text('Sign in to Cytech.'),findsOneWidget);
    await tester.tap(find.byKey(const Key('login_continue')));
    await tester.pumpAndSettle();
    expect(store.signedIn,isTrue);
    expect(find.text('People in sync.\nWork in motion.'),findsOneWidget);
  });

  testWidgets('assigned engineer can send a chat message in group UI',(tester)async{
    final store=AppStore();await store.initialize();
    store.enter(username:'fahim');
    await tester.pumpWidget(MaterialApp(theme:cytechTheme(),
      home:GroupRoom(store:store,groupId:'group-1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('group_chat_input')),
      'QA chat message from engineer');
    await tester.tap(find.byKey(const Key('send_chat')));
    await tester.pump();
    expect(store.groupEvents('group-1').last.text,'QA chat message from engineer');
  });

  test('payroll uses hours, OT and published rate snapshots',()async{
    final store=AppStore();await store.initialize();
    store.enter(username:'admin');
    store.setOvertimeMultiplier(1.5);
    store.postAttendance('group-1',DateTime(2026,11,14),{'fahim':true,'rafi':false},
      hours:{'fahim':9,'rafi':0});
    final before=PayrollEngine.month(store,DateTime(2026,11));
    final fahim=before.workers.firstWhere((r)=>r.person.id=='fahim');
    final shift=fahim.lines.firstWhere((l)=>l.date=='2026-11-14');
    expect(shift.regularHours,8);
    expect(shift.overtimeHours,1);
    expect(shift.regularPay,2400);
    expect(shift.overtimePay,450);
    expect(shift.gross,2850);
    store.setWorkerRate('fahim',name:'Fahim Ahmed',username:'fahim',rate:450);
    final after=PayrollEngine.month(store,DateTime(2026,11));
    final historic=after.workers.firstWhere((r)=>r.person.id=='fahim')
      .lines.firstWhere((l)=>l.date=='2026-11-14');
    expect(historic.rate,300);
    expect(historic.gross,2850);
    // Another report for the same group/date replaces the first payroll entry.
    store.postAttendance('group-1',DateTime(2026,11,14),{'fahim':true},
      hours:{'fahim':8});
    final current=PayrollEngine.month(store,DateTime(2026,11))
      .workers.firstWhere((r)=>r.person.id=='fahim');
    expect(current.lines.where((l)=>l.date=='2026-11-14').length,1);
    expect(current.lines.firstWhere((l)=>l.date=='2026-11-14').gross,3600);
  });

  test('public work notices are supervisor-created and member-filtered',()async{
    final store=AppStore();await store.initialize();
    store.enter(username:'ayesha');
    expect(store.canPublishWorkNotice,isTrue);
    store.createWorkNotice(company:'Demo Engineering Ltd',location:'Site South',
      date:DateTime(2026,12,1),reportingTime:'07:30',
      memberIds:['fahim','tanvir'],instructions:'Report to gate 3');
    store.demoAs('fahim');
    expect(store.canPublishWorkNotice,isTrue); // Supervisor of Warehouse group.
    expect(store.visibleWorkNotices.any((n)=>n.company=='Demo Engineering Ltd'),isTrue);
    store.demoAs('rafi');
    expect(store.canPublishWorkNotice,isFalse);
    expect(store.visibleWorkNotices.any((n)=>n.company=='Demo Engineering Ltd'),isFalse);
    expect(()=>store.createWorkNotice(company:'Restricted',location:'Site',
      date:DateTime(2026,12,1),reportingTime:'08:00',memberIds:['fahim']),
      throwsStateError);
  });

  test('admin worker registration and payroll PDF are available offline',()async{
    final store=AppStore();await store.initialize();
    store.enter(username:'admin');
    final id=store.registerWorker(name:'New Worker',username:'newworker',hourlyRate:250);
    expect(store.person(id).hourlyRate,250);
    store.saveTeam(name:'New Team',description:'Shift',members:[id]);
    expect(store.allTeamMemberIds,contains(id));
    final pdf=await PayrollPdf.build(store,PayrollEngine.month(store,DateTime(2026,11)));
    expect(pdf.length,greaterThan(700));
    // The app cannot expose admin PDF from non-admin demo personas.
    store.demoAs('rafi');
    expect(()=>store.setWorkerRate(id,name:'New Worker',username:'newworker',rate:100),
      throwsStateError);
  });

  testWidgets('polished admin dock exposes accounts and public notices',(tester)async{
    final store=AppStore();await store.initialize();store.enter(username:'admin');
    await tester.pumpWidget(MyApp(store:store));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dock_4')),findsOneWidget);
    await tester.tap(find.byKey(const Key('dock_4')));
    await tester.pumpAndSettle();
    expect(find.text('Monthly earnings'),findsOneWidget);
    await tester.tap(find.byKey(const Key('dock_2')));
    await tester.pumpAndSettle();
    expect(find.text('Published notices'),findsOneWidget);
  });
}
