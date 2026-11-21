import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../core/app_store.dart';
import '../core/cytech_theme.dart';
import '../core/daily_attendance_pdf.dart';
import '../core/payroll.dart';

class DailyAttendancePrintPage extends StatefulWidget {
  const DailyAttendancePrintPage({super.key,required this.store,this.initialDate,this.initialGroup});
  final AppStore store;
  final String? initialDate,initialGroup;
  @override State<DailyAttendancePrintPage> createState()=>_DailyAttendancePrintPageState();
}
class _DailyAttendancePrintPageState extends State<DailyAttendancePrintPage>{
  late String date;
  String? group;
  bool includePermits=true,busy=false;
  @override void initState(){
    super.initState();
    final dates=widget.store.attendance.map((a)=>a.date).toSet().toList()..sort((a,b)=>b.compareTo(a));
    date=widget.initialDate??(dates.isEmpty?dayKey(DateTime.now()):dates.first);
    group=widget.initialGroup;
  }
  Future<void> export({required bool print})async{
    if(busy||!widget.store.isAdmin||!widget.store.signedIn)return;
    setState(()=>busy=true);
    try{
      final bytes=await DailyAttendancePdf.build(widget.store,date,groupId:group,includePermits:includePermits);
      if(!mounted||!widget.store.isAdmin||!widget.store.signedIn)return;
      final name=DailyAttendancePdf.filename(date);
      if(print){
        await Printing.layoutPdf(name:name,onLayout:(_)=>bytes);
      }else{
        await Printing.sharePdf(bytes:bytes,filename:name);
      }
    }catch(e){if(mounted)toast(context,'Could not prepare attendance report: '+e.toString());}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:widget.store,builder:(context,_){
    final s=widget.store;
    if(!s.signedIn||!s.isAdmin)return const Scaffold(body:Center(child:Text('Admin only')));
    final groups=<String,String>{};
    for(final a in DailyAttendancePdf.records(s,date)){
      groups[a.groupId]=DailyAttendancePdf.groupName(s,a);
    }
    final options=DailyAttendancePdf.records(s,date,groupId:group);
    final worked=options.fold<double>(0,(n,a)=>n+a.totalHours);
    final overtime=options.fold<double>(0,(n,a)=>n+a.totalOvertime);
    final present=options.fold<int>(0,(n,a)=>n+a.presentCount);
    final absent=options.fold<int>(0,(n,a)=>n+a.absentCount);
    return Scaffold(body:SafeArea(child:Column(children:[
      const AppPageHeader(title:'Daily attendance print',subtitle:'ADMIN / ATTENDANCE RECORDS'),
      Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(17,6,17,24),children:[
        CyCard(color:cyNavy,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Icon(Icons.print_rounded,color:cyOrange,size:30),
          const SizedBox(height:12),
          const Text('One day. Complete record.',style:TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.w900)),
          const SizedBox(height:8),
          const Text('Generate a branded A4 attendance register, including member hours, work permits and engineer approvals.',
            style:TextStyle(color:Color(0xFFBDD0DF),fontSize:12,height:1.5)),
          const SizedBox(height:15),
          Text(date,style:const TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.w900)),
        ])),
        const SectionTitle('Report options'),
        OutlinedButton.icon(key:const Key('daily_print_date'),onPressed:busy?null:()async{
          final next=await showDatePicker(context:context,initialDate:DateTime.tryParse(date)??DateTime.now(),
            firstDate:DateTime(2020),lastDate:DateTime(2100));
          if(next!=null&&mounted)setState((){date=dayKey(next);group=null;});
        },icon:const Icon(Icons.calendar_month_rounded),label:Text('Attendance date: '+date)),
        const SizedBox(height:10),
        DropdownButtonFormField<String>(key:ValueKey('daily_print_'+date),
          initialValue:group??'all',isExpanded:true,
          decoration:const InputDecoration(labelText:'Report scope',prefixIcon:Icon(Icons.groups_outlined)),
          items:[const DropdownMenuItem(value:'all',child:Text('All groups')),
            for(final g in groups.entries)DropdownMenuItem(value:g.key,child:Text(g.value,overflow:TextOverflow.ellipsis)),
            if(group!=null&&!groups.containsKey(group))DropdownMenuItem(value:group!,child:const Text('Selected group (no records)')),
          ],
          onChanged:busy?null:(v)=>setState(()=>group=v=='all'?null:v)),
        const SizedBox(height:10),
        CyCard(child:SwitchListTile(contentPadding:EdgeInsets.zero,value:includePermits,
          onChanged:busy?null:(v)=>setState(()=>includePermits=v),
          title:const Text('Include Work Permit photos',style:TextStyle(color:cyNavy,fontWeight:FontWeight.w800,fontSize:13)),
          subtitle:const Text('Attach each saved photo on a separate A4 page. Missing photos are noted in the report.',
            style:TextStyle(color:cyMuted,fontSize:11)))),
        const SectionTitle('Report summary'),
        CyCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Wrap(spacing:8,runSpacing:8,children:[
            StatusPill(options.length.toString()+' GROUPS'),
            StatusPill(present.toString()+' PRESENT',tint:const Color(0xFF138457),background:const Color(0xFFE7F8EF)),
            StatusPill(absent.toString()+' ABSENT',tint:const Color(0xFFB63D3D),background:const Color(0xFFFFECEB)),
            StatusPill(hourLabel(worked)+'h WORKED'),StatusPill(hourLabel(overtime)+'h OT'),
          ]),
          const Divider(height:24),
          for(final a in options)Padding(padding:const EdgeInsets.only(bottom:8),
            child:Row(children:[
              const Icon(Icons.fact_check_outlined,color:cyOrange,size:17),const SizedBox(width:8),
              Expanded(child:Text(DailyAttendancePdf.groupName(s,a),style:const TextStyle(fontSize:12,fontWeight:FontWeight.w800,color:cyNavy))),
              Text(a.present.length.toString()+' entries',style:const TextStyle(fontSize:11,color:cyMuted)),
            ])),
          if(options.isEmpty)const Text('No attendance for this selection. Choose another date or group.',
            style:TextStyle(color:cyMuted,fontSize:12)),
        ])),
        const SizedBox(height:12),
        const InfoBanner('Only the most recent report for each group and date is printed. '
          'Present and absent totals count worker-group entries. Search and permit filters in the records list '
          'do not restrict this daily register. Engineer approvals are included without altering payroll.'),
      ])),
      Container(color:Colors.white,padding:const EdgeInsets.fromLTRB(17,10,17,15),
        child:Column(mainAxisSize:MainAxisSize.min,children:[
          SizedBox(width:double.infinity,child:FilledButton.icon(
            key:const Key('daily_print_submit'),onPressed:busy||options.isEmpty?null:()=>export(print:true),
            icon:const Icon(Icons.print_rounded),label:Text(busy?'Preparing report…':'Print / save as PDF'))),
          const SizedBox(height:7),
          SizedBox(width:double.infinity,child:OutlinedButton.icon(
            key:const Key('daily_print_share'),onPressed:busy||options.isEmpty?null:()=>export(print:false),
            icon:const Icon(Icons.share_outlined),label:const Text('Share PDF'))),
        ])),
    ])));
  });
}
