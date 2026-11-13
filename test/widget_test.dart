import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cytech_mms/main.dart';
import 'package:cytech_mms/core/app_store.dart';
import 'package:cytech_mms/core/cytech_theme.dart';
import 'package:cytech_mms/screens/group_room.dart';

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
}
