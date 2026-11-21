import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/cytech_theme.dart';
import '../core/payroll.dart';
import 'attendance_records.dart';
import 'attendance_approval_widgets.dart';

class EngineerApprovalsCenter extends StatefulWidget{
  const EngineerApprovalsCenter({super.key,required this.store});
  final AppStore store;
  @override State<EngineerApprovalsCenter> createState()=>_EngineerApprovalsCenterState();
}
class _EngineerApprovalsCenterState extends State<EngineerApprovalsCenter>{
  bool completed=false;
  String search='';
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:widget.store,builder:(context,_){
    final s=widget.store;
    if(!s.hasEngineerRole)return const Center(child:Text('Assigned engineers only'));
    final pending=s.engineerPendingAttendance,approved=s.engineerApprovedAttendance;
    final q=search.trim().toLowerCase();
    final visible=(completed?approved:pending).where((a)=>[
      a.date,attendanceGroupName(s,a),a.permit?.code??'',s.person(a.authorId).name,
      ...a.present.keys.map((id)=>s.person(id).name)
    ].any((x)=>x.toLowerCase().contains(q))).toList();
    return ListView(padding:const EdgeInsets.fromLTRB(17,6,17,110),children:[
      CyCard(color:cyNavy,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Row(children:[
          Icon(Icons.verified_user_rounded,color:cyOrange,size:20),SizedBox(width:8),
          Expanded(child:Text('ENGINEERING / ATTENDANCE REVIEW',style:TextStyle(
            color:cyOrange,fontSize:10,fontWeight:FontWeight.w900,letterSpacing:1))),
        ]),
        const SizedBox(height:13),
        Text(pending.isEmpty?'You are all caught up.':pending.length.toString()+
          (pending.length==1?' attendance notice needs':' attendance notices need')+' your approval.',
          style:const TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.w900,height:1.2)),
        const SizedBox(height:8),
        const Text('Review the work permit, attendance and overtime before approving.',
          style:TextStyle(color:Color(0xFFBDD0DF),fontSize:12,height:1.6)),
        const SizedBox(height:17),
        Row(children:[
          Expanded(child:_metric(pending.length,'PENDING',cyOrange)),
          const SizedBox(width:8),
          Expanded(child:_metric(approved.length,'APPROVED',const Color(0xFF82D6AE))),
        ]),
      ])),
      const SizedBox(height:14),
      Wrap(spacing:8,children:[
        ChoiceChip(key:const Key('approval_pending_tab'),label:Text('Pending ('+pending.length.toString()+')'),
          selected:!completed,onSelected:(_)=>setState(()=>completed=false)),
        ChoiceChip(key:const Key('approval_completed_tab'),label:Text('Approved ('+approved.length.toString()+')'),
          selected:completed,onSelected:(_)=>setState(()=>completed=true)),
      ]),
      const SizedBox(height:12),
      TextField(key:const Key('approval_search'),onChanged:(v)=>setState(()=>search=v),
        decoration:const InputDecoration(prefixIcon:Icon(Icons.search_rounded),
          hintText:'Search date, group, permit or worker')),
      SectionTitle(completed?'Approval history':'Awaiting your approval',action:visible.length.toString()+' RECORDS'),
      if(visible.isEmpty)EmptyPanel(title:search.isNotEmpty?'No matching notices':
        completed?'No approvals yet':'No pending approvals',
        message:search.isNotEmpty?'Try a different search.':completed?
          'Your approved attendance notices will be saved here.':
          'New attendance from your assigned groups will appear here.',
        icon:Icons.verified_outlined),
      for(final a in visible)Padding(padding:const EdgeInsets.only(bottom:11),child:CyCard(
        onTap:()=>_open(context,a),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            const Icon(Icons.fact_check_outlined,color:cyOrange,size:30),
            const SizedBox(width:10),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(attendanceGroupName(s,a),style:const TextStyle(color:cyNavy,fontSize:14,fontWeight:FontWeight.w900)),
              const SizedBox(height:4),
              Text(a.date+' · '+s.person(a.authorId).name,style:const TextStyle(color:cyMuted,fontSize:11)),
            ])),
            const Icon(Icons.chevron_right_rounded,color:cyMuted),
          ]),
          const Divider(height:22),
          Wrap(spacing:6,runSpacing:6,children:[
            StatusPill(a.permit==null?'LEGACY · NO PERMIT':'PTW '+a.permit!.code),
            StatusPill(a.presentCount.toString()+' present',tint:const Color(0xFF138457),background:const Color(0xFFE7F8EF)),
            StatusPill(a.absentCount.toString()+' absent',tint:const Color(0xFFB63D3D),background:const Color(0xFFFFECEB)),
            StatusPill(hourLabel(a.totalHours)+'h · '+hourLabel(a.totalOvertime)+'h OT'),
          ]),
          const SizedBox(height:11),
          AttendanceApprovalSummary(store:s,reportId:a.id,compact:true),
          const SizedBox(height:10),
          SizedBox(width:double.infinity,child:OutlinedButton.icon(
            onPressed:()=>_open(context,a),icon:Icon(completed?Icons.visibility_outlined:Icons.fact_check_rounded,size:17),
            label:Text(completed?'View approval':'Review & approve'))),
        ]))),
      const InfoBanner('Approvals are individual. A corrected notice starts a new review. '
        'Approvals stay on this device until a backend is connected.'),
    ]);
  });
  Widget _metric(int n,String label,Color tint)=>Container(padding:const EdgeInsets.all(12),
    decoration:BoxDecoration(color:Colors.white.withValues(alpha:.08),borderRadius:BorderRadius.circular(13)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(n.toString(),style:TextStyle(color:tint,fontSize:25,fontWeight:FontWeight.w900)),
      Text(label,style:const TextStyle(color:Colors.white70,fontSize:10,fontWeight:FontWeight.w800)),
    ]));
  void _open(BuildContext context,AttendanceReport a)=>Navigator.push(context,MaterialPageRoute(
    builder:(_)=>AttendanceRecordDetail(store:widget.store,report:a,
      effective:widget.store.isCurrentAttendance(a))));
}
