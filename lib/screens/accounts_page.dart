import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/payroll.dart';
import '../core/payroll_pdf.dart';
import '../core/cytech_theme.dart';

class AccountsCenter extends StatefulWidget {
  const AccountsCenter({super.key,required this.store});
  final AppStore store;
  @override State<AccountsCenter> createState()=>_AccountsCenterState();
}
class _AccountsCenterState extends State<AccountsCenter>{
  DateTime month=DateTime(DateTime.now().year,DateTime.now().month);
  String section='earnings',groupId='all',search='';
  bool exporting=false;
  @override Widget build(BuildContext context){
    final store=widget.store;
    if(!store.isAdmin)return const Center(child:EmptyPanel(
      title:'Restricted Accounts',message:'Only the workspace admin may view payroll.',
      icon:Icons.lock_rounded));
    final pay=PayrollEngine.month(store,month,groupId:groupId=='all'?null:groupId);
    final selected=pay.workers.where((w)=>w.person.name.toLowerCase().contains(search.toLowerCase())||
      w.person.username.toLowerCase().contains(search.toLowerCase())).toList();
    return ListView(padding:const EdgeInsets.fromLTRB(17,5,17,115),children:[
      Container(padding:const EdgeInsets.all(20),
        decoration:BoxDecoration(gradient:const LinearGradient(
          colors:[cyNavy,Color(0xFF18445C)],begin:Alignment.topLeft,end:Alignment.bottomRight),
          borderRadius:BorderRadius.circular(22)),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Row(children:[
            Icon(Icons.account_balance_rounded,color:cyOrange,size:17),
            SizedBox(width:8),
            Text('PAYROLL CONTROL CENTER',style:TextStyle(color:cyOrange,
              letterSpacing:1.3,fontSize:10,fontWeight:FontWeight.w900)),
            Spacer(),
            Icon(Icons.verified_user_rounded,color:Colors.white54,size:18)
          ]),
          const SizedBox(height:19),
          const Text('Every hour.\nEvery taka.',style:TextStyle(
            color:Colors.white,fontWeight:FontWeight.w900,fontSize:27,height:1.13)),
          const SizedBox(height:9),
          const Text('Attendance hours turn into clear, auditable monthly wage estimates.',
            style:TextStyle(color:Color(0xFFB9CDD9),fontSize:11,height:1.6)),
          const SizedBox(height:18),
          Container(padding:const EdgeInsets.all(14),
            decoration:BoxDecoration(color:Colors.white.withValues(alpha:.09),
              borderRadius:BorderRadius.circular(13)),
            child:Row(children:[
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                const Text('MONTHLY GROSS WAGES',style:TextStyle(
                  color:Color(0xFFBDCEDB),fontSize:9,fontWeight:FontWeight.w900,
                  letterSpacing:1.1)),
                const SizedBox(height:7),
                FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,
                  child:Text(bdt(pay.totalGross),style:const TextStyle(
                    color:Colors.white,fontSize:24,fontWeight:FontWeight.w900))),
              ])),
              const Icon(Icons.account_balance_wallet_rounded,color:cyOrange,size:28)
            ])),
        ])),
      const SizedBox(height:11),
      CyCard(child:Row(children:[
        const Icon(Icons.calendar_month_rounded,color:cyOrange),
        const SizedBox(width:11),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('PAYROLL PERIOD',style:TextStyle(color:cyMuted,
            fontSize:9,fontWeight:FontWeight.w900,letterSpacing:1)),
          const SizedBox(height:4),
          Text(monthLabel(month),style:const TextStyle(color:cyNavy,
            fontWeight:FontWeight.w900,fontSize:14)),
        ])),
        OutlinedButton(onPressed:()async{
          final date=await showDatePicker(context:context,
            initialDate:month,firstDate:DateTime(2020),lastDate:DateTime(2100),
            helpText:'Choose a date in the payroll month');
          if(date!=null)setState(()=>month=DateTime(date.year,date.month));
        },child:const Text('CHANGE')),
      ])),
      const SizedBox(height:12),
      Row(children:[
        Expanded(child:_segment('earnings','Earnings',Icons.bar_chart_rounded)),
        const SizedBox(width:5),
        Expanded(child:_segment('rates','Worker rates',Icons.people_rounded)),
        const SizedBox(width:5),
        Expanded(child:_segment('policy','Policy',Icons.tune_rounded)),
      ]),
      const SizedBox(height:16),
      if(section=='earnings')...[
        Row(children:[
          Expanded(child:_metric('TOTAL HOURS',hourLabel(pay.hours)+'h',Icons.schedule_rounded)),
          const SizedBox(width:8),
          Expanded(child:_metric('ACTIVE WORKERS',pay.activeWorkers.toString(),
            Icons.groups_2_rounded)),
        ]),
        const SizedBox(height:9),
        Row(children:[
          Expanded(child:_moneyCard('REGULAR PAY',pay.regularPay,cyNavy)),
          const SizedBox(width:8),
          Expanded(child:_moneyCard('OVERTIME PAY',pay.overtimePay,cyOrange)),
        ]),
        if(pay.missingRates)...[
          const SizedBox(height:11),
          const InfoBanner('Warning: Some recorded hours have no wage rate. '
            'The payroll gross may be incomplete; enter missing worker rates.',color:Color(0xFFAE6614)),
        ],
        SectionTitle('Monthly earnings',action:pay.workers.length.toString()+' WORKERS'),
        TextField(onChanged:(v)=>setState(()=>search=v),
          decoration:const InputDecoration(prefixIcon:Icon(Icons.search_rounded),
            hintText:'Search worker name')),
        const SizedBox(height:9),
        DropdownButtonFormField<String>(
          initialValue:groupId,
          items:[const DropdownMenuItem(value:'all',child:Text('All groups')),
            ...store.groups.map((g)=>DropdownMenuItem(value:g.id,child:Text(g.name,
              overflow:TextOverflow.ellipsis)))],
          onChanged:(v)=>setState(()=>groupId=v??'all')),
        const SizedBox(height:13),
        if(selected.isEmpty)const EmptyPanel(title:'No workers found',
          message:'Try a different search or reporting month.'),
        for(final row in selected)Padding(padding:const EdgeInsets.only(bottom:8),
          child:_workerCard(row)),
        const SizedBox(height:11),
        CyCard(color:const Color(0xFFF0F5F9),child:Row(children:[
          Container(padding:const EdgeInsets.all(11),decoration:BoxDecoration(
            color:cyNavy,borderRadius:BorderRadius.circular(10)),
            child:const Icon(Icons.picture_as_pdf_rounded,color:Colors.white,size:22)),
          const SizedBox(width:11),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('Monthly payroll report',style:TextStyle(color:cyNavy,
              fontWeight:FontWeight.w900,fontSize:12)),
            const SizedBox(height:4),
            Text(monthLabel(month)+' · BDT · A4 PDF',style:const TextStyle(
              color:cyMuted,fontSize:10)),
          ])),
        ])),
        const SizedBox(height:10),
        SizedBox(width:double.infinity,child:FilledButton.icon(
          key:const Key('export_payroll_pdf'),onPressed:exporting?null:()async{
            setState(()=>exporting=true);
            try{
              await PayrollPdf.share(store,pay);
              if(context.mounted)toast(context,'Payroll PDF is ready in the Android share/save dialog.');
            }catch(e){if(context.mounted)toast(context,'PDF export failed: '+e.toString());}
            finally{if(mounted)setState(()=>exporting=false);}
          },icon:Icon(exporting?Icons.hourglass_top_rounded:Icons.download_rounded),
          label:Text(exporting?'CREATING PDF...':'GENERATE & SHARE MONTHLY PDF'))),
        const SizedBox(height:14),
        const InfoBanner('Gross wages only. Before deductions, advances, tax or payments. '
          'The latest attendance for each group and date is counted once; '
          'separate group shifts count separately.'),
      ]else if(section=='rates')...[
        const InfoBanner('Set each registered worker’s hourly wage in taka. '
          'A new rate affects future reports; published attendance retains its original rate.'),
        SectionTitle('Worker wage directory',action:store.people.where((p)=>!p.isAdmin).length.toString()+' WORKERS'),
        for(final p in store.people.where((p)=>!p.isAdmin))
          Padding(padding:const EdgeInsets.only(bottom:8),
            child:CyCard(onTap:()=>_openWorkerEditor(p.id),child:Row(children:[
              PersonAvatar(p),const SizedBox(width:11),
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(p.name,style:const TextStyle(color:cyNavy,
                  fontSize:12,fontWeight:FontWeight.w900)),
                Text('@'+p.username,style:const TextStyle(color:cyMuted,fontSize:10)),
              ])),
              Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
                Text(p.hourlyRate==null?'NOT SET':bdt(p.hourlyRate!),
                  style:const TextStyle(color:cyOrange,fontSize:12,fontWeight:FontWeight.w900)),
                const Text('PER HOUR  ✎',style:TextStyle(color:cyMuted,
                  fontSize:9,fontWeight:FontWeight.w800))
              ])
            ]))),
        const SizedBox(height:7),
        SizedBox(width:double.infinity,child:FilledButton.icon(
          onPressed:()=>_openWorkerEditor(null),
          icon:const Icon(Icons.person_add_alt_rounded),
          label:const Text('REGISTER WORKER + HOURLY WAGE'))),
      ]else...[
        const SectionTitle('Wage calculation policy'),
        CyCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Row(children:[Icon(Icons.schedule_rounded,color:cyOrange),
            SizedBox(width:9),Text('Standard 8-hour day',style:TextStyle(
              color:cyNavy,fontWeight:FontWeight.w900,fontSize:13))]),
          const SizedBox(height:9),
          const Text('0–8 hours count as regular payable hours. Any hours above 8 are overtime. '
            'An absent worker has 0 payable hours.',style:TextStyle(color:cyMuted,fontSize:11,height:1.6)),
        ])),
        const SizedBox(height:10),
        CyCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Row(children:[Icon(Icons.payments_rounded,color:cyOrange),
            SizedBox(width:9),Text('Overtime multiplier',style:TextStyle(
              color:cyNavy,fontWeight:FontWeight.w900,fontSize:13))]),
          const SizedBox(height:9),
          const Text('Default is 1× until Cytech confirms its pay policy. Changes apply to '
            'new attendance only.',style:TextStyle(color:cyMuted,fontSize:11,height:1.6)),
          const SizedBox(height:11),
          DropdownButtonFormField<double>(
            initialValue:store.overtimeMultiplier,
            items:const [
              DropdownMenuItem(value:1.0,child:Text('1.0× · Normal hourly rate')),
              DropdownMenuItem(value:1.5,child:Text('1.5× · Premium overtime')),
              DropdownMenuItem(value:2.0,child:Text('2.0× · Double hourly rate')),
            ],
            onChanged:(v){if(v!=null)store.setOvertimeMultiplier(v);},
          )
        ])),
        const SizedBox(height:10),
        const InfoBanner('Each published attendance report saves the worker wage rates and '
          'overtime multiplier. A later wage change cannot rewrite historical pay. '
          'This is a gross wages estimate, not a payment confirmation.'),
      ],
    ]);
  }
  Widget _segment(String value,String title,IconData icon){
    final selected=section==value;
    return InkWell(onTap:()=>setState(()=>section=value),
      borderRadius:BorderRadius.circular(12),
      child:Container(padding:const EdgeInsets.symmetric(vertical:12,horizontal:4),
        decoration:BoxDecoration(color:selected?cyNavy:Colors.white,
          border:Border.all(color:selected?cyNavy:cyLine),
          borderRadius:BorderRadius.circular(12)),
        child:Column(children:[
          Icon(icon,color:selected?cyOrange:cyMuted,size:19),
          const SizedBox(height:5),
          FittedBox(fit:BoxFit.scaleDown,child:Text(title,
            style:TextStyle(fontSize:11,fontWeight:FontWeight.w900,
              color:selected?Colors.white:cyMuted))),
        ]))));
  }
  Widget _metric(String title,String value,IconData icon)=>CyCard(
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Icon(icon,color:cyOrange,size:19),const SizedBox(height:8),
      Text(value,style:const TextStyle(color:cyNavy,fontSize:22,fontWeight:FontWeight.w900)),
      Text(title,style:const TextStyle(color:cyMuted,fontSize:9,fontWeight:FontWeight.w800))
    ]));
  Widget _moneyCard(String title,double amount,Color color)=>CyCard(
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(title,style:const TextStyle(color:cyMuted,fontSize:9,fontWeight:FontWeight.w900)),
      const SizedBox(height:6),
      FittedBox(fit:BoxFit.scaleDown,child:Text(bdt(amount),
        style:TextStyle(fontSize:18,color:color,fontWeight:FontWeight.w900))),
    ]));
  Widget _workerCard(WorkerPayroll w)=>CyCard(
    onTap:()=>Navigator.push(context,MaterialPageRoute(
      builder:(_)=>WorkerStatement(store:widget.store,payroll:w,month:month))),
    child:Column(children:[
      Row(children:[
        PersonAvatar(w.person),const SizedBox(width:10),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(w.person.name,style:const TextStyle(color:cyNavy,fontSize:12,fontWeight:FontWeight.w900)),
          const SizedBox(height:4),
          Text((w.person.hourlyRate==null?'Rate not set':bdt(w.person.hourlyRate!)+' / hr')+
            ' · '+w.shifts.toString()+' shifts',
            style:const TextStyle(color:cyMuted,fontSize:10)),
        ])),
        FittedBox(fit:BoxFit.scaleDown,child:Text(bdt(w.gross),style:const TextStyle(
          color:cyOrange,fontSize:14,fontWeight:FontWeight.w900))),
      ]),
      const Divider(height:22),
      Row(children:[
        const Icon(Icons.schedule_rounded,color:cyMuted,size:15),
        const SizedBox(width:5),
        Text(hourLabel(w.totalHours)+'h worked',style:const TextStyle(
          color:cyMuted,fontSize:10,fontWeight:FontWeight.w800)),
        const Spacer(),
        StatusPill('+'+hourLabel(w.overtimeHours)+'h OT'),
        const SizedBox(width:8),
        const Icon(Icons.chevron_right_rounded,color:cyMuted),
      ]),
      if(w.missingRate)...[
        const SizedBox(height:7),
        const Text('Rate missing on a recorded shift',style:TextStyle(
          color:Color(0xFFAE6614),fontSize:10,fontWeight:FontWeight.w800)),
      ],
    ]));
  void _openWorkerEditor(String? id)=>Navigator.push(context,
    MaterialPageRoute(builder:(_)=>WorkerWageEditor(store:widget.store,workerId:id)));
}

class WorkerStatement extends StatelessWidget {
  const WorkerStatement({super.key,required this.store,required this.payroll,required this.month});
  final AppStore store;final WorkerPayroll payroll;final DateTime month;
  @override Widget build(BuildContext context){
    if(!store.isAdmin)return const Scaffold(body:Center(child:Text('Admin only')));
    final w=payroll;
    return Scaffold(body:SafeArea(child:Column(children:[
      AppPageHeader(title:'Worker statement',subtitle:monthLabel(month)),
      Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(19,7,19,30),children:[
        CyCard(color:cyNavy,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          PersonAvatar(w.person,size:51),const SizedBox(height:12),
          const Text('MONTHLY PAY STATEMENT',style:TextStyle(color:cyOrange,
            fontSize:10,letterSpacing:1.1,fontWeight:FontWeight.w900)),
          const SizedBox(height:7),
          Text(w.person.name,style:const TextStyle(color:Colors.white,
            fontSize:20,fontWeight:FontWeight.w900)),
          Text('@'+w.person.username,style:const TextStyle(
            color:Color(0xFFB4C9D7),fontSize:11)),
          const SizedBox(height:16),
          Text(bdt(w.gross),style:const TextStyle(
            color:Colors.white,fontSize:26,fontWeight:FontWeight.w900)),
          const Text('GROSS EARNINGS',style:TextStyle(color:cyOrange,
            fontSize:10,fontWeight:FontWeight.w900,letterSpacing:1.1)),
        ])),
        const SizedBox(height:12),
        Row(children:[
          Expanded(child:_statementBox('REGULAR',hourLabel(w.regularHours)+'h',bdt(w.regularPay))),
          const SizedBox(width:8),
          Expanded(child:_statementBox('OVERTIME',hourLabel(w.overtimeHours)+'h',bdt(w.overtimePay))),
        ]),
        SectionTitle('Attendance ledger',action:w.lines.length.toString()+' ENTRIES'),
        if(w.lines.isEmpty)const EmptyPanel(title:'No shifts this month',
          message:'Published attendance will appear in this statement.'),
        for(final line in w.lines)Padding(padding:const EdgeInsets.only(bottom:8),
          child:CyCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[
              Expanded(child:Text(line.date,style:const TextStyle(
                color:cyNavy,fontSize:13,fontWeight:FontWeight.w900))),
              Text(bdt(line.gross),style:const TextStyle(
                color:cyOrange,fontSize:13,fontWeight:FontWeight.w900)),
            ]),
            const SizedBox(height:5),
            Text(line.groupName,style:const TextStyle(color:cyMuted,fontSize:11)),
            const Divider(height:22),
            Wrap(spacing:9,runSpacing:6,children:[
              StatusPill(line.present?'PRESENT':'ABSENT'),
              StatusPill(hourLabel(line.regularHours)+'h regular',
                tint:cyNavy,background:cyCanvas),
              StatusPill('+'+hourLabel(line.overtimeHours)+'h OT'),
            ]),
            const SizedBox(height:10),
            Text('Rate: '+(line.rate==null?'Missing':bdt(line.rate!)+'/h')+
              ' · Overtime '+line.overtimeMultiplier.toStringAsFixed(1)+'×',
              style:const TextStyle(color:cyMuted,fontSize:10)),
            const SizedBox(height:5),
            Text('Regular '+bdt(line.regularPay)+'   |   OT '+bdt(line.overtimePay),
              style:const TextStyle(color:cyNavy,fontSize:10,fontWeight:FontWeight.w800))
          ]))),
        if(w.missingRate)const InfoBanner('Some historical attendance lacks a wage rate. '
          'Verify the worker’s rate before approving this payroll.',color:Color(0xFFA46D13)),
        const SizedBox(height:13),
        OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(
          builder:(_)=>WorkerWageEditor(store:store,workerId:w.person.id))),
          icon:const Icon(Icons.edit_outlined),label:const Text('EDIT CURRENT HOURLY RATE')),
      ])),
    ])));
  }
  Widget _statementBox(String title,String hours,String amount)=>CyCard(
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(title,style:const TextStyle(color:cyMuted,fontSize:9,fontWeight:FontWeight.w900)),
      const SizedBox(height:9),
      Text(hours,style:const TextStyle(color:cyNavy,fontSize:19,fontWeight:FontWeight.w900)),
      const SizedBox(height:6),
      FittedBox(child:Text(amount,style:const TextStyle(
        color:cyOrange,fontSize:11,fontWeight:FontWeight.w900))),
    ]));
}

class WorkerWageEditor extends StatefulWidget{
  const WorkerWageEditor({super.key,required this.store,this.workerId});
  final AppStore store;final String? workerId;
  @override State<WorkerWageEditor> createState()=>_WorkerWageEditorState();
}
class _WorkerWageEditorState extends State<WorkerWageEditor>{
  late final TextEditingController name,username,rate;
  @override void initState(){
    super.initState();
    final existing=widget.workerId==null?null:widget.store.person(widget.workerId!);
    name=TextEditingController(text:existing?.name??'');
    username=TextEditingController(text:existing?.username??'');
    rate=TextEditingController(text:existing?.hourlyRate?.toStringAsFixed(2)??'');
    rate.addListener(refresh);
  }
  void refresh(){if(mounted)setState((){});}
  @override void dispose(){rate.removeListener(refresh);name.dispose();username.dispose();rate.dispose();super.dispose();}
  @override Widget build(BuildContext context){
    final s=widget.store;
    if(!s.isAdmin)return const Scaffold(body:Center(child:Text('Admin only')));
    final value=double.tryParse(rate.text),isEdit=widget.workerId!=null;
    return Scaffold(body:SafeArea(child:Column(children:[
      AppPageHeader(title:isEdit?'Edit worker wage':'Register worker',
        subtitle:'ACCOUNTING / HOURLY PAY'),
      Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(19,6,19,26),children:[
        CyCard(color:cyNavy,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('WORKFORCE / AGREED RATE',style:TextStyle(color:cyOrange,
            fontSize:10,letterSpacing:1.3,fontWeight:FontWeight.w900)),
          const SizedBox(height:9),
          Text(isEdit?'Update hourly wage.':'Create a worker profile.',
            style:const TextStyle(color:Colors.white,fontSize:21,fontWeight:FontWeight.w900)),
          const SizedBox(height:8),
          const Text('Future attendance uses this hourly rate. Historical reports keep their saved rate.',
            style:TextStyle(color:Color(0xFFBDCFDD),fontSize:11,height:1.6))
        ])),
        const FormLabel('Full member name *'),
        TextField(key:const Key('worker_name'),controller:name,
          decoration:const InputDecoration(hintText:'e.g. Shahin Ahmed')),
        const FormLabel('Unique username *'),
        TextField(key:const Key('worker_username'),controller:username,
          decoration:const InputDecoration(hintText:'e.g. shahin')),
        const FormLabel('Hourly wage (BDT) *'),
        TextField(key:const Key('worker_hourly_rate'),controller:rate,
          keyboardType:const TextInputType.numberWithOptions(decimal:true),
          decoration:const InputDecoration(prefixText:'৳  ',hintText:'e.g. 300')),
        const SizedBox(height:17),
        CyCard(color:cyNavy,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('WAGE PREVIEW',style:TextStyle(color:cyOrange,
            fontSize:10,fontWeight:FontWeight.w900,letterSpacing:1)),
          const SizedBox(height:11),
          Text(value==null?'Rate not set':bdt(value)+' / hour',
            style:const TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w900)),
          const SizedBox(height:7),
          Text('8h regular shift: '+bdt((value??0)*8),
            style:const TextStyle(color:Color(0xFFBFD1DC),fontSize:11)),
          const SizedBox(height:5),
          Text('9h shift incl. OT: '+bdt((value??0)*(8+s.overtimeMultiplier)),
            style:const TextStyle(color:Color(0xFFBFD1DC),fontSize:11)),
        ])),
        const SizedBox(height:12),
        const InfoBanner('For now, worker accounts are local-only. '
          'Production access control and payroll authorization will require a backend.'),
      ])),
      Container(color:Colors.white,padding:const EdgeInsets.fromLTRB(19,12,19,16),
        child:SizedBox(width:double.infinity,child:FilledButton.icon(
          key:const Key('save_worker_rate'),icon:const Icon(Icons.check_circle_outline_rounded),
          label:Text(isEdit?'SAVE WAGE RATE':'REGISTER WORKER'),
          onPressed:(){
            try{
              if(value==null)throw ArgumentError('Enter a valid hourly wage');
              if(isEdit){
                s.setWorkerRate(widget.workerId!,name:name.text,username:username.text,rate:value);
              }else{
                s.registerWorker(name:name.text,username:username.text,hourlyRate:value);
              }
              Navigator.pop(context);
            }catch(e){toast(context,e.toString().replaceFirst('Invalid argument(s): ',''));}
          }))),
    ])));
  }
}
