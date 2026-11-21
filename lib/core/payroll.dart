import 'dart:math' as math;
import 'app_store.dart';

class PayrollLine {
  const PayrollLine({required this.groupId,required this.groupName,required this.date,
    required this.present,required this.hours,required this.regularHours,
    required this.overtimeHours,required this.rate,required this.overtimeMultiplier,
    required this.regularPay,required this.overtimePay});
  final String groupId,groupName,date;
  final bool present;
  final double hours,regularHours,overtimeHours,overtimeMultiplier,regularPay,overtimePay;
  final double? rate;
  double get gross=>regularPay+overtimePay;
}
class WorkerPayroll {
  WorkerPayroll(this.person);
  final Person person;
  final List<PayrollLine> lines=[];
  bool missingRate=false;
  double get regularHours=>lines.fold<double>(0,(s,l)=>s+l.regularHours);
  double get overtimeHours=>lines.fold<double>(0,(s,l)=>s+l.overtimeHours);
  double get totalHours=>regularHours+overtimeHours;
  double get regularPay=>lines.fold<double>(0,(s,l)=>s+l.regularPay);
  double get overtimePay=>lines.fold<double>(0,(s,l)=>s+l.overtimePay);
  double get gross=>regularPay+overtimePay;
  int get fullDays=>lines.where((l)=>l.hours>=8).length;
  int get shifts=>lines.where((l)=>l.hours>0).length;
}
class MonthlyPayroll {
  MonthlyPayroll(this.month,this.groupId,this.workers);
  final DateTime month;
  final String? groupId;
  final List<WorkerPayroll> workers;
  double get totalGross=>workers.fold<double>(0,(s,w)=>s+w.gross);
  double get regularPay=>workers.fold<double>(0,(s,w)=>s+w.regularPay);
  double get overtimePay=>workers.fold<double>(0,(s,w)=>s+w.overtimePay);
  double get regularHours=>workers.fold<double>(0,(s,w)=>s+w.regularHours);
  double get overtimeHours=>workers.fold<double>(0,(s,w)=>s+w.overtimeHours);
  double get hours=>regularHours+overtimeHours;
  int get activeWorkers=>workers.where((w)=>w.totalHours>0).length;
  bool get missingRates=>workers.any((w)=>w.missingRate);
}
class PayrollEngine {
  const PayrollEngine._();
  static MonthlyPayroll month(AppStore store,DateTime date,{String? groupId}){
    final rows=<String,WorkerPayroll>{
      for(final p in store.people.where((p)=>!p.isAdmin))p.id:WorkerPayroll(p)
    };
    final monthPrefix=dayKey(DateTime(date.year,date.month)).substring(0,7);
    final reports=[...store.attendance]..sort((a,b){
      final t=b.createdAt.compareTo(a.createdAt);
      return t==0?b.id.compareTo(a.id):t;
    });
    // Only the most recently published report per group+date is payroll-effective.
    // A worker on two different groups on the same day has two distinct assignments.
    final uniqueDates=<String>{};
    for(final report in reports){
      if(!report.date.startsWith(monthPrefix))continue;
      if(groupId!=null&&report.groupId!=groupId)continue;
      if(!uniqueDates.add(report.groupId+'|'+report.date))continue;
      final groups=store.groups.where((g)=>g.id==report.groupId);
      final groupName=report.groupName.isNotEmpty?report.groupName:
        (groups.isEmpty?'Archived group':groups.first.name);
      for(final pair in report.present.entries){
        final row=rows[pair.key];
        if(row==null)continue;
        final hours=report.hoursFor(pair.key);
        final regular=math.min(8.0,hours);
        final overtime=math.max(0.0,hours-8);
        // Wage snapshots on newly published reports are authoritative.
        // Legacy v3 reports had no rate snapshot, so use current rate with warning if missing.
        final rate=report.rateSnapshot.containsKey(pair.key)?
          report.rateSnapshot[pair.key]:row.person.hourlyRate;
        final validRate=rate!=null&&rate.isFinite&&rate>=0;
        final multiplier=report.otMultiplier.isFinite&&report.otMultiplier>0?
          report.otMultiplier:1.0;
        if(!validRate&&hours>0)row.missingRate=true;
        final regularPay=validRate?regular*rate:0.0;
        final overtimePay=validRate?overtime*rate*multiplier:0.0;
        row.lines.add(PayrollLine(groupId:report.groupId,groupName:groupName,
          date:report.date,present:pair.value,hours:hours,
          regularHours:regular,overtimeHours:overtime,rate:rate,
          overtimeMultiplier:multiplier,regularPay:regularPay,overtimePay:overtimePay));
      }
    }
    final sorted=rows.values.toList()
      ..sort((a,b){final x=b.gross.compareTo(a.gross);return x==0?
          a.person.name.compareTo(b.person.name):x;});
    for(final worker in sorted){
      worker.lines.sort((a,b)=>b.date.compareTo(a.date));
    }
    return MonthlyPayroll(DateTime(date.year,date.month),groupId,sorted);
  }
}

String bdt(num money)=>'৳'+money.toStringAsFixed(2);
String hourLabel(num hours){
  final value=hours.toDouble();
  if(value==value.roundToDouble())return value.toInt().toString();
  return value.toStringAsFixed(1);
}
String monthLabel(DateTime date){
  const months=['January','February','March','April','May','June',
    'July','August','September','October','November','December'];
  return months[date.month-1]+' '+date.year.toString();
}
