import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/cytech_theme.dart';

class AttendanceApprovalSummary extends StatelessWidget {
  const AttendanceApprovalSummary({super.key,required this.store,required this.reportId,this.compact=false});
  final AppStore store;
  final String reportId;
  final bool compact;
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:store,builder:(context,_){
    final report=store.attendanceById(reportId);
    if(report==null)return const SizedBox.shrink();
    final current=store.isCurrentAttendance(report);
    final engineers=store.assignedEngineers(report);
    final pending=engineers.where((id)=>!report.approvals.containsKey(id)&&id!=report.authorId).toList();
    final approvals=report.approvals.values.toList()
      ..sort((a,b)=>a.approvedAt.compareTo(b.approvedAt));
    final approved=approvals.isNotEmpty;
    final tint=approved?const Color(0xFF138457):const Color(0xFF996318);
    return Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(
      color:approved?const Color(0xFFEAF8F0):const Color(0xFFFFF3E3),
      borderRadius:BorderRadius.circular(13)),child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Icon(approved?Icons.verified_rounded:Icons.pending_actions_rounded,color:tint,size:20),
          const SizedBox(width:8),
          Expanded(child:Text(approved?'ENGINEER APPROVED':
            !current?'SUPERSEDED NOTICE':engineers.isEmpty?'NO ENGINEER ASSIGNED':'AWAITING ENGINEER APPROVAL',
            style:TextStyle(color:tint,fontSize:11,fontWeight:FontWeight.w900))),
        ]),
        for(final a in approvals)Padding(padding:const EdgeInsets.only(top:7),child:Row(
          crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Icon(Icons.check_circle_rounded,color:Color(0xFF138457),size:15),
            const SizedBox(width:6),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(a.engineerName,style:const TextStyle(color:cyNavy,fontSize:12,fontWeight:FontWeight.w800)),
              if(!compact)Text(a.approvedAt.replaceFirst('T',' ').split('.').first,
                style:const TextStyle(color:cyMuted,fontSize:10)),
            ])),
          ])),
        if(current&&pending.isNotEmpty)...[
          const SizedBox(height:7),
          Text(pending.contains(store.currentUserId)?'Your approval is pending · '+pending.length.toString()+' remaining':
            pending.length.toString()+' assigned engineer(s) still pending',
            style:TextStyle(color:tint,fontSize:11,fontWeight:FontWeight.w700)),
          if(!compact)Text(pending.map((id)=>store.person(id).name).join(', '),
            style:const TextStyle(color:cyMuted,fontSize:11,height:1.5)),
        ],
        if(!current)const Padding(padding:EdgeInsets.only(top:6),
          child:Text('Replaced by a newer attendance report. Historical approvals are retained.',
            style:TextStyle(color:cyMuted,fontSize:10,height:1.4))),
      ]));
  });
}

class EngineerApproveAction extends StatefulWidget{
  const EngineerApproveAction({super.key,required this.store,required this.reportId});
  final AppStore store;
  final String reportId;
  @override State<EngineerApproveAction> createState()=>_EngineerApproveActionState();
}
class _EngineerApproveActionState extends State<EngineerApproveAction>{
  bool saving=false;
  Future<void> approve()async{
    if(saving)return;
    final s=widget.store;
    final a=s.attendanceById(widget.reportId);
    if(a==null||!s.canApproveAttendance(a))return;
    final yes=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Approve attendance?'),
      content:Text('Confirm that you have reviewed the attendance for '+a.date+
        ', including workers, hours and available Work Permit. Your name and approval time will be recorded.'),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Confirm approval')),
      ]));
    if(yes!=true||!mounted)return;
    setState(()=>saving=true);
    try{
      await s.approveAttendance(widget.reportId);
      if(mounted)toast(context,'Attendance approved · '+s.me.name);
    }catch(e){if(mounted)toast(context,e.toString());}
    finally{if(mounted)setState(()=>saving=false);}
  }
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:widget.store,builder:(context,_){
    final a=widget.store.attendanceById(widget.reportId);
    if(a==null||!widget.store.canApproveAttendance(a))return const SizedBox.shrink();
    return SizedBox(width:double.infinity,child:FilledButton.icon(
      key:const Key('approve_attendance'),onPressed:saving?null:approve,
      icon:const Icon(Icons.verified_rounded),
      label:Text(saving?'Saving approval…':'Approve attendance')));
  });
}
