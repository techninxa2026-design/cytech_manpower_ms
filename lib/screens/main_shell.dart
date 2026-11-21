import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/cytech_theme.dart';
import 'management_pages.dart';
import 'group_room.dart';
import 'public_notices.dart';
import 'accounts_page.dart';
import 'attendance_records.dart';
import 'engineer_approvals.dart';

void pushPage(BuildContext context,Widget page){
  Navigator.push(context,MaterialPageRoute(builder:(_)=>page));
}
class MainShell extends StatefulWidget{
  const MainShell({super.key,required this.store});
  final AppStore store;
  @override State<MainShell> createState()=>_MainShellState();
}
class _MainShellState extends State<MainShell>{
  int tab=0; String groupFilter='All';String search='';
  final searchController=TextEditingController();
  @override void dispose(){searchController.dispose();super.dispose();}
  AppStore get store=>widget.store;
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:store,builder:(context,_){
    final titles=['Workspace','Groups','Public Notices','Teams',
      store.isAdmin?'Accounts':'Profile',if(store.isAdmin)'Attendance Records',
      if(store.hasEngineerRole)'Approvals'];
    final pending=store.engineerPendingAttendance.length;
    final activeTab=tab>=titles.length?0:tab;
    return Scaffold(
      extendBody:true,
      body:SafeArea(child:Column(children:[
        if(activeTab!=0)Container(color:cyCanvas,padding:const EdgeInsets.fromLTRB(19,17,19,11),
          child:Row(children:[
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              const Text('CYTECH / OPERATIONS',style:TextStyle(color:cyOrange,
                fontSize:9,letterSpacing:1.4,fontWeight:FontWeight.w900)),
              const SizedBox(height:5),
              Text(titles[activeTab],style:const TextStyle(fontWeight:FontWeight.w900,
                color:cyNavy,fontSize:25,letterSpacing:-1)),
            ])),
            if(store.isAdmin&&(tab==1||tab==3))
              IconButton.filled(onPressed:()=>tab==3?
                pushPage(context,TeamEditor(store:store)):
                pushPage(context,GroupEditor(store:store)),
                style:IconButton.styleFrom(backgroundColor:cyOrange),
                icon:const Icon(Icons.add_rounded,color:Colors.white)),
            if(tab==4)const BrandMark(size:30),
          ])),
        Expanded(child:IndexedStack(index:activeTab,children:[
          _dashboard(),
          _groups(),
          WorkNoticeCenter(store:store),
          _teams(),
          store.isAdmin?AccountsCenter(store:store):_profile(),
          if(store.isAdmin)AttendanceRecordsCenter(store:store),
          if(store.hasEngineerRole)EngineerApprovalsCenter(key:ValueKey(store.currentUserId),store:store),
        ])),
      ])),
      bottomNavigationBar:SafeArea(top:false,child:Container(
        margin:const EdgeInsets.fromLTRB(13,0,13,9),
        padding:const EdgeInsets.symmetric(horizontal:7,vertical:7),
        decoration:BoxDecoration(color:cyNavy,
          borderRadius:BorderRadius.circular(23),
          border:Border.all(color:const Color(0xFF24445C),width:1),
          boxShadow:const [BoxShadow(color:Color(0x36051B2E),blurRadius:20,offset:Offset(0,9))]),
        child:Row(children:[
          for(final item in <(String,IconData)>[
            ('Home',Icons.space_dashboard_rounded),
            ('Groups',Icons.forum_rounded),
            ('Notices',Icons.campaign_rounded),
            ('Teams',Icons.groups_rounded),
            (store.isAdmin?'Accounts':'Profile',
              store.isAdmin?Icons.account_balance_wallet_rounded:Icons.person_rounded),
            if(store.isAdmin)('Records',Icons.fact_check_rounded),
            if(store.hasEngineerRole)('Approvals',Icons.verified_rounded),
          ].asMap().entries)Expanded(child:InkWell(
            key:Key('dock_'+item.key.toString()),
            borderRadius:BorderRadius.circular(16),
            onTap:()=>setState(()=>tab=item.key),
            child:AnimatedContainer(duration:const Duration(milliseconds:200),
              padding:const EdgeInsets.symmetric(vertical:8,horizontal:2),
              decoration:BoxDecoration(
                color:activeTab==item.key?cyOrange:Colors.transparent,
                borderRadius:BorderRadius.circular(15)),
              child:Column(mainAxisSize:MainAxisSize.min,children:[
                Stack(clipBehavior:Clip.none,children:[
                  Icon(item.value.$2,size:19,color:activeTab==item.key?Colors.white:const Color(0xFF91A7B8)),
                  if(item.value.$1=='Approvals'&&pending>0)Positioned(top:-6,right:-12,
                    child:Container(padding:const EdgeInsets.symmetric(horizontal:4,vertical:1),
                      decoration:BoxDecoration(color:activeTab==item.key?Colors.white:cyOrange,
                        borderRadius:BorderRadius.circular(10)),
                      child:Text(pending>99?'99+':pending.toString(),style:TextStyle(fontSize:8,
                        fontWeight:FontWeight.w900,color:activeTab==item.key?cyOrange:Colors.white)))),
                ]),
                const SizedBox(height:5),
                FittedBox(fit:BoxFit.scaleDown,
                  child:Text(item.value.$1,style:TextStyle(
                    fontSize:9,fontWeight:FontWeight.w900,
                    color:activeTab==item.key?Colors.white:const Color(0xFF9AB1C2)))),
              ]))))
        ]),
      )),
    );
  });

  Widget _dashboard(){
    final groups=store.visibleGroups,teams=store.visibleTeams;
    final opened=store.complaints.where((c)=>c.status!='Resolved'&&groups.any((g)=>g.id==c.groupId)).length;
    return ListView(children:[
      Container(color:cyNavy,child:Stack(children:[
        Positioned(right:-75,top:-85,child:Transform.rotate(angle:.55,
          child:Container(width:220,height:220,decoration:BoxDecoration(
            border:Border.all(color:Colors.white.withValues(alpha:.05),width:50),
            borderRadius:BorderRadius.circular(55))))),
        Padding(padding:const EdgeInsets.fromLTRB(21,23,21,53),child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            const BrandLockup(dark:true,compact:true),const Spacer(),
            InkWell(onTap:()=>store.isAdmin?Navigator.push(context,MaterialPageRoute(
              builder:(_)=>Scaffold(appBar:AppBar(title:const Text('Profile')),
                body:SafeArea(child:_profile())))):setState(()=>tab=4),
              child:PersonAvatar(store.me,size:40)),
          ]),
          const SizedBox(height:27),
          Text('HELLO, '+(store.isAdmin?'ADMIN':store.me.name.split(' ').first.toUpperCase()),
            style:const TextStyle(color:cyOrange,fontSize:11,letterSpacing:2,fontWeight:FontWeight.w900)),
          const SizedBox(height:10),
          const Text('People in sync.\nWork in motion.',style:TextStyle(
            color:Colors.white,fontSize:31,fontWeight:FontWeight.w900,height:1.1,letterSpacing:-1.6)),
          const SizedBox(height:11),
          Text(store.isAdmin?'Your entire manpower operation at a glance.':
            'Your assigned teams, conversations and site activities in one place.',
            style:const TextStyle(fontSize:12,color:Color(0xFFB5C6D5),height:1.6)),
        ]))
      ])),
      Transform.translate(offset:const Offset(0,-26),
        child:Padding(padding:const EdgeInsets.symmetric(horizontal:19),
          child:Row(children:[
            Expanded(child:_stat(Icons.groups_outlined,store.isAdmin?store.allTeamMemberIds.length:teams.length,
              store.isAdmin?'People':'My teams')),
            const SizedBox(width:9),
            Expanded(child:_stat(Icons.forum_outlined,groups.length,'Groups')),
            const SizedBox(width:9),
            Expanded(child:_stat(Icons.report_problem_outlined,opened,'Open issues')),
          ]))),
      Padding(padding:const EdgeInsets.fromLTRB(19,0,19,30),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          if(store.hasEngineerRole&&store.engineerPendingAttendance.isNotEmpty)...[
            CyCard(onTap:()=>setState(()=>tab=5),child:Row(children:[
              const Icon(Icons.pending_actions_rounded,color:cyOrange,size:26),const SizedBox(width:10),
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(store.engineerPendingAttendance.length.toString()+' attendance approval(s) pending',
                  style:const TextStyle(color:cyNavy,fontSize:13,fontWeight:FontWeight.w900)),
                const Text('Review your assigned groups',style:TextStyle(color:cyMuted,fontSize:11)),
              ])),const Icon(Icons.chevron_right_rounded,color:cyOrange),
            ])),
            const SizedBox(height:16),
          ],
          const Text('QUICK OPERATIONS',style:TextStyle(color:cyOrange,
            fontWeight:FontWeight.w900,fontSize:10,letterSpacing:1.5)),
          const SizedBox(height:12),
          Row(children:[
            Expanded(child:_shortcut(
              icon:Icons.forum_rounded,title:'Group workspace',subtitle:'Chat & notices',
              orange:true,onTap:()=>setState(()=>tab=1))),
            const SizedBox(width:11),
            Expanded(child:_shortcut(
              icon:Icons.groups_2_outlined,title:'Manage teams',subtitle:'Members & roles',
              onTap:()=>setState(()=>tab=3))),
          ]),
          if(store.isAdmin)...[
            const SizedBox(height:10),
            Row(children:[
              Expanded(child:_shortcut(icon:Icons.add_circle_outline_rounded,
                title:'Create group',subtitle:'Build a workspace',
                onTap:()=>pushPage(context,GroupEditor(store:store)))),
              const SizedBox(width:11),
              Expanded(child:_shortcut(icon:Icons.person_add_alt_1_rounded,
                title:'Create team',subtitle:'Assign registered users',
                onTap:()=>pushPage(context,TeamEditor(store:store)))),
            ]),
          ],
          SectionTitle('Active workspaces',action:'VIEW ALL',onTap:()=>setState(()=>tab=1)),
          if(groups.isEmpty)const EmptyPanel(title:'No groups yet',
            message:'An admin can create a group and assign you to it.',icon:Icons.forum_outlined),
          for(final g in groups.take(3))Padding(padding:const EdgeInsets.only(bottom:9),
            child:_groupCard(g)),
          SectionTitle('Latest operational updates',action:'GROUPS',onTap:()=>setState(()=>tab=1)),
          _updates(groups),
          const SizedBox(height:10),
          const InfoBanner('Offline preview: your changes are saved only on this Android device. '
            'Chats and notices do not synchronize with other phones yet.',color:cyNavy),
        ])),
    ]);
  }
  Widget _stat(IconData icon,int value,String label)=>CyCard(
    padding:const EdgeInsets.symmetric(horizontal:12,vertical:14),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Icon(icon,color:cyOrange,size:21),
      const SizedBox(height:9),
      Text(value.toString(),style:const TextStyle(
        color:cyNavy,fontWeight:FontWeight.w900,fontSize:25,letterSpacing:-1)),
      Text(label,style:const TextStyle(color:cyMuted,fontWeight:FontWeight.w700,fontSize:10),
        maxLines:1,overflow:TextOverflow.ellipsis)
    ]));
  Widget _shortcut({required IconData icon,required String title,required String subtitle,
    required VoidCallback onTap,bool orange=false})=>CyCard(
      onTap:onTap,color:orange?cyOrange:Colors.white,
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Container(padding:const EdgeInsets.all(9),decoration:BoxDecoration(
          color:orange?Colors.white.withValues(alpha:.18):cyOrangeSoft,
          borderRadius:BorderRadius.circular(11)),
          child:Icon(icon,color:orange?Colors.white:cyOrange,size:21)),
        const SizedBox(height:13),
        Text(title,style:TextStyle(color:orange?Colors.white:cyNavy,
          fontWeight:FontWeight.w900,fontSize:13)),
        const SizedBox(height:4),
        Text(subtitle,style:TextStyle(color:orange?Colors.white70:cyMuted,fontSize:10)),
      ]));
  Widget _updates(List<WorkGroup> visible){
    final item=store.events.where((e)=>e.kind!='chat'&&visible.any((g)=>g.id==e.groupId)).toList()
      ..sort((a,b)=>b.timestamp.compareTo(a.timestamp));
    if(item.isEmpty)return const EmptyPanel(title:'No new updates',
      message:'Attendance notices and complaints will appear here.');
    return Column(children:[
      for(final e in item.take(3))Padding(padding:const EdgeInsets.only(bottom:9),
        child:CyCard(onTap:()=>pushPage(context,GroupRoom(store:store,groupId:e.groupId,
          initialTab:e.kind=='attendance'?1:2)),child:Row(children:[
          Container(width:40,height:40,decoration:BoxDecoration(
            color:e.kind=='attendance'?cyOrangeSoft:const Color(0xFFF0EDFF),
            borderRadius:BorderRadius.circular(11)),
            child:Icon(e.kind=='attendance'?Icons.fact_check_outlined:Icons.report_outlined,
              color:e.kind=='attendance'?cyOrange:cyPurple)),
          const SizedBox(width:11),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(e.kind=='attendance'?'OFFICIAL ATTENDANCE NOTICE':'ENGINEER COMPLAINT',
              style:TextStyle(fontSize:10,fontWeight:FontWeight.w900,
                color:e.kind=='attendance'?cyOrange:cyPurple)),
            const SizedBox(height:4),
            Text(store.group(e.groupId).name,maxLines:1,overflow:TextOverflow.ellipsis,
              style:const TextStyle(color:cyNavy,fontWeight:FontWeight.w900,fontSize:12)),
            Text(store.person(e.authorId).name,
              style:const TextStyle(color:cyMuted,fontSize:10))
          ])),
          const Icon(Icons.chevron_right_rounded,color:cyMuted)
        ])))
    ]);
  }
  Widget _teams(){
    final teams=store.visibleTeams;
    return ListView(padding:const EdgeInsets.fromLTRB(19,5,19,90),children:[
      const Text('YOUR PEOPLE, ORGANIZED',style:TextStyle(fontSize:10,
        color:cyOrange,letterSpacing:1.4,fontWeight:FontWeight.w900)),
      const SizedBox(height:8),
      Text(store.isAdmin?'Build your workforce.':'Your assigned teams.',
        style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900,color:cyNavy)),
      const SizedBox(height:7),
      Text(store.isAdmin?'Create teams from registered users. A user may join multiple teams.':
        'Teams that include your account appear here.',style:const TextStyle(color:cyMuted,fontSize:12,height:1.5)),
      const SizedBox(height:16),
      if(store.isAdmin)CyCard(onTap:()=>pushPage(context,TeamEditor(store:store)),
        color:cyNavy,child:const Row(children:[
          CircleAvatar(backgroundColor:Color(0xFF294761),
            child:Icon(Icons.add_rounded,color:cyOrange)),SizedBox(width:11),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('CREATE A NEW TEAM',style:TextStyle(color:Colors.white,
              fontSize:12,fontWeight:FontWeight.w900)),
            Text('Select one or many registered members',
              style:TextStyle(color:Color(0xFFBAC7D6),fontSize:10))
          ])),
          Icon(Icons.arrow_forward_ios_rounded,color:Colors.white70,size:14)
        ])),
      SectionTitle('All teams',action:teams.length.toString()+' TEAMS'),
      if(teams.isEmpty)const EmptyPanel(title:'No assigned teams',
        message:'Your administrator will add you to a team.'),
      for(final team in teams)Padding(padding:const EdgeInsets.only(bottom:10),
        child:CyCard(onTap:()=>pushPage(context,TeamDetail(store:store,teamId:team.id)),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[
              Container(width:49,height:49,decoration:BoxDecoration(
                color:cyOrangeSoft,borderRadius:BorderRadius.circular(14)),
                child:const Icon(Icons.engineering_rounded,color:cyOrange,size:26)),
              const SizedBox(width:11),
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(team.name,style:const TextStyle(fontWeight:FontWeight.w900,color:cyNavy,fontSize:14)),
                const SizedBox(height:4),
                Text(team.description,maxLines:2,overflow:TextOverflow.ellipsis,
                  style:const TextStyle(color:cyMuted,fontSize:11,height:1.4)),
              ])),
              const Icon(Icons.chevron_right_rounded,color:cyMuted),
            ]),
            const Divider(height:24),
            Row(children:[
              AvatarStack(ids:team.memberIds,store:store),const Spacer(),
              StatusPill(team.memberIds.length.toString()+' MEMBERS'),
            ])
          ]))),
    ]);
  }
  Widget _groups(){
    List<WorkGroup> groups=store.visibleGroups.where((g)=>
      g.name.toLowerCase().contains(search.toLowerCase())).toList();
    if(groupFilter=='With notices'){
      groups=groups.where((g)=>store.reportsFor(g.id).isNotEmpty).toList();
    }
    if(groupFilter=='With issues'){
      groups=groups.where((g)=>store.complaintsFor(g.id).isNotEmpty).toList();
    }
    return ListView(padding:const EdgeInsets.fromLTRB(19,5,19,90),children:[
      const Text('PROJECT SPACES',style:TextStyle(fontSize:10,
        color:cyOrange,letterSpacing:1.5,fontWeight:FontWeight.w900)),
      const SizedBox(height:8),
      const Text('Group conversations.',style:TextStyle(
        color:cyNavy,fontWeight:FontWeight.w900,fontSize:21)),
      const SizedBox(height:5),
      const Text('Chat, attendance notices, engineering issues and team members.',
        style:TextStyle(color:cyMuted,fontSize:12,height:1.55)),
      const SizedBox(height:18),
      TextField(controller:searchController,onChanged:(v)=>setState(()=>search=v),
        decoration:const InputDecoration(prefixIcon:Icon(Icons.search_rounded),
          hintText:'Search your groups...')),
      const SizedBox(height:13),
      SizedBox(height:37,child:ListView(scrollDirection:Axis.horizontal,children:[
        for(final filter in ['All','With notices','With issues'])
          Padding(padding:const EdgeInsets.only(right:7),child:ChoiceChip(
            label:Text(filter,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w800)),
            selected:groupFilter==filter,
            onSelected:(_)=>setState(()=>groupFilter=filter),
            selectedColor:cyNavy,backgroundColor:Colors.white,
            labelStyle:TextStyle(color:groupFilter==filter?Colors.white:cyMuted),
            side:BorderSide(color:groupFilter==filter?cyNavy:cyLine))),
      ])),
      SectionTitle('Available groups',action:groups.length.toString()+' RESULTS'),
      if(groups.isEmpty)const EmptyPanel(title:'No matching groups',
        message:'Try a different search or ask the admin for access.'),
      for(final g in groups)Padding(padding:const EdgeInsets.only(bottom:11),child:_groupCard(g)),
      if(store.isAdmin)Padding(padding:const EdgeInsets.only(top:10),
        child:SizedBox(width:double.infinity,child:FilledButton.icon(
          onPressed:()=>pushPage(context,GroupEditor(store:store)),
          icon:const Icon(Icons.add_rounded),label:const Text('CREATE GROUP')))),
    ]);
  }
  Widget _groupCard(WorkGroup g){
    final notices=store.reportsFor(g.id),issues=store.complaintsFor(g.id);
    return CyCard(onTap:()=>pushPage(context,GroupRoom(store:store,groupId:g.id)),
      child:Column(children:[
        Row(children:[
          GroupArtwork(group:g,size:54),const SizedBox(width:12),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(g.name,maxLines:1,overflow:TextOverflow.ellipsis,
              style:const TextStyle(color:cyNavy,fontSize:14,fontWeight:FontWeight.w900)),
            const SizedBox(height:3),
            Text(g.description,maxLines:1,overflow:TextOverflow.ellipsis,
              style:const TextStyle(color:cyMuted,fontSize:10)),
            const SizedBox(height:6),
            StatusPill(store.roleFor(g).toUpperCase(),
              background:cyOrangeSoft,tint:cyOrange),
          ])),
          const Icon(Icons.chevron_right_rounded,color:cyMuted),
        ]),
        const Divider(height:22),
        Row(children:[
          AvatarStack(ids:g.members.map((m)=>m.personId).toList(),store:store),
          const Spacer(),
          if(notices.isNotEmpty)const Icon(Icons.campaign_rounded,color:cyOrange,size:16),
          if(notices.isNotEmpty)const SizedBox(width:4),
          if(notices.isNotEmpty)Text(notices.length.toString(),style:const TextStyle(
            fontSize:11,fontWeight:FontWeight.w900,color:cyOrange)),
          if(issues.isNotEmpty)const SizedBox(width:11),
          if(issues.isNotEmpty)const Icon(Icons.report_problem_rounded,color:cyPurple,size:16),
          if(issues.isNotEmpty)const SizedBox(width:4),
          if(issues.isNotEmpty)Text(issues.length.toString(),style:const TextStyle(
            fontSize:11,fontWeight:FontWeight.w900,color:cyPurple)),
          const SizedBox(width:8),
          const Text('OPEN CHAT',style:TextStyle(color:cyNavy,fontSize:10,fontWeight:FontWeight.w900))
        ])
      ]));
  }
  Widget _profile()=>ListView(padding:const EdgeInsets.fromLTRB(19,5,19,40),children:[
    CyCard(color:cyNavy,child:Row(children:[
      PersonAvatar(store.me,size:55),const SizedBox(width:13),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(store.me.name,style:const TextStyle(
          color:Colors.white,fontWeight:FontWeight.w900,fontSize:16)),
        const SizedBox(height:5),
        Text('@'+store.me.username,style:const TextStyle(
          color:Color(0xFFB5C9D9),fontSize:11)),
        const SizedBox(height:8),
        StatusPill(store.currentRole.toUpperCase())
      ])),
      const BrandMark(size:28),
    ])),
    const SectionTitle('Demo persona switcher'),
    const InfoBanner('Preview-only role switching lets you test Admin, Supervisor, '
      'Engineer and Member screens. This is not a production security feature.'),
    const SizedBox(height:12),
    for(final entry in [
      ('admin','Workspace Admin'),('ayesha','Supervisor · Site Alpha'),
      ('fahim','Engineer · Site Alpha'),('rafi','General Member'),
      ('nabila','Supervisor · Project Delta'),
    ])Padding(padding:const EdgeInsets.only(bottom:8),
      child:CyCard(onTap:(){
        store.demoAs(entry.$1);
        Navigator.of(context).popUntil((route)=>route.isFirst);
        setState(()=>tab=0);
        toast(context,'Previewing as '+entry.$2);
      },child:Row(children:[
        PersonAvatar(store.person(entry.$1)),const SizedBox(width:12),
        Expanded(child:Text(entry.$2,style:const TextStyle(
          color:cyNavy,fontWeight:FontWeight.w800,fontSize:12))),
        if(store.currentUserId==entry.$1)
          const Icon(Icons.check_circle_rounded,color:cyOrange,size:20)
        else const Icon(Icons.chevron_right_rounded,color:cyMuted)
      ]))),
    const SectionTitle('Account & application'),
    CyCard(child:Column(children:[
      ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.people_alt_outlined,color:cyOrange),
        title:const Text('Registered demo users',style:TextStyle(fontWeight:FontWeight.w800)),
        trailing:Text(store.people.length.toString())),
      const Divider(),
      const ListTile(contentPadding:EdgeInsets.zero,
        leading:Icon(Icons.storage_outlined,color:cyOrange),
        title:Text('Local-only data storage',style:TextStyle(fontWeight:FontWeight.w800)),
        subtitle:Text('This phone only. No cloud synchronization.')),
      const Divider(),
      ListTile(contentPadding:EdgeInsets.zero,
        leading:const Icon(Icons.logout_rounded,color:cyOrange),
        title:const Text('Sign out',style:TextStyle(fontWeight:FontWeight.w800)),
        onTap:(){
          Navigator.of(context).popUntil((route)=>route.isFirst);
          store.signOut();
        }),
    ])),
  ]);
}
