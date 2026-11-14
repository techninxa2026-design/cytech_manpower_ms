import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'app_store.dart';
import 'payroll.dart';

class PayrollPdf {
  PayrollPdf._();
  static Future<Uint8List> build(AppStore store,MonthlyPayroll data)async{
    if(!store.isAdmin)throw StateError('Admin only');
    final document=pw.Document(title:'Cytech Manpower Payroll - '+monthLabel(data.month),
      author:'Cytech Engineering');
    final navy=PdfColor.fromHex('#071A2E'),orange=PdfColor.fromHex('#FC4B09'),
      muted=PdfColor.fromHex('#6D7C8B'),light=PdfColor.fromHex('#F2F6F8');
    final bold=pw.TextStyle(fontSize:10,fontWeight:pw.FontWeight.bold,color:navy);
    String money(double n)=>n.toStringAsFixed(2);
    document.addPage(pw.MultiPage(
      pageFormat:PdfPageFormat.a4,
      margin:const pw.EdgeInsets.all(34),
      header:(context)=>pw.Container(
        padding:const pw.EdgeInsets.symmetric(vertical:8),
        decoration:pw.BoxDecoration(border:pw.Border(bottom:pw.BorderSide(color:orange,width:2))),
        child:pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[
          pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
            pw.Text('CYTECH ENGINEERING',style:pw.TextStyle(fontSize:17,color:navy,fontWeight:pw.FontWeight.bold)),
            pw.SizedBox(height:3),
            pw.Text('MANPOWER MANAGEMENT  /  GROSS WAGE REGISTER',
              style:pw.TextStyle(color:orange,fontSize:8,fontWeight:pw.FontWeight.bold)),
          ]),
          pw.Text(monthLabel(data.month),style:bold)
        ])),
      footer:(context)=>pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[
        pw.Text('Locally generated demonstration report - BDT',style:pw.TextStyle(fontSize:7,color:muted)),
        pw.Text('Page '+context.pageNumber.toString()+' / '+context.pagesCount.toString(),
          style:pw.TextStyle(fontSize:7,color:muted)),
      ]),
      build:(context)=>[
        pw.SizedBox(height:23),
        pw.Text('Monthly payroll summary',style:pw.TextStyle(
          color:navy,fontSize:21,fontWeight:pw.FontWeight.bold)),
        pw.SizedBox(height:6),
        pw.Text('Gross earnings by attendance-based working hours. No deductions or payments included.',
          style:pw.TextStyle(fontSize:9,color:muted)),
        pw.SizedBox(height:14),
        pw.Container(padding:const pw.EdgeInsets.all(16),
          decoration:pw.BoxDecoration(color:navy,borderRadius:pw.BorderRadius.circular(9)),
          child:pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[
            _pdfStat('GROSS TOTAL',money(data.totalGross),PdfColors.white),
            _pdfStat('REGULAR HOURS',hourLabel(data.regularHours),PdfColors.white),
            _pdfStat('OVERTIME HOURS',hourLabel(data.overtimeHours),PdfColors.white),
          ])),
        pw.SizedBox(height:15),
        pw.Row(children:[
          pw.Text('Regular wages: BDT '+money(data.regularPay),style:bold),
          pw.Spacer(),
          pw.Text('Overtime wages: BDT '+money(data.overtimePay),style:bold),
        ]),
        pw.SizedBox(height:18),
        pw.Text('WORKER-WISE BREAKDOWN',style:pw.TextStyle(
          color:orange,fontWeight:pw.FontWeight.bold,fontSize:10)),
        pw.SizedBox(height:8),
        pw.TableHelper.fromTextArray(
          headers:['Worker / Username','Rate / Hour','Reg. Hrs','OT Hrs','Regular BDT','OT BDT','Gross BDT'],
          data:data.workers.map((w)=>[
            w.person.name+'\n@'+w.person.username,
            w.person.hourlyRate?.toStringAsFixed(2)??'NOT SET',
            hourLabel(w.regularHours),hourLabel(w.overtimeHours),
            money(w.regularPay),money(w.overtimePay),money(w.gross)
          ]).toList(),
          headerDecoration:pw.BoxDecoration(color:navy),
          headerStyle:pw.TextStyle(color:PdfColors.white,fontWeight:pw.FontWeight.bold,fontSize:7),
          cellStyle:pw.TextStyle(color:navy,fontSize:7),
          cellPadding:const pw.EdgeInsets.all(7),
          oddRowDecoration:pw.BoxDecoration(color:light),
          border:pw.TableBorder.symmetric(inside:pw.BorderSide(color:PdfColors.grey300)),
        ),
        pw.SizedBox(height:14),
        pw.Text('TOTAL PAYABLE GROSS: BDT '+money(data.totalGross),
          style:pw.TextStyle(color:orange,fontSize:14,fontWeight:pw.FontWeight.bold)),
        pw.SizedBox(height:16),
        if(data.missingRates)pw.Container(padding:const pw.EdgeInsets.all(10),
          color:PdfColor.fromHex('#FFF0DE'),
          child:pw.Text('WARNING: Some historical attendance shifts have no recorded hourly rate. Payroll amounts may be incomplete.',
            style:pw.TextStyle(fontSize:8,color:PdfColor.fromHex('#874D17')))),
        pw.SizedBox(height:11),
        pw.Text('Accounting notes',style:bold),
        pw.SizedBox(height:6),
        pw.Text('- Standard hours: first 8 hours of each shift. Overtime: hours above 8.\n'
          '- OT premium is captured at attendance publication (default 1.0x).\n'
          '- Historical rate snapshots are used for published reports.\n'
          '- Latest published attendance for the same group and date wins.\n'
          '- Separate group assignments on one date are counted separately.\n'
          '- This is an offline gross wages calculation, not a statutory payslip or proof of payment.',
          style:pw.TextStyle(fontSize:8,color:muted,height:1.6)),
      ],
    ));
    return document.save();
  }
  static pw.Widget _pdfStat(String title,String value,PdfColor color)=>pw.Column(
    crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
      pw.Text(title,style:pw.TextStyle(fontSize:7,color:PdfColors.grey300)),
      pw.SizedBox(height:7),
      pw.Text(value,style:pw.TextStyle(fontSize:18,color:color,fontWeight:pw.FontWeight.bold)),
    ]);
  static Future<void> share(AppStore store,MonthlyPayroll payroll)async{
    final bytes=await build(store,payroll);
    final m=payroll.month;
    final suffix=m.year.toString()+'-'+m.month.toString().padLeft(2,'0');
    await Printing.sharePdf(bytes:bytes,filename:'Cytech_Payroll_'+suffix+'.pdf');
  }
}
