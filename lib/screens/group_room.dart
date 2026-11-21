import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/cytech_theme.dart';
import 'management_pages.dart';
import '../core/payroll.dart';
import 'dart:io';
import '../core/permit_scanner.dart';
import '../core/permit_evidence.dart';
import 'work_permit_field.dart';

class GroupRoom extends StatefulWidget{
  const GroupRoom({super.key,required this.store,required this.groupId,this.initialTab=0});
  final AppStore store;final String groupId;final int initialTab;
  @override State<GroupRoom> createState()=>_GroupRoomState();
}
class _GroupRoomState extends State<GroupRoom>{
  late int tab;String issueFilter='All';
  final message=TextEditingController(),scroll=ScrollController();
  @override void initState(){super.initState();tab=widget.initialTab;}
  @override void dispose(){message.dispose();scroll.dispose();super.dispose();}
  void send(){
    if(message.text.trim().isEmpty)return;
    widget.store.postMessage(widget.groupId,message.text);
    message.clear();
    WidgetsBinding.instance.addPostFrameCallback((_){
      if(scroll.hasClients)scroll.animateTo(scroll.position.maxScrollExtent,
        duration:const Duration(milliseconds:260),curve:Curves.easeOut);
    });
  }
  void navigate(Widget page)=>Navigator.push(context,MaterialPageRoute(builder:(_)=>page));
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:widget.store,
    builder:(context,_){
    final found=widget.store.groups.where((g)=>g.id==widget.groupId);
    if(found.isEmpty)return const Scaffold(body:SafeArea(child:Center(child:Text('Group deleted'))));
    final g=found.first,s=widget.store;
    if(!s.canSee(g))return const Scaffold(body:SafeArea(child:Center(child:Text('You are not assigned to this group'))));
    final notices=s.reportsFor(g.id),issues=s.complaintsFor(g.id);
    return Scaffold(body:SafeArea(child:Column(children:[
      Container(color:cyNavy,child:Column(children:[
        Padding(padding:const EdgeInsets.fromLTRB(10,13,13,14),child:Row(children:[
          IconButton(onPressed:()=>Navigator.pop(context),
            icon:const Icon(Icons.arrow_back_ios_new_rounded,color:Colors.white,size:19)),
          GroupArtwork(group:g,size:45),const SizedBox(width:10),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(g.name,maxLines:1,overflow:TextOverflow.ellipsis,
              style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:15)),
            const SizedBox(height:4),
            Text(g.members.length.toString()+' MEMBERS · '+s.roleFor(g).toUpperCase(),
              style:const TextStyle(color:Color(0xFFB1C8D9),fontSize:10,
                fontWeight:FontWeight.w800,letterSpacing:.4))
          ])),
          if(s.isAdmin)PopupMenuButton<String>(
            icon:const Icon(Icons.more_vert_rounded,color:Colors.white),
            color:Colors.white,onSelected:(v)async{
              if(v=='assign')navigate(AssignmentEditor(store:s,groupId:g.id));
              if(v=='edit')navigate(GroupEditor(store:s,groupId:g.id));
              if(v=='delete'){
                final yes=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
                  title:const Text('Delete this group?'),
                  content:const Text('Its chat, complaints and assignments will be removed. Historical attendance and Work Permit records are retained for Admin.'),
                  actions:[
                    TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('CANCEL')),
                    FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('DELETE')),
                  ]));
                if(yes==true&&context.mounted){
                  Navigator.pop(context);
                  s.deleteGroup(g.id);
                }
              }
            },itemBuilder:(_)=>[
              const PopupMenuItem(value:'assign',child:Text('Manage assignments')),
              const PopupMenuItem(value:'edit',child:Text('Edit group')),
              const PopupMenuItem(value:'delete',child:Text('Delete group')),
            ])
          else const Icon(Icons.lock_outline_rounded,color:Colors.white54,size:19),
        ])),
        Padding(padding:const EdgeInsets.fromLTRB(19,0,19,15),child:Row(children:[
          StatusPill('LIVE WORKSPACE',tint:const Color(0xFFBFF1D7),
            background:const Color(0xFF164D40),icon:Icons.circle),
          const SizedBox(width:6),
          if(notices.isNotEmpty)StatusPill(notices.length.toString()+' NOTICES',
            tint:Colors.white,background:const Color(0xFF20405B)),
          const Spacer(),
          if(s.canPublish(g))
            InkWell(onTap:()=>navigate(AttendanceEditor(store:s,groupId:g.id)),
              child:const Icon(Icons.add_circle_rounded,color:cyOrange,size:24)),
          if(s.canComplain(g))
            InkWell(onTap:()=>navigate(ComplaintEditor(store:s,groupId:g.id)),
              child:const Icon(Icons.report_problem_rounded,color:cyOrange,size:24)),
        ])),
      ])),
      Container(color:Colors.white,padding:const EdgeInsets.fromLTRB(12,8,12,8),
        child:Row(children:[
          _tabButton(0,'Chat',Icons.chat_bubble_outline_rounded),
          _tabButton(1,'Notices',Icons.campaign_outlined,badge:notices.length),
          _tabButton(2,'Issues',Icons.report_gmailerrorred_outlined,badge:issues.length),
          _tabButton(3,'People',Icons.people_outline_rounded),
        ])),
      Expanded(child:switch(tab){
        1=>_notices(notices,g),
        2=>_issues(issues,g),
        3=>_people(g),
        _=>_chat(g),
      }),
      if(tab==0)_composer(),
    ])));
  });
  Widget _tabButton(int index,String label,IconData icon,{int badge=0}){
    final active=tab==index;
    return Expanded(child:InkWell(onTap:()=>setState(()=>tab=index),
      borderRadius:BorderRadius.circular(11),
      child:Container(padding:const EdgeInsets.symmetric(vertical:10),
        decoration:BoxDecoration(color:active?cyOrangeSoft:Colors.transparent,
          borderRadius:BorderRadius.circular(11)),
        child:Column(children:[
          Stack(clipBehavior:Clip.none,children:[
            Icon(icon,size:19,color:active?cyOrange:cyMuted),
            if(badge>0)Positioned(top:-6,right:-12,child:Container(
              padding:const EdgeInsets.symmetric(horizontal:4,vertical:1),
              decoration:BoxDecoration(color:cyOrange,borderRadius:BorderRadius.circular(9)),
              child:Text(badge.toString(),style:const TextStyle(
                fontSize:8,fontWeight:FontWeight.w900,color:Colors.white))))
          ]),
          const SizedBox(height:4),
          Text(label,style:TextStyle(fontSize:10,
            fontWeight:FontWeight.w900,color:active?cyOrange:cyMuted)),
        ]))));
  }
  Widget _chat(WorkGroup g){
    final s=widget.store,list=s.groupEvents(g.id),notices=s.reportsFor(g.id),
      issues=s.complaintsFor(g.id);
    return ListView(controller:scroll,padding:const EdgeInsets.fromLTRB(15,12,15,16),children:[
      if(notices.isNotEmpty||issues.isNotEmpty)CyCard(color:const Color(0xFFFFFAF6),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Row(children:[
            Icon(Icons.push_pin_rounded,size:15,color:cyOrange),SizedBox(width:7),
            Text('IMPORTANT GROUP UPDATES',style:TextStyle(color:cyOrange,
              fontSize:10,fontWeight:FontWeight.w900,letterSpacing:1)),
          ]),
          const SizedBox(height:10),
          if(notices.isNotEmpty)InkWell(onTap:()=>setState(()=>tab=1),
            child:Row(children:[
              const Icon(Icons.fact_check_rounded,size:18,color:cyOrange),
              const SizedBox(width:8),
              Expanded(child:Text('Attendance notice · '+notices.first.date,
                style:const TextStyle(fontSize:11,fontWeight:FontWeight.w900,color:cyNavy))),
              const Icon(Icons.chevron_right_rounded,color:cyOrange,size:17),
            ])),
          if(notices.isNotEmpty&&issues.isNotEmpty)const Divider(height:18),
          if(issues.isNotEmpty)InkWell(onTap:()=>setState(()=>tab=2),
            child:Row(children:[
              const Icon(Icons.report_problem_rounded,size:18,color:cyPurple),
              const SizedBox(width:8),
              Expanded(child:Text('Engineering issues · '+issues.length.toString(),
                style:const TextStyle(fontSize:11,fontWeight:FontWeight.w900,color:cyNavy))),
              const Icon(Icons.chevron_right_rounded,color:cyPurple,size:17),
            ]))
        ])),
      const Padding(padding:EdgeInsets.symmetric(vertical:15),
        child:Center(child:Text('GROUP CONVERSATION',style:TextStyle(color:cyMuted,
          fontSize:9,letterSpacing:1.4,fontWeight:FontWeight.w900)))),
      if(list.isEmpty)const EmptyPanel(title:'Start the conversation',
        message:'Everyone assigned to this group can send messages.'),
      for(final event in list)Padding(padding:const EdgeInsets.only(bottom:13),
        child:switch(event.kind){
          'attendance'=>_attendanceEvent(event),
          'complaint'=>_complaintEvent(event),
          _=>_chatEvent(event),
        }),
    ]);
  }
  Widget _chatEvent(GroupEvent e){
    final s=widget.store,own=e.authorId==s.currentUserId;
    return Row(crossAxisAlignment:CrossAxisAlignment.end,
      mainAxisAlignment:own?MainAxisAlignment.end:MainAxisAlignment.start,children:[
      if(!own)...[PersonAvatar(s.person(e.authorId),size:31),const SizedBox(width:7)],
      Flexible(child:Column(crossAxisAlignment:own?CrossAxisAlignment.end:CrossAxisAlignment.start,children:[
        Padding(padding:const EdgeInsets.only(bottom:4,left:5,right:5),
          child:Text(own?'You':s.person(e.authorId).name,
            style:const TextStyle(color:cyMuted,fontSize:10,fontWeight:FontWeight.w800))),
        Container(padding:const EdgeInsets.symmetric(horizontal:13,vertical:11),
          decoration:BoxDecoration(color:own?cyNavy:Colors.white,
            border:Border.all(color:own?cyNavy:cyLine),
            borderRadius:BorderRadius.only(
              topLeft:const Radius.circular(15),topRight:const Radius.circular(15),
              bottomLeft:Radius.circular(own?15:4),bottomRight:Radius.circular(own?4:15))),
          child:Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
            Text(e.text,style:TextStyle(color:own?Colors.white:cyNavy,
              fontSize:12,height:1.55)),
            const SizedBox(height:5),
            Text(_time(e.timestamp),style:TextStyle(fontSize:9,
              color:own?Colors.white60:cyMuted))
          ]))
      ])),
    ]);
  }
  Widget _attendanceEvent(GroupEvent e){
    final match=widget.store.attendance.where((n)=>n.id==e.referenceId);
    if(match.isEmpty)return const SizedBox.shrink();
    return _attendanceCard(match.first,inChat:true);
  }
  Widget _complaintEvent(GroupEvent e){
    final match=widget.store.complaints.where((n)=>n.id==e.referenceId);
    if(match.isEmpty)return const SizedBox.shrink();
    return _complaintCard(match.first,inChat:true);
  }
  Widget _composer()=>Container(color:Colors.white,padding:const EdgeInsets.fromLTRB(13,9,13,13),
    child:Row(children:[
      Expanded(child:TextField(key:const Key('group_chat_input'),controller:message,
        textCapitalization:TextCapitalization.sentences,
        minLines:1,maxLines:4,textInputAction:TextInputAction.send,onSubmitted:(_)=>send(),
        decoration:InputDecoration(
          hintText:'Message your team...',
          prefixIcon:const Icon(Icons.chat_bubble_outline_rounded,size:19,color:cyMuted),
          fillColor:cyCanvas,filled:true,contentPadding:const EdgeInsets.symmetric(
            horizontal:13,vertical:13),
          border:OutlineInputBorder(borderRadius:BorderRadius.circular(15),
            borderSide:BorderSide.none),
          enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(15),
            borderSide:BorderSide.none)))),
      const SizedBox(width:8),
      IconButton.filled(key:const Key('send_chat'),onPressed:send,
        style:IconButton.styleFrom(backgroundColor:cyOrange,
          minimumSize:const Size(49,49)),
        icon:const Icon(Icons.send_rounded,color:Colors.white,size:19)),
    ]));
  Widget _notices(List<AttendanceReport> notices,WorkGroup g)=>ListView(
    padding:const EdgeInsets.fromLTRB(17,14,17,25),children:[
      const Text('OFFICIAL REPORTS',style:TextStyle(color:cyOrange,
        fontSize:10,letterSpacing:1.5,fontWeight:FontWeight.w900)),
      const SizedBox(height:8),
      const Text('Attendance notices.',style:TextStyle(
        color:cyNavy,fontSize:23,fontWeight:FontWeight.w900)),
      const SizedBox(height:6),
      const Text('Published by group supervisors and administrators.',
        style:TextStyle(color:cyMuted,fontSize:11,height:1.6)),
      if(widget.store.canPublish(g))Padding(padding:const EdgeInsets.only(top:15),
        child:SizedBox(width:double.infinity,child:FilledButton.icon(
          onPressed:()=>navigate(AttendanceEditor(store:widget.store,groupId:g.id)),
          icon:const Icon(Icons.add_rounded),label:const Text('PUBLISH ATTENDANCE NOTICE')))),
      const SizedBox(height:14),
      if(notices.isEmpty)const EmptyPanel(title:'No attendance reports',
        message:'An admin or supervisor can publish the first official notice.',
        icon:Icons.fact_check_outlined),
      for(final report in notices)Padding(padding:const EdgeInsets.only(bottom:11),
        child:_attendanceCard(report)),
    ]);
  Widget _attendanceCard(AttendanceReport n,{bool inChat=false}){
    final s=widget.store;
    return CyCard(color:const Color(0xFFFFF7F0),child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          Container(padding:const EdgeInsets.all(9),decoration:BoxDecoration(
            color:cyOrange,borderRadius:BorderRadius.circular(11)),
            child:const Icon(Icons.campaign_rounded,color:Colors.white,size:20)),
          const SizedBox(width:10),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('OFFICIAL ATTENDANCE NOTICE',style:TextStyle(color:cyOrange,
              fontSize:10,letterSpacing:.6,fontWeight:FontWeight.w900)),
            const SizedBox(height:4),
            Text(n.date,style:const TextStyle(color:cyNavy,
              fontWeight:FontWeight.w900,fontSize:15)),
          ])),
          const Icon(Icons.push_pin_rounded,color:cyOrange,size:16),
        ]),
        const SizedBox(height:12),
        Row(children:[
          Expanded(child:_countBox(n.presentCount,'PRESENT',
            const Color(0xFF138457),const Color(0xFFE7F8EF))),
          const SizedBox(width:9),
          Expanded(child:_countBox(n.absentCount,'ABSENT',
            const Color(0xFFBE4242),const Color(0xFFFFECEB))),
        ]),
        const SizedBox(height:12),
        Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:10),
          decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(11)),
          child:Row(children:[
            const Icon(Icons.schedule_rounded,color:cyOrange,size:17),
            const SizedBox(width:7),
            Expanded(child:Text(hourLabel(n.totalHours)+'h worked · '+
              hourLabel(n.totalOvertime)+'h overtime',style:const TextStyle(
              color:cyNavy,fontSize:11,fontWeight:FontWeight.w900))),
          ])),
        const SizedBox(height:12),
        if(n.permit!=null)Padding(padding:const EdgeInsets.only(bottom:9),
          child:StatusPill('WORK PERMIT '+n.permit!.code,icon:Icons.verified_outlined)),
        Text('Published by '+s.person(n.authorId).name,
          style:const TextStyle(color:cyMuted,fontSize:10)),
        const SizedBox(height:10),
        InkWell(onTap:()=>_showReport(n),child:const Row(
          mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
          Text('VIEW MEMBER-WISE ATTENDANCE',style:TextStyle(
            color:cyOrange,fontWeight:FontWeight.w900,fontSize:10)),
          Icon(Icons.arrow_forward_rounded,color:cyOrange,size:17),
        ])),
      ]));
  }
  Widget _countBox(int amount,String title,Color tint,Color bg)=>Container(
    padding:const EdgeInsets.all(11),decoration:BoxDecoration(
      color:bg,borderRadius:BorderRadius.circular(12)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(amount.toString(),style:TextStyle(fontSize:23,color:tint,fontWeight:FontWeight.w900)),
      const SizedBox(height:3),
      Text(title,style:TextStyle(fontSize:10,color:tint,fontWeight:FontWeight.w900))
    ]));
  void _showReport(AttendanceReport n){
    showModalBottomSheet(context:context,isScrollControlled:true,showDragHandle:true,
      backgroundColor:cyCanvas,builder:(ctx)=>SafeArea(child:FractionallySizedBox(
        heightFactor:.78,child:ListView(padding:const EdgeInsets.fromLTRB(19,5,19,24),children:[
          const Text('OFFICIAL ATTENDANCE',style:TextStyle(color:cyOrange,fontSize:10,
            fontWeight:FontWeight.w900,letterSpacing:1.5)),
          const SizedBox(height:7),
          Text(n.date,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:24,color:cyNavy)),
          if(n.permit!=null)Padding(padding:const EdgeInsets.only(top:8),
            child:StatusPill('WORK PERMIT '+n.permit!.code,icon:Icons.verified_outlined)),
          const SizedBox(height:11),
          InfoBanner(hourLabel(n.totalHours)+' hours worked · '+hourLabel(n.totalOvertime)+
            ' hours overtime across '+n.presentCount.toString()+' present members',
            icon:Icons.schedule_rounded,color:cyOrange),
          const SizedBox(height:15),
          for(final entry in n.present.entries)Padding(padding:const EdgeInsets.only(bottom:9),
            child:CyCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Row(children:[
                PersonAvatar(widget.store.person(entry.key)),const SizedBox(width:11),
                Expanded(child:Text(widget.store.person(entry.key).name,
                  style:const TextStyle(color:cyNavy,fontSize:12,fontWeight:FontWeight.w900))),
                StatusPill(entry.value?'PRESENT':'ABSENT',
                  tint:entry.value?const Color(0xFF138457):const Color(0xFFB63D3D),
                  background:entry.value?const Color(0xFFE7F8EF):const Color(0xFFFFECEB)),
              ]),
              const Divider(height:20),
              Row(children:[
                const Icon(Icons.access_time_rounded,color:cyOrange,size:16),
                const SizedBox(width:7),
                Text(hourLabel(n.hoursFor(entry.key))+' hours worked',
                  style:const TextStyle(color:cyNavy,fontWeight:FontWeight.w900,fontSize:11)),
                const Spacer(),
                if(entry.value&&n.hoursFor(entry.key)>=8)
                  const StatusPill('1 DAY',background:Color(0xFFE7F8EF),
                    tint:Color(0xFF138457)),
                if(!entry.value)const StatusPill('0 HOURS'),
                if(entry.value&&n.hoursFor(entry.key)<8)
                  const StatusPill('PARTIAL DAY'),
              ]),
              if(n.overtimeFor(entry.key)>0)Padding(
                padding:const EdgeInsets.only(top:10),
                child:StatusPill('+'+hourLabel(n.overtimeFor(entry.key))+'h OVERTIME',
                  icon:Icons.bolt_rounded)),
            ]))),
        ]))));
  }
  Widget _issues(List<GroupComplaint> issues,WorkGroup g){
    final visible=issues.where((i)=>issueFilter=='All'||i.status==issueFilter).toList();
    return ListView(padding:const EdgeInsets.fromLTRB(17,14,17,25),children:[
      const Text('ENGINEERING CHANNEL',style:TextStyle(color:cyPurple,
        fontWeight:FontWeight.w900,fontSize:10,letterSpacing:1.5)),
      const SizedBox(height:7),
      const Text('Issues & complaints.',style:TextStyle(color:cyNavy,
        fontWeight:FontWeight.w900,fontSize:23)),
      const SizedBox(height:7),
      const Text('Problems raised by engineers stay visible until resolved.',
        style:TextStyle(color:cyMuted,fontSize:11,height:1.6)),
      if(widget.store.canComplain(g))Padding(padding:const EdgeInsets.only(top:15),
        child:SizedBox(width:double.infinity,child:FilledButton.icon(
          onPressed:()=>navigate(ComplaintEditor(store:widget.store,groupId:g.id)),
          icon:const Icon(Icons.add_rounded),label:const Text('RAISE AN ENGINEERING COMPLAINT')))),
      const SizedBox(height:12),
      Row(children:[
        Expanded(child:_smallMetric(issues.where((i)=>i.status=='Open').length,'OPEN',cyPurple)),
        const SizedBox(width:7),
        Expanded(child:_smallMetric(issues.where((i)=>i.status=='Under Review').length,'REVIEW',
          const Color(0xFFBB7A10))),
        const SizedBox(width:7),
        Expanded(child:_smallMetric(issues.where((i)=>i.status=='Resolved').length,'DONE',
          const Color(0xFF158458))),
      ]),
      const SizedBox(height:10),
      SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
        for(final f in ['All','Open','Under Review','Resolved'])Padding(
          padding:const EdgeInsets.only(right:7),
          child:ChoiceChip(label:Text(f,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w800)),
            selected:issueFilter==f,selectedColor:cyNavy,
            labelStyle:TextStyle(color:issueFilter==f?Colors.white:cyMuted),
            onSelected:(_)=>setState(()=>issueFilter=f))),
      ])),
      const SizedBox(height:13),
      if(visible.isEmpty)const EmptyPanel(title:'No issues here',
        message:'Engineer complaints will be highlighted in this board.',
        icon:Icons.verified_outlined),
      for(final c in visible)Padding(padding:const EdgeInsets.only(bottom:10),
        child:_complaintCard(c)),
    ]);
  }
  Widget _smallMetric(int n,String label,Color tint)=>CyCard(
    padding:const EdgeInsets.symmetric(horizontal:10,vertical:13),
    child:Column(children:[
      Text(n.toString(),style:TextStyle(color:tint,fontSize:21,fontWeight:FontWeight.w900)),
      Text(label,style:TextStyle(color:tint,fontSize:9,fontWeight:FontWeight.w900))
    ]));
  Widget _complaintCard(GroupComplaint c,{bool inChat=false}){
    final status=c.status;
    final pillColor=status=='Resolved'?const Color(0xFF178D62):
      status=='Under Review'?const Color(0xFFA36A11):cyPurple;
    return CyCard(color:const Color(0xFFF7F5FF),child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[
        Container(padding:const EdgeInsets.all(9),decoration:BoxDecoration(color:cyPurple,
          borderRadius:BorderRadius.circular(11)),
          child:const Icon(Icons.report_problem_rounded,color:Colors.white,size:20)),
        const SizedBox(width:10),
        const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('ENGINEER COMPLAINT',style:TextStyle(color:cyPurple,
            fontWeight:FontWeight.w900,fontSize:10,letterSpacing:.7)),
          SizedBox(height:3),
          Text('FIELD ISSUE REPORT',style:TextStyle(color:cyMuted,
            fontSize:9,fontWeight:FontWeight.w800)),
        ])),
        StatusPill(status.toUpperCase(),tint:pillColor,
          background:pillColor.withValues(alpha:.11)),
      ]),
      const SizedBox(height:11),
      Text(c.text,maxLines:inChat?4:null,overflow:inChat?TextOverflow.ellipsis:null,
        style:const TextStyle(color:cyNavy,fontSize:12,height:1.55,fontWeight:FontWeight.w600)),
      const SizedBox(height:10),
      Row(children:[
        PersonAvatar(widget.store.person(c.authorId),size:25),
        const SizedBox(width:7),
        Expanded(child:Text(widget.store.person(c.authorId).name,
          style:const TextStyle(color:cyMuted,fontSize:10))),
        InkWell(onTap:()=>_showComplaint(c),child:const Row(children:[
          Text('DETAILS',style:TextStyle(color:cyPurple,
            fontSize:10,fontWeight:FontWeight.w900)),
          SizedBox(width:4),
          Icon(Icons.arrow_forward_rounded,color:cyPurple,size:16),
        ])),
      ])
    ]));
  }
  void _showComplaint(GroupComplaint c){
    showModalBottomSheet(context:context,isScrollControlled:true,showDragHandle:true,
      backgroundColor:cyCanvas,builder:(ctx)=>AnimatedBuilder(animation:widget.store,builder:(ctx,_){
        final match=widget.store.complaints.where((x)=>x.id==c.id);
        if(match.isEmpty)return const SizedBox.shrink();
        final item=match.first,canReview=widget.store.canReview(widget.store.group(widget.groupId));
        return SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(20,8,20,30),
          child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('ENGINEERING INCIDENT',style:TextStyle(
              color:cyPurple,fontWeight:FontWeight.w900,fontSize:10,letterSpacing:1.5)),
            const SizedBox(height:9),
            const Text('Complaint details',style:TextStyle(
              color:cyNavy,fontSize:22,fontWeight:FontWeight.w900)),
            const SizedBox(height:13),
            CyCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              StatusPill(item.status.toUpperCase(),tint:cyPurple,
                background:const Color(0xFFF0EDFF)),
              const SizedBox(height:14),
              Text(item.text,style:const TextStyle(fontSize:13,color:cyNavy,height:1.6)),
              const SizedBox(height:12),
              Text('By '+widget.store.person(item.authorId).name+' · '+item.createdAt.substring(0,10),
                style:const TextStyle(fontSize:11,color:cyMuted)),
            ])),
            if(canReview)...[
              const SizedBox(height:17),
              const Text('UPDATE ISSUE STATUS',style:TextStyle(
                color:cyNavy,fontSize:11,fontWeight:FontWeight.w900)),
              const SizedBox(height:10),
              Wrap(spacing:8,runSpacing:8,children:[
                for(final status in ['Open','Under Review','Resolved'])
                  ChoiceChip(label:Text(status),selected:item.status==status,
                    onSelected:(_)=>widget.store.setComplaintStatus(widget.groupId,item.id,status)),
              ]),
            ],
            const SizedBox(height:20),
            SizedBox(width:double.infinity,child:OutlinedButton(
              onPressed:()=>Navigator.pop(ctx),child:const Text('CLOSE DETAILS')))
          ])));
      }));
  }
  Widget _people(WorkGroup g){
    final s=widget.store;
    return ListView(padding:const EdgeInsets.fromLTRB(17,14,17,25),children:[
      const Text('ASSIGNED TO THIS GROUP',style:TextStyle(color:cyOrange,
        fontSize:10,letterSpacing:1.4,fontWeight:FontWeight.w900)),
      const SizedBox(height:8),
      const Text('Group people.',style:TextStyle(color:cyNavy,
        fontSize:23,fontWeight:FontWeight.w900)),
      const SizedBox(height:7),
      Text(g.members.length.toString()+' assigned people can access this conversation.',
        style:const TextStyle(color:cyMuted,fontSize:11)),
      if(s.isAdmin)Padding(padding:const EdgeInsets.only(top:15),
        child:SizedBox(width:double.infinity,child:FilledButton.icon(
          onPressed:()=>navigate(AssignmentEditor(store:s,groupId:g.id)),
          icon:const Icon(Icons.person_add_alt_1_rounded),
          label:const Text('MANAGE ASSIGNED MEMBERS')))),
      const SizedBox(height:17),
      if(g.members.isEmpty)const EmptyPanel(title:'No members assigned',
        message:'Add people from one or more teams.'),
      for(final a in g.members)Padding(padding:const EdgeInsets.only(bottom:8),
        child:CyCard(child:Row(children:[
          PersonAvatar(s.person(a.personId)),const SizedBox(width:11),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(s.person(a.personId).name,style:const TextStyle(
              color:cyNavy,fontWeight:FontWeight.w900,fontSize:12)),
            const SizedBox(height:4),
            Text('Assigned '+a.assignedOn,style:const TextStyle(
              color:cyMuted,fontSize:10))
          ])),
          StatusPill(a.role.toUpperCase()),
        ]))),
      const SizedBox(height:11),
      const InfoBanner('An admin manages group assignments. Supervisors publish attendance; '
        'engineers submit complaints; all assigned users can chat.'),
    ]);
  }
  String _time(String iso)=>iso.length>=16?iso.substring(11,16):iso;
}

class AttendanceEditor extends StatefulWidget{
  const AttendanceEditor({super.key,required this.store,required this.groupId});
  final AppStore store;final String groupId;
  @override State<AttendanceEditor> createState()=>_AttendanceEditorState();
}
class _AttendanceEditorState extends State<AttendanceEditor>{
  DateTime date=DateTime.now();
  late final Map<String,bool> status;
  late final Map<String,double> hours;
  PermitScan? permitScan;
  bool publishing=false;
  @override void initState(){
    super.initState();
    status={for(final m in widget.store.group(widget.groupId).members)m.personId:true};
    hours={for(final id in status.keys)id:8.0};
  }
  Future<void> publish()async{
    final scan=permitScan;
    if(scan==null||publishing||status.isEmpty)return;
    final selectedDate=date;
    final selectedStatus=Map<String,bool>.of(status);
    final selectedHours=Map<String,double>.of(hours);
    setState(()=>publishing=true);
    PermitEvidence? evidence;
    bool saved=false;
    try {
      evidence=await scan.persist();
      await widget.store.postAttendance(widget.groupId,selectedDate,selectedStatus,
        hours:selectedHours,permit:evidence);
      saved=true;
      if(mounted)Navigator.pop(context);
    }catch(e){
      if(!saved&&evidence!=null){
        try{await File(evidence.imagePath).delete();}catch(_){}
      }
      if(mounted)toast(context,'Unable to publish: '+e.toString());
    }finally{
      if(mounted)setState(()=>publishing=false);
    }
  }
  String shiftDisplay(String id){
    if(!(status[id]??false))return 'Absent · 0 hours';
    final h=hours[id]??8.0;
    if(h>=8){return '1 day'+(h>8?' + '+hourLabel(h-8)+'h OT':'');}
    return hourLabel(h)+'h · partial day';
  }
  @override Widget build(BuildContext context){
    final g=widget.store.group(widget.groupId);
    if(!widget.store.canPublish(g))return const Scaffold(body:Center(child:Text('Only admin and supervisor can publish notices')));
    final present=status.values.where((v)=>v).length,absent=status.length-present;
    return Scaffold(body:SafeArea(child:Column(children:[
      const AppPageHeader(title:'Publish attendance',subtitle:'OFFICIAL GROUP NOTICE'),
      Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(19,4,19,24),children:[
        CyCard(color:cyNavy,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const StatusPill('OFFICIAL GROUP NOTICE'),
          const SizedBox(height:13),
          const Text('Who attended today?',style:TextStyle(
            fontWeight:FontWeight.w900,fontSize:22,color:Colors.white)),
          const SizedBox(height:5),
          Text(g.name,style:const TextStyle(color:Color(0xFFBDCEDB),fontSize:12)),
          const SizedBox(height:15),
          OutlinedButton.icon(onPressed:()async{
            final d=await showDatePicker(context:context,initialDate:date,
              firstDate:DateTime(2020),lastDate:DateTime(2100));
            if(d!=null)setState(()=>date=d);
          },style:OutlinedButton.styleFrom(foregroundColor:Colors.white,
            side:const BorderSide(color:Colors.white38)),
            icon:const Icon(Icons.calendar_month_rounded),
            label:Text(dayKey(date)+'  ·  CHANGE DATE')),
        ])),
        const SizedBox(height:13),
        WorkPermitField(key:const Key('work_permit_field'),locked:publishing,
          onChanged:(scan)=>setState(()=>permitScan=scan)),
        const SizedBox(height:13),
        Row(children:[
          Expanded(child:CyCard(child:Column(children:[
            Text(present.toString(),style:const TextStyle(color:Color(0xFF138857),
              fontWeight:FontWeight.w900,fontSize:23)),
            const Text('PRESENT',style:TextStyle(color:Color(0xFF138857),
              fontSize:10,fontWeight:FontWeight.w900))
          ]))),
          const SizedBox(width:9),
          Expanded(child:CyCard(child:Column(children:[
            Text(absent.toString(),style:const TextStyle(color:Color(0xFFC34242),
              fontWeight:FontWeight.w900,fontSize:23)),
            const Text('ABSENT',style:TextStyle(color:Color(0xFFC34242),
              fontSize:10,fontWeight:FontWeight.w900))
          ]))),
        ]),
        const SectionTitle('Member attendance'),
        Wrap(spacing:8,runSpacing:6,children:[
          OutlinedButton.icon(onPressed:publishing?null:()=>setState(()=>status.updateAll((_,__)=>true)),
            icon:const Icon(Icons.check_circle_outline_rounded,color:Color(0xFF138457),size:17),
            label:const Text('All present')),
          OutlinedButton.icon(onPressed:publishing?null:()=>setState(()=>status.updateAll((_,__)=>false)),
            icon:const Icon(Icons.cancel_outlined,color:Color(0xFFB63D3D),size:17),
            label:const Text('All absent')),
        ]),
        const SizedBox(height:10),
        if(status.isEmpty)const EmptyPanel(title:'No group members',
          message:'Ask the admin to assign group members first.'),
        for(final id in status.keys)Padding(padding:const EdgeInsets.only(bottom:9),
          child:CyCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[
              PersonAvatar(widget.store.person(id)),const SizedBox(width:10),
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(widget.store.person(id).name,style:const TextStyle(
                  color:cyNavy,fontWeight:FontWeight.w900,fontSize:12)),
                Text(g.roleOf(id).toUpperCase(),style:const TextStyle(
                  color:cyMuted,fontSize:9,fontWeight:FontWeight.w900))
              ])),
              SegmentedButton<bool>(showSelectedIcon:false,
                style:ButtonStyle(visualDensity:VisualDensity.compact,
                  padding:const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal:6))),
                segments:const [
                  ButtonSegment(value:true,label:Text('P',style:TextStyle(fontSize:11))),
                  ButtonSegment(value:false,label:Text('A',style:TextStyle(fontSize:11)))
                ],selected:{status[id]!},
                onSelectionChanged:(v)=>setState(()=>status[id]=v.first)),
            ]),
            if(status[id]??false)...[
              const Divider(height:21),
              Row(children:[
                const Icon(Icons.schedule_rounded,color:cyOrange,size:17),
                const SizedBox(width:7),
                const Expanded(child:Text('HOURS WORKED',style:TextStyle(
                  color:cyMuted,fontSize:10,fontWeight:FontWeight.w900))),
                IconButton(key:Key('hours_minus_'+id),
                  onPressed:()=>setState(()=>hours[id]=((hours[id]??8)-.5).clamp(0.0,24.0).toDouble()),
                  visualDensity:VisualDensity.compact,
                  icon:const Icon(Icons.remove_circle_outline_rounded,color:cyOrange)),
                Text(hourLabel(hours[id]??8)+' h',key:Key('hours_value_'+id),
                  style:const TextStyle(color:cyNavy,fontSize:14,fontWeight:FontWeight.w900)),
                IconButton(key:Key('hours_plus_'+id),
                  onPressed:()=>setState(()=>hours[id]=((hours[id]??8)+.5).clamp(0.0,24.0).toDouble()),
                  visualDensity:VisualDensity.compact,
                  icon:const Icon(Icons.add_circle_rounded,color:cyOrange)),
              ]),
              Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:7),
                decoration:BoxDecoration(color:cyOrangeSoft,borderRadius:BorderRadius.circular(9)),
                child:Row(children:[
                  const Icon(Icons.verified_rounded,color:cyOrange,size:14),
                  const SizedBox(width:6),
                  Text(shiftDisplay(id),style:const TextStyle(
                    color:cyOrange,fontSize:10,fontWeight:FontWeight.w900)),
                ])),
            ]else const Padding(padding:EdgeInsets.only(top:8),
              child:StatusPill('ABSENT · 0 HOURS',
                tint:Color(0xFFB63D3D),background:Color(0xFFFFECEB))),
          ]))),
        const SizedBox(height:12),
        const InfoBanner('8 hours = 1 regular day. Hours over 8 are recorded as overtime. '
          'Publishing saves current worker wage rates and OT policy for historical payroll.',color:cyOrange),
      ])),
      Container(color:Colors.white,padding:const EdgeInsets.fromLTRB(19,12,19,16),
        child:SizedBox(width:double.infinity,child:FilledButton.icon(
          key:const Key('publish_attendance'),
          onPressed:status.isEmpty||permitScan==null||publishing?null:publish,
          icon:const Icon(Icons.campaign_rounded),
          label:Text(publishing?'SAVING ATTENDANCE…':permitScan==null?'VERIFY WORK PERMIT FIRST':'PUBLISH OFFICIAL NOTICE')))),
    ])));
  }
}

class ComplaintEditor extends StatefulWidget{
  const ComplaintEditor({super.key,required this.store,required this.groupId});
  final AppStore store;final String groupId;
  @override State<ComplaintEditor> createState()=>_ComplaintEditorState();
}
class _ComplaintEditorState extends State<ComplaintEditor>{
  final description=TextEditingController();
  @override void dispose(){description.dispose();super.dispose();}
  @override Widget build(BuildContext context){
    final g=widget.store.group(widget.groupId);
    if(!widget.store.canComplain(g))return const Scaffold(body:Center(child:Text('Only assigned engineers can submit complaints')));
    return Scaffold(body:SafeArea(child:Column(children:[
      const AppPageHeader(title:'Raise a complaint',subtitle:'ENGINEERING ISSUE REPORT'),
      Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(19,5,19,25),children:[
        Container(padding:const EdgeInsets.all(19),decoration:BoxDecoration(
          color:cyNavy,borderRadius:BorderRadius.circular(20)),
          child:const Row(children:[
            CircleAvatar(radius:26,backgroundColor:Color(0xFF2A3E58),
              child:Icon(Icons.report_problem_rounded,color:cyOrange,size:27)),
            SizedBox(width:14),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('SPEAK UP. STAY SAFE.',style:TextStyle(color:cyOrange,
                letterSpacing:1.1,fontSize:10,fontWeight:FontWeight.w900)),
              SizedBox(height:7),
              Text('Report a site or engineering concern to your entire group.',
                style:TextStyle(color:Colors.white,fontSize:12,height:1.6))
            ]))
          ])),
        const FormLabel('Complaint description'),
        TextField(key:const Key('complaint_description'),controller:description,
          textCapitalization:TextCapitalization.sentences,minLines:7,maxLines:11,
          decoration:const InputDecoration(
            hintText:'Explain what happened, where, and what should be addressed...')),
        const SizedBox(height:15),
        const InfoBanner('Your complaint appears as a highlighted card in group chat and the '
          'Issues board. Admins and supervisors can mark it Under Review or Resolved.',
          icon:Icons.info_outline_rounded,color:cyPurple),
      ])),
      Container(color:Colors.white,padding:const EdgeInsets.fromLTRB(19,12,19,16),
        child:SizedBox(width:double.infinity,child:FilledButton.icon(
          key:const Key('submit_complaint'),onPressed:(){
            if(description.text.trim().isEmpty){toast(context,'Enter your complaint before submitting');return;}
            widget.store.sendComplaint(widget.groupId,description.text);
            Navigator.pop(context);
          },
          icon:const Icon(Icons.send_rounded),label:const Text('SUBMIT COMPLAINT')))),
    ])));
  }
}
