import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/cytech_theme.dart';

class WorkNoticeCenter extends StatefulWidget{
  const WorkNoticeCenter({super.key,required this.store});
  final AppStore store;
  @override State<WorkNoticeCenter> createState()=>_WorkNoticeCenterState();
}
class _WorkNoticeCenterState extends State<WorkNoticeCenter>{
  bool assignmentsOnly=false;
  @override Widget build(BuildContext context){
    final store=widget.store;
    final items=store.visibleWorkNotices.where((n)=>!assignmentsOnly||n.memberIds.contains(store.currentUserId)).toList();
    return ListView(padding:const EdgeInsets.fromLTRB(18,6,18,115),children:[
      Container(padding:const EdgeInsets.all(19),decoration:BoxDecoration(
        color:cyNavy,borderRadius:BorderRadius.circular(21)),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(
              color:cyOrange.withValues(alpha:.19),borderRadius:BorderRadius.circular(13)),
              child:const Icon(Icons.campaign_rounded,color:cyOrange,size:23)),
            const Spacer(),
            const StatusPill('WORK ASSIGNMENTS',background:Color(0xFF20445C),tint:Colors.white),
          ]),
          const SizedBox(height:16),
          const Text('Know where.\nKnow when.',style:TextStyle(color:Colors.white,
            fontSize:25,height:1.1,fontWeight:FontWeight.w900)),
          const SizedBox(height:8),
          const Text('Official company reporting details for your workforce.',
            style:TextStyle(color:Color(0xFFBED0DF),fontSize:12,height:1.6)),
        ])),
      const SizedBox(height:13),
      if(store.canPublishWorkNotice)SizedBox(width:double.infinity,
        child:FilledButton.icon(key:const Key('create_public_notice'),
          onPressed:()=>Navigator.push(context,MaterialPageRoute(
            builder:(_)=>WorkNoticeEditor(store:store))),
          icon:const Icon(Icons.add_rounded),
          label:const Text('PUBLISH PUBLIC WORK NOTICE'))),
      SectionTitle('Published notices',action:items.length.toString()+' NOTICES'),
      Row(children:[
        Expanded(child:ChoiceChip(label:const Text('Relevant notices'),
          selected:!assignmentsOnly,onSelected:(_)=>setState(()=>assignmentsOnly=false))),
        const SizedBox(width:8),
        Expanded(child:ChoiceChip(label:const Text('My assignments'),
          selected:assignmentsOnly,onSelected:(_)=>setState(()=>assignmentsOnly=true))),
      ]),
      const SizedBox(height:12),
      if(items.isEmpty)const EmptyPanel(title:'No work notices yet',
        message:'Upcoming company, location and reporting details will be shown here.',
        icon:Icons.campaign_outlined),
      for(final n in items)Padding(padding:const EdgeInsets.only(bottom:11),
        child:CyCard(onTap:()=>_details(context,n),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            Container(padding:const EdgeInsets.all(9),decoration:BoxDecoration(
              color:cyOrangeSoft,borderRadius:BorderRadius.circular(11)),
              child:const Icon(Icons.apartment_rounded,color:cyOrange,size:23)),
            const SizedBox(width:10),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              const Text('OFFICIAL WORK NOTICE',style:TextStyle(color:cyOrange,fontSize:9,
                fontWeight:FontWeight.w900,letterSpacing:1)),
              const SizedBox(height:4),
              Text(n.company,maxLines:1,overflow:TextOverflow.ellipsis,
                style:const TextStyle(fontSize:14,fontWeight:FontWeight.w900,color:cyNavy)),
            ])),
            StatusPill(n.date,icon:Icons.event_rounded),
          ]),
          const SizedBox(height:13),
          Row(children:[
            const Icon(Icons.location_on_outlined,color:cyMuted,size:15),
            const SizedBox(width:6),
            Expanded(child:Text(n.location,style:const TextStyle(
              fontSize:12,color:cyInk,fontWeight:FontWeight.w700))),
          ]),
          const SizedBox(height:8),
          Row(children:[
            const Icon(Icons.access_time_filled_rounded,color:cyOrange,size:15),
            const SizedBox(width:6),
            Text('Report at '+n.reportingTime,style:const TextStyle(
              fontSize:12,color:cyNavy,fontWeight:FontWeight.w900)),
            const Spacer(),
            Text(n.memberIds.length.toString()+' assigned',style:const TextStyle(
              color:cyMuted,fontSize:10,fontWeight:FontWeight.w800))
          ]),
          if(n.memberIds.contains(store.currentUserId))...[
            const Divider(height:23),
            const Row(children:[
              Icon(Icons.check_circle_rounded,color:Color(0xFF119764),size:16),
              SizedBox(width:6),Text('YOU ARE ASSIGNED',style:TextStyle(
                color:Color(0xFF119764),fontWeight:FontWeight.w900,fontSize:10))
            ])
          ]else if(store.canPublishWorkNotice)...[
            const SizedBox(height:9),
            AvatarStack(ids:n.memberIds,store:store),
          ],
        ]))),
      const InfoBanner('Offline preview: Public Notices are stored only on this phone. '
        'Other phones will not receive them until a backend is connected.'),
    ]);
  }
  void _details(BuildContext context,WorkNotice notice){
    final store=widget.store;
    showModalBottomSheet(context:context,isScrollControlled:true,showDragHandle:true,
      backgroundColor:cyCanvas,builder:(ctx)=>SafeArea(child:FractionallySizedBox(
        heightFactor:.72,child:ListView(padding:const EdgeInsets.fromLTRB(20,6,20,30),children:[
          const Text('CYTECH / WORK NOTICE',style:TextStyle(color:cyOrange,
            fontSize:10,letterSpacing:1.5,fontWeight:FontWeight.w900)),
          const SizedBox(height:7),
          Text(notice.company,style:const TextStyle(color:cyNavy,
            fontSize:23,fontWeight:FontWeight.w900)),
          const SizedBox(height:14),
          CyCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            _detail(Icons.event_rounded,'WORK DATE',notice.date),
            const Divider(height:25),
            _detail(Icons.access_time_rounded,'REPORTING TIME',notice.reportingTime),
            const Divider(height:25),
            _detail(Icons.location_on_rounded,'WORK LOCATION',notice.location),
            if(notice.instructions.isNotEmpty)...[
              const Divider(height:25),
              _detail(Icons.info_outline_rounded,'INSTRUCTIONS',notice.instructions),
            ],
          ])),
          SectionTitle('Assigned workers',action:notice.memberIds.length.toString()+' MEMBERS'),
          for(final id in notice.memberIds)Padding(padding:const EdgeInsets.only(bottom:7),
            child:CyCard(child:Row(children:[
              PersonAvatar(store.person(id)),const SizedBox(width:10),
              Expanded(child:Text(store.person(id).name,style:const TextStyle(
                fontSize:12,fontWeight:FontWeight.w900,color:cyNavy))),
              if(id==store.currentUserId)const StatusPill('YOU')
            ]))),
          const SizedBox(height:13),
          Text('Published by '+store.person(notice.authorId).name,
            style:const TextStyle(color:cyMuted,fontSize:11)),
        ]))));
  }
  Widget _detail(IconData icon,String label,String text)=>Row(
    crossAxisAlignment:CrossAxisAlignment.start,children:[
    Icon(icon,color:cyOrange,size:21),const SizedBox(width:11),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(label,style:const TextStyle(color:cyMuted,fontSize:9,
        fontWeight:FontWeight.w900,letterSpacing:1)),
      const SizedBox(height:5),
      Text(text,style:const TextStyle(color:cyNavy,
        fontSize:13,fontWeight:FontWeight.w800,height:1.5)),
    ]))
  ]);
}

class WorkNoticeEditor extends StatefulWidget{
  const WorkNoticeEditor({super.key,required this.store});
  final AppStore store;
  @override State<WorkNoticeEditor> createState()=>_WorkNoticeEditorState();
}
class _WorkNoticeEditorState extends State<WorkNoticeEditor>{
  final company=TextEditingController(),location=TextEditingController(),
    instructions=TextEditingController(),search=TextEditingController();
  final selected=<String>{};
  DateTime date=DateTime.now();
  TimeOfDay time=const TimeOfDay(hour:8,minute:0);
  String teamFilter='all';
  @override void dispose(){company.dispose();location.dispose();instructions.dispose();search.dispose();super.dispose();}
  Future<void> chooseDate()async{
    final next=await showDatePicker(context:context,initialDate:date,
      firstDate:DateTime(2020),lastDate:DateTime(2100));
    if(next!=null)setState(()=>date=next);
  }
  Future<void> chooseTime()async{
    final next=await showTimePicker(context:context,initialTime:time);
    if(next!=null)setState(()=>time=next);
  }
  String get formattedTime=>time.hour.toString().padLeft(2,'0')+':'+time.minute.toString().padLeft(2,'0');
  @override Widget build(BuildContext context){
    final store=widget.store;
    if(!store.canPublishWorkNotice)return const Scaffold(body:Center(child:Text('Supervisor or Admin access required')));
    final teamIds=teamFilter=='all'?store.allTeamMemberIds:store.team(teamFilter).memberIds;
    final people=teamIds.toSet().map(store.person).where((p)=>
      p.name.toLowerCase().contains(search.text.toLowerCase())||
      p.username.toLowerCase().contains(search.text.toLowerCase())).toList();
    return Scaffold(body:SafeArea(child:Column(children:[
      const AppPageHeader(title:'Publish work notice',subtitle:'SUPERVISOR / OFFICIAL NOTICE'),
      Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(19,5,19,25),children:[
        CyCard(color:cyNavy,child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('NEW COMPANY ASSIGNMENT',style:TextStyle(color:cyOrange,fontSize:10,
            letterSpacing:1.3,fontWeight:FontWeight.w900)),
          SizedBox(height:8),
          Text('Tell workers exactly\nwhere to report.',style:TextStyle(
            color:Colors.white,fontSize:22,height:1.2,fontWeight:FontWeight.w900)),
          SizedBox(height:9),
          Text('Selected workers will see this notice in their Public Notices screen.',
            style:TextStyle(color:Color(0xFFB5C9D7),fontSize:11,height:1.6)),
        ])),
        const FormLabel('Company name *'),
        TextField(key:const Key('work_company'),controller:company,
          decoration:const InputDecoration(hintText:'e.g. MasterWave Industries',
            prefixIcon:Icon(Icons.apartment_rounded))),
        const FormLabel('Work site / location *'),
        TextField(key:const Key('work_location'),controller:location,
          decoration:const InputDecoration(hintText:'Site address or project location',
            prefixIcon:Icon(Icons.place_outlined))),
        const FormLabel('Reporting date & time'),
        Row(children:[
          Expanded(child:CyCard(onTap:chooseDate,child:Row(children:[
            const Icon(Icons.calendar_month_rounded,color:cyOrange),
            const SizedBox(width:8),
            Expanded(child:Text(dayKey(date),style:const TextStyle(
              fontSize:11,fontWeight:FontWeight.w900,color:cyNavy)))
          ]))),
          const SizedBox(width:8),
          Expanded(child:CyCard(onTap:chooseTime,child:Row(children:[
            const Icon(Icons.access_time_rounded,color:cyOrange),
            const SizedBox(width:8),
            Expanded(child:Text(formattedTime,style:const TextStyle(
              fontSize:11,fontWeight:FontWeight.w900,color:cyNavy)))
          ])))
        ]),
        const FormLabel('Instructions (optional)'),
        TextField(controller:instructions,maxLines:3,minLines:2,
          decoration:const InputDecoration(hintText:'Uniform, safety gear, gate entrance, contact person...')),
        SectionTitle('Select team members',action:selected.length.toString()+' SELECTED'),
        DropdownButtonFormField<String>(
          initialValue:teamFilter,
          items:[const DropdownMenuItem(value:'all',child:Text('All teams')),
            ...store.teams.map((t)=>DropdownMenuItem(value:t.id,child:Text(t.name)))],
          onChanged:(v)=>setState(()=>teamFilter=v??'all')),
        const SizedBox(height:9),
        TextField(controller:search,onChanged:(_)=>setState((){}),
          decoration:const InputDecoration(prefixIcon:Icon(Icons.search_rounded),
            hintText:'Search registered team members')),
        const SizedBox(height:10),
        if(people.isEmpty)const EmptyPanel(title:'No workers found',
          message:'Create a team and add registered users first.'),
        for(final p in people)Padding(padding:const EdgeInsets.only(bottom:8),
          child:CyCard(
            color:selected.contains(p.id)?const Color(0xFFFFF8F4):Colors.white,
            onTap:()=>setState((){if(!selected.add(p.id)){selected.remove(p.id);}}),
            child:Row(children:[
              PersonAvatar(p),const SizedBox(width:10),
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(p.name,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w900,color:cyNavy)),
                Text('@'+p.username,style:const TextStyle(color:cyMuted,fontSize:10))
              ])),
              Icon(selected.contains(p.id)?Icons.check_box_rounded:Icons.check_box_outline_blank_rounded,
                color:selected.contains(p.id)?cyOrange:cyMuted),
            ]))),
      ])),
      Container(color:Colors.white,padding:const EdgeInsets.fromLTRB(18,10,18,15),child:Column(
        mainAxisSize:MainAxisSize.min,children:[
          Text(selected.length.toString()+' workers selected',style:const TextStyle(
            color:cyMuted,fontSize:11)),
          const SizedBox(height:7),
          SizedBox(width:double.infinity,child:FilledButton.icon(
            key:const Key('publish_work_notice'),icon:const Icon(Icons.campaign_rounded),
            label:const Text('PUBLISH WORK NOTICE'),
            onPressed:(){
              try{
                store.createWorkNotice(company:company.text,location:location.text,date:date,
                  reportingTime:formattedTime,memberIds:selected.toList(),instructions:instructions.text);
                Navigator.pop(context);
              }catch(e){toast(context,e.toString().replaceFirst('Invalid argument(s): ',''));}
            })),
        ]))
    ])));
  }
}
