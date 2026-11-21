import 'dart:io';
import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/cytech_theme.dart';
import '../core/payroll.dart';
import 'attendance_approval_widgets.dart';
import 'daily_attendance_print.dart';

String attendanceGroupName(AppStore store,AttendanceReport report){
  if(report.groupName.isNotEmpty)return report.groupName;
  for(final group in store.groups){if(group.id==report.groupId)return group.name;}
  return 'Archived group';
}

class AttendanceRecordsCenter extends StatefulWidget{
  const AttendanceRecordsCenter({super.key,required this.store});
  final AppStore store;
  @override State<AttendanceRecordsCenter> createState()=>_AttendanceRecordsCenterState();
}
class _AttendanceRecordsCenterState extends State<AttendanceRecordsCenter>{
  DateTime? date;
  String group='all',query='',permitFilter='all';
  final search=TextEditingController();
  @override void dispose(){search.dispose();super.dispose();}
  @override Widget build(BuildContext context){
    final s=widget.store;
    if(!s.isAdmin)return const Center(child:Text('Admin only'));
    final groups=<String,String>{for(final g in s.groups)g.id:g.name};
    for(final a in s.attendance){groups.putIfAbsent(a.groupId,()=>attendanceGroupName(s,a));}
    final term=query.trim().toLowerCase();
    final rows=s.attendance.where((a){
      if(date!=null&&a.date!=dayKey(date!))return false;
      if(group!='all'&&a.groupId!=group)return false;
      if(permitFilter=='verified'&&!(a.permit?.isValid??false))return false;
      if(permitFilter=='missing'&&(a.permit?.isValid??false))return false;
      return term.isEmpty||[
        a.date,a.permit?.code??'',attendanceGroupName(s,a),
        s.person(a.authorId).name,
        ...a.present.keys.map((id)=>s.person(id).name+' '+s.person(id).username)
      ].any((x)=>x.toLowerCase().contains(term));
    }).toList()..sort((a,b){
      final d=b.date.compareTo(a.date);
      return d==0?b.createdAt.compareTo(a.createdAt):d;
    });
    final latest=<String,String>{};
    final byPublication=[...s.attendance]..sort((a,b){
      final d=b.createdAt.compareTo(a.createdAt);
      return d==0?b.id.compareTo(a.id):d;
    });
    for(final a in byPublication){latest.putIfAbsent(a.groupId+'|'+a.date,()=>a.id);}
    final effective=rows.where((a)=>latest[a.groupId+'|'+a.date]==a.id).toList();
    return ListView(padding:const EdgeInsets.fromLTRB(17,5,17,115),children:[
      Container(padding:const EdgeInsets.all(19),decoration:BoxDecoration(
        color:cyNavy,borderRadius:BorderRadius.circular(21)),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Row(children:[
            Icon(Icons.fact_check_rounded,color:cyOrange,size:20),SizedBox(width:8),
            Expanded(child:Text('ADMIN / ATTENDANCE RECORDS',style:TextStyle(
              color:cyOrange,fontSize:10,fontWeight:FontWeight.w900,letterSpacing:1.1))),
          ]),
          const SizedBox(height:13),
          const Text('Every shift. Every permit.',style:TextStyle(
            color:Colors.white,fontSize:24,fontWeight:FontWeight.w900,height:1.2)),
          const SizedBox(height:8),
          const Text('Inspect day-wise attendance, working hours, overtime and scanned Work Permits.',
            style:TextStyle(color:Color(0xFFBDD0DF),fontSize:12,height:1.55)),
          const SizedBox(height:17),
          Row(children:[
            Expanded(child:_stat(rows.length.toString(),'REPORTS')),
            Expanded(child:_stat(hourLabel(effective.fold<double>(0,(sum,a)=>sum+a.totalHours))+'h','WORKED')),
            Expanded(child:_stat(hourLabel(effective.fold<double>(0,(sum,a)=>sum+a.totalOvertime))+'h','OVERTIME')),
          ]),
        ])),
      const SizedBox(height:13),
      SizedBox(width:double.infinity,child:FilledButton.icon(
        key:const Key('records_daily_print'),onPressed:()=>_printDay(date==null?null:dayKey(date!)),
        icon:const Icon(Icons.print_rounded),label:const Text('PRINT DAILY ATTENDANCE'))),
      const SizedBox(height:13),
      TextField(key:const Key('records_search'),controller:search,
        onChanged:(v)=>setState(()=>query=v),
        decoration:InputDecoration(prefixIcon:const Icon(Icons.search_rounded),
          hintText:'Search permit, worker, group or date',
          suffixIcon:query.isEmpty?null:IconButton(onPressed:(){
            search.clear();setState(()=>query='');
          },icon:const Icon(Icons.clear_rounded)))),
      const SizedBox(height:9),
      Row(children:[
        Expanded(child:OutlinedButton.icon(
          key:const Key('records_date'),onPressed:()async{
            final next=await showDatePicker(context:context,initialDate:date??DateTime.now(),
              firstDate:DateTime(2020),lastDate:DateTime(2100));
            if(next!=null&&mounted)setState(()=>date=next);
          },icon:const Icon(Icons.calendar_month_rounded,size:17),
          label:FittedBox(fit:BoxFit.scaleDown,child:Text(date==null?'All dates':dayKey(date!))))),
        const SizedBox(width:8),
        TextButton(onPressed:(){
          search.clear();setState((){date=null;group='all';query='';permitFilter='all';});
        },child:const Text('RESET')),
      ]),
      const SizedBox(height:8),
      DropdownButtonFormField<String>(key:ValueKey(group),
        initialValue:groups.containsKey(group)?group:'all',isExpanded:true,
        decoration:const InputDecoration(prefixIcon:Icon(Icons.groups_outlined)),
        items:[const DropdownMenuItem(value:'all',child:Text('All groups')),
          for(final entry in groups.entries)DropdownMenuItem(value:entry.key,
            child:Text(entry.value,overflow:TextOverflow.ellipsis))],
        onChanged:(v)=>setState(()=>group=v??'all')),
      const SizedBox(height:9),
      Wrap(spacing:7,runSpacing:5,children:[
        for(final item in [('all','All permits'),('verified','Verified scan'),('missing','Missing / legacy')])
          ChoiceChip(label:Text(item.$2),selected:permitFilter==item.$1,
            onSelected:(_)=>setState(()=>permitFilter=item.$1)),
      ]),
      SectionTitle('Attendance history',action:rows.length.toString()+' RECORDS'),
      if(rows.isEmpty)const EmptyPanel(title:'No matching attendance',
        message:'Try another date, group, worker or permit code.',icon:Icons.fact_check_outlined),
      for(int i=0;i<rows.length;i++)...[
        if(i==0||rows[i].date!=rows[i-1].date)Padding(
          padding:const EdgeInsets.only(top:10,bottom:8),
          child:Row(children:[
            Expanded(child:Text(rows[i].date,style:const TextStyle(
              color:cyNavy,fontSize:14,fontWeight:FontWeight.w900))),
            TextButton.icon(onPressed:()=>_printDay(rows[i].date),
              icon:const Icon(Icons.print_outlined,size:17),label:const Text('Print day')),
          ])),
        Padding(padding:const EdgeInsets.only(bottom:9),
          child:_record(rows[i],latest[rows[i].groupId+'|'+rows[i].date]==rows[i].id)),
      ],
      const SizedBox(height:12),
      const InfoBanner('Records remain on this device. Prior reports without a photo are marked legacy. Superseded reports are retained for review; only the latest group/date counts in payroll.'),
    ]);
  }
  void _printDay(String? value)=>Navigator.push(context,MaterialPageRoute(
    builder:(_)=>DailyAttendancePrintPage(store:widget.store,initialDate:value,
      initialGroup:group=='all'?null:group)));
  Widget _stat(String value,String label)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    FittedBox(fit:BoxFit.scaleDown,child:Text(value,style:const TextStyle(
      color:Colors.white,fontWeight:FontWeight.w900,fontSize:20))),
    Text(label,style:const TextStyle(color:Color(0xFFBDD0DF),fontSize:9,fontWeight:FontWeight.w800)),
  ]);
  Widget _record(AttendanceReport a,bool effective){
    final proof=a.permit,verified=proof?.isValid??false;
    return CyCard(onTap:()=>Navigator.push(context,MaterialPageRoute(
      builder:(_)=>AttendanceRecordDetail(store:widget.store,report:a,effective:effective))),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          if(proof!=null&&verified)ClipRRect(borderRadius:BorderRadius.circular(9),
            child:Image.file(File(proof.imagePath),width:44,height:55,fit:BoxFit.cover,
              errorBuilder:(_,__,___)=>const Icon(Icons.broken_image_outlined)))
          else const Icon(Icons.description_outlined,color:cyMuted,size:34),
          const SizedBox(width:11),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(attendanceGroupName(widget.store,a),style:const TextStyle(
              color:cyNavy,fontSize:13,fontWeight:FontWeight.w900)),
            const SizedBox(height:4),
            Text(proof==null?'No legacy permit':('PTW '+proof.code),style:TextStyle(
              color:verified?const Color(0xFF138457):cyMuted,fontWeight:FontWeight.w800,fontSize:12)),
            Text('By '+widget.store.person(a.authorId).name,
              maxLines:1,overflow:TextOverflow.ellipsis,
              style:const TextStyle(color:cyMuted,fontSize:10)),
          ])),
          const Icon(Icons.chevron_right_rounded,color:cyMuted),
        ]),
        const Divider(height:21),
        Wrap(spacing:7,runSpacing:6,children:[
          StatusPill(a.presentCount.toString()+' present',tint:const Color(0xFF138457),
            background:const Color(0xFFE7F8EF)),
          StatusPill(a.absentCount.toString()+' absent',tint:const Color(0xFFB63D3D),
            background:const Color(0xFFFFECEB)),
          StatusPill(hourLabel(a.totalHours)+'h · '+hourLabel(a.totalOvertime)+'h OT'),
          StatusPill(effective?'CURRENT':'SUPERSEDED',tint:cyNavy,background:cyCanvas),
        ]),
        const SizedBox(height:10),
        AttendanceApprovalSummary(store:widget.store,reportId:a.id,compact:true),
      ]));
  }
}

class AttendanceRecordDetail extends StatelessWidget{
  const AttendanceRecordDetail({super.key,required this.store,required this.report,
    required this.effective});
  final AppStore store;
  final AttendanceReport report;
  final bool effective;
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:store,builder:(context,_){
    final a=store.attendanceById(report.id);
    if(a==null||!store.canInspectAttendance(a))return const Scaffold(body:Center(child:Text('Attendance review access required')));
    final proof=a.permit;
    final current=store.isCurrentAttendance(a);
    final verified=proof?.isValid??false;
    return Scaffold(body:SafeArea(child:Column(children:[
      AppPageHeader(title:'Attendance details',subtitle:a.date),
      Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(17,5,17,24),children:[
        CyCard(color:cyNavy,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          StatusPill(current?'CURRENT REPORT':'SUPERSEDED'),
          const SizedBox(height:12),
          Text(attendanceGroupName(store,a),style:const TextStyle(color:Colors.white,
            fontSize:21,fontWeight:FontWeight.w900)),
          const SizedBox(height:7),
          Text('Attendance date: '+a.date,style:const TextStyle(color:Colors.white70,fontSize:12)),
          Text('Published by '+store.person(a.authorId).name,style:const TextStyle(
            color:Colors.white70,fontSize:11)),
          Text('Published: '+a.createdAt.replaceFirst('T',' ').split('.').first,
            style:const TextStyle(color:Colors.white70,fontSize:11)),
        ])),
        const SectionTitle('Engineer approval'),
        AttendanceApprovalSummary(store:store,reportId:a.id),
        const SectionTitle('Work Permit'),
        CyCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          if(proof!=null)...[
            const Text('EXTRACTED PERMIT CODE',style:TextStyle(color:cyMuted,fontSize:10,fontWeight:FontWeight.w900)),
            const SizedBox(height:5),
            SelectableText(proof.code,style:const TextStyle(color:cyNavy,fontSize:27,
              fontWeight:FontWeight.w900,letterSpacing:2)),
            Text('Scanned: '+proof.scannedAt.replaceFirst('T',' ').split('.').first,
              style:const TextStyle(color:cyMuted,fontSize:10)),
            const SizedBox(height:10),
          ],
          if(proof!=null&&verified)...[
            const StatusPill('VERIFIED SCAN',tint:Color(0xFF138457),background:Color(0xFFE7F8EF)),
            const SizedBox(height:9),
            InkWell(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>
              _PermitImage(path:proof.imagePath,code:proof.code))),
              child:SizedBox(height:210,width:double.infinity,child:Image.file(
                File(proof.imagePath),fit:BoxFit.contain,
                errorBuilder:(_,__,___)=>const Center(child:Text('Photo unavailable'))))),
            const SizedBox(height:6),
            const Text('Tap image for full-page pinch-to-zoom',
              style:TextStyle(color:cyOrange,fontWeight:FontWeight.w800,fontSize:11)),
          ]else InfoBanner(proof==null?'Legacy attendance: no work permit was required at publication.':
            'The saved photo is missing or unavailable on this device.',
            icon:Icons.warning_amber_rounded,color:const Color(0xFFB63D3D)),
        ])),
        SectionTitle('Member attendance',action:a.present.length.toString()+' WORKERS'),
        Wrap(spacing:8,runSpacing:7,children:[
          StatusPill(a.presentCount.toString()+' PRESENT',tint:const Color(0xFF138457),
            background:const Color(0xFFE7F8EF)),
          StatusPill(a.absentCount.toString()+' ABSENT',tint:const Color(0xFFB63D3D),
            background:const Color(0xFFFFECEB)),
          StatusPill(hourLabel(a.totalHours)+'h worked'),
          StatusPill(hourLabel(a.totalOvertime)+'h OT'),
        ]),
        const SizedBox(height:11),
        for(final entry in a.present.entries)Padding(padding:const EdgeInsets.only(bottom:8),
          child:CyCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[
              PersonAvatar(store.person(entry.key)),const SizedBox(width:10),
              Expanded(child:Text(store.person(entry.key).name,style:const TextStyle(
                color:cyNavy,fontWeight:FontWeight.w900,fontSize:13))),
              StatusPill(entry.value?'PRESENT':'ABSENT',
                tint:entry.value?const Color(0xFF138457):const Color(0xFFB63D3D),
                background:entry.value?const Color(0xFFE7F8EF):const Color(0xFFFFECEB))
            ]),
            const Divider(height:21),
            Wrap(spacing:8,runSpacing:6,children:[
              StatusPill(hourLabel(a.hoursFor(entry.key))+'h WORKED',tint:cyNavy,background:cyCanvas),
              StatusPill(a.hoursFor(entry.key)>=8?'1 DAY':entry.value?'PARTIAL SHIFT':'NO SHIFT',
                tint:cyNavy,background:cyCanvas),
              if(a.overtimeFor(entry.key)>0)StatusPill('+'+hourLabel(a.overtimeFor(entry.key))+'h OT'),
            ]),
          ]))),
      ])),
      if(store.canApproveAttendance(a))Container(color:Colors.white,padding:const EdgeInsets.fromLTRB(17,10,17,14),
        child:EngineerApproveAction(store:store,reportId:a.id)),
    ])));
  });
}

class _PermitImage extends StatelessWidget {
  const _PermitImage({required this.path,required this.code});
  final String path,code;
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:cyNavy,
    appBar:AppBar(backgroundColor:cyNavy,foregroundColor:Colors.white,title:Text('Work Permit '+code)),
    body:SafeArea(child:InteractiveViewer(minScale:1,maxScale:8,
      child:Center(child:Image.file(File(path),fit:BoxFit.contain,
        errorBuilder:(_,__,___)=>const Text('Photo unavailable',style:TextStyle(color:Colors.white)))))));
}
