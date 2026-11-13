import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_store.dart';
import '../core/cytech_theme.dart';

class TeamDetail extends StatelessWidget{
  const TeamDetail({super.key,required this.store,required this.teamId});
  final AppStore store;final String teamId;
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:store,builder:(context,_){
    final matching=store.teams.where((t)=>t.id==teamId);
    if(matching.isEmpty)return const Scaffold(body:Center(child:Text('Team no longer exists')));
    final team=matching.first;
    return Scaffold(body:SafeArea(child:Column(children:[
      AppPageHeader(title:team.name,subtitle:'TEAM OVERVIEW',actions:[
        if(store.isAdmin)IconButton(
          onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>
            TeamEditor(store:store,teamId:team.id))),
          icon:const Icon(Icons.edit_outlined,color:cyOrange)),
      ]),
      Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(19,10,19,30),children:[
        CyCard(color:cyNavy,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const StatusPill('ACTIVE TEAM'),
          const SizedBox(height:15),
          Text(team.name,style:const TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.w900)),
          const SizedBox(height:6),
          Text(team.description.isEmpty?'Manpower workforce team':team.description,
            style:const TextStyle(color:Color(0xFFBBD0DD),fontSize:12,height:1.6)),
          const SizedBox(height:15),
          Row(children:[
            AvatarStack(ids:team.memberIds,store:store),const Spacer(),
            Text(team.memberIds.length.toString()+' MEMBERS',style:const TextStyle(
              color:Colors.white,fontSize:11,fontWeight:FontWeight.w900))
          ])
        ])),
        SectionTitle('Team members',action:team.memberIds.length.toString()+' PEOPLE'),
        if(team.memberIds.isEmpty)const EmptyPanel(title:'No members assigned',
          message:'The admin can edit this team and add registered users.'),
        for(final id in team.memberIds)
          Padding(padding:const EdgeInsets.only(bottom:8),child:CyCard(child:Row(children:[
            PersonAvatar(store.person(id)),const SizedBox(width:12),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(store.person(id).name,style:const TextStyle(
                fontSize:13,fontWeight:FontWeight.w900,color:cyNavy)),
              const SizedBox(height:4),
              Text('@'+store.person(id).username,style:const TextStyle(color:cyMuted,fontSize:11))
            ])),
            const StatusPill('REGISTERED'),
          ]))),
        if(store.isAdmin)...[
          const SizedBox(height:17),
          SizedBox(width:double.infinity,child:FilledButton.icon(
            onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>
              TeamEditor(store:store,teamId:teamId))),
            icon:const Icon(Icons.edit_rounded),label:const Text('EDIT TEAM & MEMBERS'))),
          const SizedBox(height:14),
          TextButton.icon(onPressed:()async{
            final yes=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
              title:const Text('Delete team?'),
              content:const Text('This team will be removed. Existing group assignments remain unchanged.'),
              actions:[
                TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('CANCEL')),
                FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('DELETE')),
              ]));
            if(yes==true){store.deleteTeam(teamId);if(context.mounted)Navigator.pop(context);}
          },icon:const Icon(Icons.delete_outline_rounded,color:Colors.redAccent),
            label:const Text('Delete team',style:TextStyle(color:Colors.redAccent))),
        ]
      ])),
    ])));
  });
}

class TeamEditor extends StatefulWidget{
  const TeamEditor({super.key,required this.store,this.teamId});
  final AppStore store;final String? teamId;
  @override State<TeamEditor> createState()=>_TeamEditorState();
}
class _TeamEditorState extends State<TeamEditor>{
  late final TextEditingController name,description,search;
  late final Set<String> members;
  @override void initState(){
    super.initState();
    final old=widget.teamId==null?null:widget.store.team(widget.teamId!);
    name=TextEditingController(text:old?.name??'');
    description=TextEditingController(text:old?.description??'');
    search=TextEditingController();
    members=(old?.memberIds??[]).toSet();
  }
  @override void dispose(){name.dispose();description.dispose();search.dispose();super.dispose();}
  @override Widget build(BuildContext context){
    if(!widget.store.isAdmin)return const Scaffold(body:Center(child:Text('Admin access required')));
    final people=widget.store.people.where((p)=>!p.isAdmin&&
      (p.name.toLowerCase().contains(search.text.toLowerCase())||
       p.username.toLowerCase().contains(search.text.toLowerCase()))).toList();
    return Scaffold(body:SafeArea(child:Column(children:[
      AppPageHeader(title:widget.teamId==null?'Create new team':'Edit team',subtitle:'WORKFORCE MANAGEMENT'),
      Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(19,4,19,24),children:[
        Container(padding:const EdgeInsets.all(19),decoration:BoxDecoration(
          color:cyNavy,borderRadius:BorderRadius.circular(20)),
          child:const Row(children:[
            CircleAvatar(radius:24,backgroundColor:Color(0xFF23425C),
              child:Icon(Icons.engineering_outlined,color:cyOrange,size:27)),
            SizedBox(width:14),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('BUILD YOUR CREW',style:TextStyle(color:cyOrange,
                fontWeight:FontWeight.w900,fontSize:10,letterSpacing:1.5)),
              SizedBox(height:5),
              Text('Organize one or more registered people into a reusable workforce team.',
                style:TextStyle(color:Colors.white,fontSize:12,height:1.5))
            ])),
          ])),
        const FormLabel('Team name'),
        TextField(key:const Key('team_name'),controller:name,
          decoration:const InputDecoration(hintText:'e.g. Electrical Maintenance Team')),
        const FormLabel('Description'),
        TextField(controller:description,minLines:2,maxLines:3,
          decoration:const InputDecoration(hintText:'What does this team handle?')),
        SectionTitle('Select registered members',action:members.length.toString()+' SELECTED'),
        TextField(controller:search,onChanged:(_)=>setState((){}),
          decoration:const InputDecoration(prefixIcon:Icon(Icons.search_rounded),
            hintText:'Search by name or username')),
        const SizedBox(height:10),
        for(final p in people)
          Padding(padding:const EdgeInsets.only(bottom:7),child:CyCard(
            color:members.contains(p.id)?const Color(0xFFFFF8F4):Colors.white,
            onTap:()=>setState((){members.contains(p.id)?members.remove(p.id):members.add(p.id);}),
            child:Row(children:[
              PersonAvatar(p),const SizedBox(width:11),
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(p.name,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:12,color:cyNavy)),
                Text('@'+p.username,style:const TextStyle(color:cyMuted,fontSize:10))
              ])),
              Icon(members.contains(p.id)?Icons.check_box_rounded:Icons.check_box_outline_blank_rounded,
                color:members.contains(p.id)?cyOrange:cyMuted),
            ]))),
        if(people.isEmpty)const EmptyPanel(title:'No matching users',
          message:'Try another search or register a demo account.'),
      ])),
      Container(color:Colors.white,padding:const EdgeInsets.fromLTRB(19,12,19,16),
        child:SizedBox(width:double.infinity,child:FilledButton.icon(
          key:const Key('save_team'),onPressed:(){
            if(name.text.trim().isEmpty){toast(context,'Please enter a team name');return;}
            if(members.isEmpty){toast(context,'Select at least one team member');return;}
            widget.store.saveTeam(id:widget.teamId,name:name.text,
              description:description.text,members:members.toList());
            Navigator.pop(context);
          },
          icon:const Icon(Icons.check_circle_outline_rounded),
          label:Text(widget.teamId==null?'CREATE TEAM':'SAVE TEAM')))),
    ])));
  }
}

class GroupEditor extends StatefulWidget{
  const GroupEditor({super.key,required this.store,this.groupId});
  final AppStore store;final String? groupId;
  @override State<GroupEditor> createState()=>_GroupEditorState();
}
class _GroupEditorState extends State<GroupEditor>{
  late final TextEditingController name,description;
  String? image;
  bool picking=false;
  @override void initState(){
    super.initState();
    final old=widget.groupId==null?null:widget.store.group(widget.groupId!);
    name=TextEditingController(text:old?.name??'');
    description=TextEditingController(text:old?.description??'');
    image=old?.imageBase64;
  }
  @override void dispose(){name.dispose();description.dispose();super.dispose();}
  Future<void> pickImage()async{
    if(picking)return;
    setState(()=>picking=true);
    try{
      final file=await ImagePicker().pickImage(
        source:ImageSource.gallery,maxWidth:640,maxHeight:640,imageQuality:62);
      if(file!=null){
        final bytes=await file.readAsBytes();
        if(bytes.length>900000){
          if(mounted)toast(context,'Please choose an image under 900 KB after compression.');
        }else if(mounted){setState(()=>image=base64Encode(bytes));}
      }
    }catch(_){if(mounted)toast(context,'Unable to open gallery on this device.');}
    finally{if(mounted)setState(()=>picking=false);}
  }
  @override Widget build(BuildContext context){
    if(!widget.store.isAdmin)return const Scaffold(body:Center(child:Text('Admin access required')));
    return Scaffold(body:SafeArea(child:Column(children:[
      AppPageHeader(title:widget.groupId==null?'Create group':'Edit group',subtitle:'GROUP WORKSPACE'),
      Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(19,5,19,25),children:[
        Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:cyNavy,
          borderRadius:BorderRadius.circular(20)),child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('BUILD A WORKSPACE',style:TextStyle(color:cyOrange,fontSize:10,
              fontWeight:FontWeight.w900,letterSpacing:1.5)),
            const SizedBox(height:8),
            const Text('A home for your people, daily reports & engineering issues.',
              style:TextStyle(color:Colors.white,fontSize:18,
                fontWeight:FontWeight.w900,height:1.35)),
            const SizedBox(height:12),
            Row(children:[
              const Icon(Icons.chat_bubble_outline_rounded,color:cyOrange,size:16),
              const SizedBox(width:7),
              Text('CHAT + NOTICES + COMPLAINTS',style:TextStyle(
                color:Colors.white.withValues(alpha:.75),fontSize:10,
                fontWeight:FontWeight.w800)),
            ])
          ])),
        const FormLabel('Group name'),
        TextField(key:const Key('group_name'),controller:name,
          decoration:const InputDecoration(hintText:'e.g. Project Alpha Site Crew')),
        const FormLabel('Description (optional)'),
        TextField(controller:description,maxLines:3,minLines:2,
          decoration:const InputDecoration(hintText:'Purpose, shift or site information')),
        const FormLabel('Group picture (optional)'),
        CyCard(onTap:pickImage,child:Row(children:[
          if(image!=null)ClipRRect(borderRadius:BorderRadius.circular(12),
            child:Image.memory(base64Decode(image!),width:65,height:65,fit:BoxFit.cover))
          else Container(width:65,height:65,decoration:BoxDecoration(
            gradient:const LinearGradient(colors:[cyNavy,cyNavyLight]),
            borderRadius:BorderRadius.circular(12)),
            child:const Icon(Icons.groups_2_rounded,color:cyOrange,size:32)),
          const SizedBox(width:13),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(image==null?'Illustrated cover included':'Custom cover selected',
              style:const TextStyle(fontWeight:FontWeight.w900,color:cyNavy,fontSize:12)),
            const SizedBox(height:5),
            Text(picking?'Opening gallery...':'Tap to choose an image from gallery',
              style:const TextStyle(color:cyMuted,fontSize:10)),
          ])),
          const Icon(Icons.add_photo_alternate_outlined,color:cyOrange),
        ])),
        if(image!=null)Align(alignment:Alignment.centerRight,child:TextButton(
          onPressed:()=>setState(()=>image=null),
          child:const Text('Use illustrated cover instead'))),
        const SizedBox(height:17),
        const InfoBanner('New groups start empty. On the next screen, assign one or more '
          'users from your teams and choose their role and assignment date.'),
      ])),
      Container(color:Colors.white,padding:const EdgeInsets.fromLTRB(19,12,19,16),
        child:SizedBox(width:double.infinity,child:FilledButton.icon(
          key:const Key('save_group'),onPressed:(){
            if(name.text.trim().isEmpty){toast(context,'Please give the group a name');return;}
            final id=widget.store.saveGroup(id:widget.groupId,
              name:name.text,description:description.text,imageBase64:image??'');
            if(widget.groupId==null){
              Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>
                AssignmentEditor(store:widget.store,groupId:id)));
            }else{Navigator.pop(context);}
          },
          icon:const Icon(Icons.arrow_forward_rounded),
          label:Text(widget.groupId==null?'CONTINUE TO MEMBERS':'SAVE CHANGES')))),
    ])));
  }
}

class AssignmentEditor extends StatefulWidget{
  const AssignmentEditor({super.key,required this.store,required this.groupId});
  final AppStore store;final String groupId;
  @override State<AssignmentEditor> createState()=>_AssignmentEditorState();
}
class _AssignmentEditorState extends State<AssignmentEditor>{
  late final Set<String> selected;
  late final Map<String,String> roles;
  late final TextEditingController search;
  DateTime date=DateTime.now();
  @override void initState(){
    super.initState();
    final original=widget.store.group(widget.groupId).members;
    selected=original.map((m)=>m.personId).toSet();
    roles={for(final a in original)a.personId:a.role};
    search=TextEditingController();
  }
  @override void dispose(){search.dispose();super.dispose();}
  Future<void> selectDate()async{
    final next=await showDatePicker(context:context,initialDate:date,
      firstDate:DateTime(2020),lastDate:DateTime(2100),
      helpText:'Assignment date');
    if(next!=null)setState(()=>date=next);
  }
  @override Widget build(BuildContext context){
    if(!widget.store.isAdmin)return const Scaffold(body:Center(child:Text('Admin access required')));
    final group=widget.store.group(widget.groupId);
    final all={...widget.store.allTeamMemberIds,...group.members.map((m)=>m.personId)}.toList();
    final filtered=all.map(widget.store.person).where((p)=>
      p.name.toLowerCase().contains(search.text.toLowerCase())||
      p.username.toLowerCase().contains(search.text.toLowerCase())).toList();
    return Scaffold(body:SafeArea(child:Column(children:[
      AppPageHeader(title:'Assign group members',subtitle:group.name),
      Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(19,5,19,25),children:[
        CyCard(color:cyNavy,child:Row(children:[
          const Icon(Icons.calendar_month_rounded,color:cyOrange,size:29),
          const SizedBox(width:13),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('ASSIGNMENT DATE',style:TextStyle(color:cyOrange,fontSize:10,
              letterSpacing:1.2,fontWeight:FontWeight.w900)),
            const SizedBox(height:5),
            Text(dayKey(date),style:const TextStyle(color:Colors.white,
              fontSize:17,fontWeight:FontWeight.w900)),
          ])),
          TextButton(onPressed:selectDate,child:const Text('CHANGE')),
        ])),
        const SizedBox(height:12),
        const InfoBanner('Only members of a registered team are eligible. Select multiple people, '
          'then choose Supervisor, Engineer or Member for each person.'),
        SectionTitle('Available team members',action:selected.length.toString()+' SELECTED'),
        TextField(controller:search,onChanged:(_)=>setState((){}),
          decoration:const InputDecoration(prefixIcon:Icon(Icons.search_rounded),
            hintText:'Find people across all teams')),
        const SizedBox(height:10),
        if(all.isEmpty)const EmptyPanel(title:'Create a team first',
          message:'Add registered users to a team before assigning them to groups.'),
        for(final p in filtered)
          Padding(padding:const EdgeInsets.only(bottom:8),child:CyCard(
            color:selected.contains(p.id)?const Color(0xFFFFF8F5):Colors.white,
            child:Column(children:[
              InkWell(onTap:()=>setState((){
                if(!selected.add(p.id)){selected.remove(p.id);}
                roles.putIfAbsent(p.id,()=>'member');
              }),child:Row(children:[
                PersonAvatar(p),const SizedBox(width:10),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(p.name,style:const TextStyle(color:cyNavy,fontSize:12,
                    fontWeight:FontWeight.w900)),
                  Text('@'+p.username,style:const TextStyle(fontSize:10,color:cyMuted))
                ])),
                Icon(selected.contains(p.id)?Icons.check_box_rounded:
                  Icons.check_box_outline_blank_rounded,
                  color:selected.contains(p.id)?cyOrange:cyMuted),
              ])),
              if(selected.contains(p.id))...[
                const Divider(height:18),
                Row(children:[
                  const Text('GROUP ROLE',style:TextStyle(color:cyMuted,fontSize:10,
                    fontWeight:FontWeight.w900)),
                  const Spacer(),
                  DropdownButton<String>(
                    value:roles[p.id]??'member',underline:const SizedBox.shrink(),
                    style:const TextStyle(fontSize:12,fontWeight:FontWeight.w900,color:cyNavy),
                    items:const [
                      DropdownMenuItem(value:'supervisor',child:Text('Supervisor')),
                      DropdownMenuItem(value:'engineer',child:Text('Engineer')),
                      DropdownMenuItem(value:'member',child:Text('Member')),
                    ],onChanged:(v)=>setState(()=>roles[p.id]=v??'member')),
                ]),
              ]
            ]))),
      ])),
      Container(color:Colors.white,padding:const EdgeInsets.fromLTRB(19,10,19,16),
        child:Column(mainAxisSize:MainAxisSize.min,children:[
          Text(selected.length.toString()+' people selected for '+dayKey(date),
            style:const TextStyle(color:cyMuted,fontSize:11)),
          const SizedBox(height:9),
          SizedBox(width:double.infinity,child:FilledButton.icon(
            key:const Key('save_assignments'),onPressed:(){
              final members=selected.map((id)=>GroupMember(
                personId:id,role:roles[id]??'member',assignedOn:dayKey(date))).toList();
              widget.store.saveAssignments(widget.groupId,members);
              toast(context,'Group assignments updated');
              Navigator.pop(context);
            },
            icon:const Icon(Icons.verified_rounded),label:const Text('SAVE GROUP ASSIGNMENTS'))),
        ])),
    ])));
  }
}
