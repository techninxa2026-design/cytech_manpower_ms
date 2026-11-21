import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cytech_mms/core/permit_evidence.dart';
import 'package:cytech_mms/core/permit_matcher.dart';
import 'package:cytech_mms/screens/attendance_records.dart';
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
  late Directory evidenceDirectory;
  late PermitEvidence evidence;
  setUp(()async{
    SharedPreferences.setMockInitialValues({});
    evidenceDirectory=await Directory.systemTemp.createTemp('cytech-test-');
    // Persistence fixture only: real OCR is tested separately on an Android device.
    final file=await File(evidenceDirectory.path+'/test.jpg').writeAsBytes([1,2,3]);
    evidence=PermitEvidence(code:'16385',imagePath:file.path,scannedAt:'2026-11-21T10:00:00');
  });
  tearDown(()async{await evidenceDirectory.delete(recursive:true);});

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
    await store.postAttendance(group.id,DateTime(2026,11,14),{'ayesha':true,'fahim':false},permit:evidence);
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
    await store.postAttendance('group-1',DateTime(2026,11,14),{'fahim':true,'rafi':false},
      hours:{'fahim':9,'rafi':0},permit:evidence);
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
    await store.postAttendance('group-1',DateTime(2026,11,14),{'fahim':true},
      hours:{'fahim':8},permit:evidence);
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
    expect(find.text('Every hour.\nEvery taka.'),findsOneWidget);
    await tester.tap(find.byKey(const Key('dock_2')));
    await tester.pumpAndSettle();
    expect(find.text('Know where.\nKnow when.'),findsOneWidget);
  });

  test('permit matcher recognizes top-right PTW serial and rejects ambiguous or incomplete scans',(){
    final lines=[
      const PermitText('Permit-to-Work: General Work',Rect.fromLTWH(310,170,420,25)),
      const PermitText('PTW No.',Rect.fromLTWH(820,164,95,20)),
      const PermitText('Date of issue',Rect.fromLTWH(820,190,100,18)),
      const PermitText('PART 1',Rect.fromLTWH(450,304,100,20)),
      const PermitText('LOCATION of work',Rect.fromLTWH(100,331,150,18)),
      const PermitText('POST-PERMIT MEASURES required',Rect.fromLTWH(100,1190,350,22)),
    ];
    const size=Size(1204,1600);
    const target=PermitText('16385',Rect.fromLTWH(895,267,82,26),confidence:.95);
    const elsewhere=PermitText('99999',Rect.fromLTWH(901,900,75,18),confidence:.99);
    expect(PermitMatcher.match(lines,[target,elsewhere],size)?.code,'16385');
    expect(PermitMatcher.match(lines,[elsewhere],size),isNull);
    expect(PermitMatcher.match(lines,[target,
      const PermitText('12345',Rect.fromLTWH(970,263,70,24))],size),isNull);
    expect(PermitMatcher.match(lines.take(5).toList(),[target],size),isNull);
    expect(PermitMatcher.match(lines,[target],const Size(480,640)),isNull);
    expect(PermitMatcher.match(lines,[const PermitText('16385',
      Rect.fromLTWH(895,267,82,26),confidence:.3)],size),isNull);
  });

  test('attendance requires evidence, retains it across restart and group deletion',()async{
    final store=AppStore();await store.initialize();store.enter(username:'ayesha');
    final before=store.attendance.length;
    await expectLater(store.postAttendance('group-1',DateTime(2026,11,21),{'fahim':true}),
      throwsStateError);
    expect(store.attendance.length,before);
    final invalid=PermitEvidence(code:'wrong',imagePath:evidence.imagePath,scannedAt:evidence.scannedAt);
    await expectLater(store.postAttendance('group-1',DateTime(2026,11,21),{'fahim':true},permit:invalid),
      throwsStateError);
    await store.postAttendance('group-1',DateTime(2026,11,21),{'fahim':true},
      hours:{'fahim':9},permit:evidence);
    final restored=AppStore();await restored.initialize();restored.enter(username:'admin');
    final record=restored.attendance.firstWhere((a)=>a.date=='2026-11-21');
    expect(record.permit?.code,'16385');
    expect(record.permit?.isValid,isTrue);
    expect(record.hoursFor('fahim'),9);
    expect(record.overtimeFor('fahim'),1);
    restored.deleteGroup('group-1');
    expect(restored.attendance.any((a)=>a.id==record.id),isTrue);
    expect(restored.attendance.firstWhere((a)=>a.id==record.id).groupName,'Industrial Site Alpha');
    expect(PayrollEngine.month(restored,DateTime(2026,11)).workers
      .firstWhere((w)=>w.person.id=='fahim').lines.any((l)=>l.date=='2026-11-21'),isTrue);
    restored.demoAs('rafi');
    await expectLater(restored.postAttendance('group-2',DateTime(2026,11,21),{'tanvir':true},
      permit:evidence),throwsStateError);
  });

  testWidgets('attendance publish is disabled before a verified Work Permit',(tester)async{
    final store=AppStore();await store.initialize();store.enter(username:'admin');
    await tester.pumpWidget(MaterialApp(theme:cytechTheme(),
      home:AttendanceEditor(store:store,groupId:'group-1')));
    await tester.pumpAndSettle();
    final button=tester.widget<FilledButton>(find.byKey(const Key('publish_attendance')));
    expect(button.onPressed,isNull);
    expect(find.text('VERIFY WORK PERMIT FIRST'),findsOneWidget);
  });

  testWidgets('admin dock has records, member dock does not',(tester)async{
    final store=AppStore();await store.initialize();store.enter(username:'admin');
    await tester.pumpWidget(MyApp(store:store));await tester.pumpAndSettle();
    expect(find.byKey(const Key('dock_5')),findsOneWidget);
    await tester.tap(find.byKey(const Key('dock_5')));await tester.pumpAndSettle();
    expect(find.text('Attendance Records'),findsOneWidget);
    store.demoAs('rafi');await tester.pumpAndSettle();
    expect(find.byKey(const Key('dock_5')),findsNothing);
  });

  test('engineer approval is individual, role-scoped, durable and revision-specific',()async{
    final store=AppStore();await store.initialize();store.enter(username:'ayesha');
    await store.postAttendance('group-1',DateTime(2026,11,22),
      {'fahim':true,'nabila':true},hours:{'fahim':9,'nabila':8},permit:evidence);
    final report=store.attendance.first;
    expect(report.approvals,isEmpty);
    await expectLater(store.approveAttendance(report.id),throwsStateError);
    store.demoAs('rafi');
    await expectLater(store.approveAttendance(report.id),throwsStateError);
    store.demoAs('admin');
    await expectLater(store.approveAttendance(report.id),throwsStateError);
    store.demoAs('sadia');
    await expectLater(store.approveAttendance(report.id),throwsStateError);
    store.demoAs('fahim'); // Also a supervisor in a different group.
    expect(store.hasEngineerRole,isTrue);
    expect(store.engineerPendingAttendance.any((a)=>a.id==report.id),isTrue);
    await store.approveAttendance(report.id);
    expect(store.attendanceById(report.id)!.approvals['fahim']!.engineerName,'Fahim Ahmed');
    expect(store.engineerPendingAttendance.any((a)=>a.id==report.id),isFalse);
    expect(store.engineerApprovedAttendance.any((a)=>a.id==report.id),isTrue);
    await expectLater(store.approveAttendance(report.id),throwsStateError);
    store.demoAs('nabila');
    expect(store.engineerPendingAttendance.any((a)=>a.id==report.id),isTrue);
    await store.approveAttendance(report.id);
    final restored=AppStore();await restored.initialize();restored.enter(username:'admin');
    final saved=restored.attendanceById(report.id)!;
    expect(saved.approvals.keys,containsAll(['fahim','nabila']));
    expect(saved.approvals['fahim']!.approvedAt,isNotEmpty);
    expect(saved.hoursFor('fahim'),9);
    expect(saved.permit!.code,evidence.code);
    await restored.postAttendance('group-1',DateTime(2026,11,22),
      {'fahim':true,'nabila':true},hours:{'fahim':8,'nabila':8},permit:evidence);
    final corrected=restored.attendance.first;
    expect(corrected.id,isNot(report.id));
    expect(corrected.approvals,isEmpty);
    expect(restored.isCurrentAttendance(saved),isFalse);
    restored.demoAs('fahim');
    expect(restored.engineerPendingAttendance.any((a)=>a.id==corrected.id),isTrue);
    expect(restored.engineerApprovedAttendance.any((a)=>a.id==report.id),isTrue);
    expect(restored.canApproveAttendance(saved),isFalse);
  });

  testWidgets('engineer approvals navigation and confirmation update the same record',(tester)async{
    final store=AppStore();await store.initialize();store.enter(username:'fahim');
    // Engineer of Site Alpha, supervisor of Warehouse. Legacy sample is pending.
    final report=store.engineerPendingAttendance.first;
    await tester.pumpWidget(MyApp(store:store));await tester.pumpAndSettle();
    expect(find.byKey(const Key('dock_5')),findsOneWidget);
    await tester.tap(find.byKey(const Key('dock_5')));await tester.pumpAndSettle();
    expect(find.text('Approvals'),findsWidgets);
    expect(find.byKey(const Key('approval_pending_tab')),findsOneWidget);
    final review=find.text('Review & approve');
    await tester.ensureVisible(review.first);
    await tester.tap(review.first);await tester.pumpAndSettle();
    expect(find.byType(AttendanceRecordDetail),findsOneWidget);
    await tester.tap(find.byKey(const Key('approve_attendance')));await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm approval'));await tester.pumpAndSettle();
    expect(store.attendanceById(report.id)!.approvals.containsKey('fahim'),isTrue);
    expect(find.byKey(const Key('approve_attendance')),findsNothing);
    expect(find.text('ENGINEER APPROVED'),findsWidgets);
    await tester.pageBack();await tester.pumpAndSettle();
    expect(store.engineerPendingAttendance.any((a)=>a.id==report.id),isFalse);
    expect(store.engineerApprovedAttendance.any((a)=>a.id==report.id),isTrue);
  });
}
