import 'dart:convert';
import 'package:flutter/material.dart';
import 'app_store.dart';

const cyOrange=Color(0xFFFC4B09);
const cyOrangeSoft=Color(0xFFFFEEE6);
const cyNavy=Color(0xFF071A2E);
const cyNavyLight=Color(0xFF12324B);
const cyInk=Color(0xFF172333);
const cyMuted=Color(0xFF8190A1);
const cyCanvas=Color(0xFFF4F6F8);
const cyLine=Color(0xFFE6EBEF);
const cyPurple=Color(0xFF6B4DC6);

ThemeData cytechTheme(){
  final scheme=ColorScheme.fromSeed(seedColor:cyOrange,brightness:Brightness.light,
    primary:cyOrange,surface:Colors.white);
  return ThemeData(
    useMaterial3:true,colorScheme:scheme,scaffoldBackgroundColor:cyCanvas,
    appBarTheme:const AppBarTheme(backgroundColor:cyCanvas,foregroundColor:cyNavy,
      surfaceTintColor:Colors.transparent,elevation:0,centerTitle:false),
    textTheme:const TextTheme(
      headlineLarge:TextStyle(fontSize:31,fontWeight:FontWeight.w900,letterSpacing:-1.5,color:cyNavy),
      headlineMedium:TextStyle(fontSize:25,fontWeight:FontWeight.w900,letterSpacing:-.8,color:cyNavy),
      titleLarge:TextStyle(fontSize:19,fontWeight:FontWeight.w900,letterSpacing:-.5,color:cyNavy),
      titleMedium:TextStyle(fontSize:15,fontWeight:FontWeight.w800,color:cyInk),
      bodyMedium:TextStyle(fontSize:13,color:cyInk,height:1.4),
      bodySmall:TextStyle(fontSize:11,color:cyMuted,height:1.45),
    ),
    inputDecorationTheme:InputDecorationTheme(
      filled:true,fillColor:Colors.white,
      hintStyle:const TextStyle(fontSize:13,color:Color(0xFFABB7C2)),
      contentPadding:const EdgeInsets.symmetric(horizontal:15,vertical:16),
      border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:cyLine)),
      enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:cyLine)),
      focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:cyOrange,width:1.5)),
    ),
    filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(
      backgroundColor:cyOrange,foregroundColor:Colors.white,
      textStyle:const TextStyle(fontWeight:FontWeight.w800,fontSize:13),
      padding:const EdgeInsets.symmetric(vertical:16,horizontal:18),
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)))),
    outlinedButtonTheme:OutlinedButtonThemeData(style:OutlinedButton.styleFrom(
      foregroundColor:cyNavy,side:const BorderSide(color:cyLine),
      padding:const EdgeInsets.symmetric(vertical:15,horizontal:17),
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)))),
    snackBarTheme:SnackBarThemeData(backgroundColor:cyNavy,contentTextStyle:const TextStyle(color:Colors.white),
      behavior:SnackBarBehavior.floating,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))),
    dividerColor:cyLine,
  );
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key,this.size=42,this.color=cyOrange});
  final double size;final Color color;
  @override Widget build(BuildContext context)=>SizedBox(width:size,height:size,
    child:CustomPaint(painter:_BrandPainter(color)));
}
class _BrandPainter extends CustomPainter{
  _BrandPainter(this.color);final Color color;
  @override void paint(Canvas canvas,Size s){
    final pen=Paint()..color=color..strokeWidth=s.width*.068..style=PaintingStyle.stroke
      ..strokeCap=StrokeCap.square..strokeJoin=StrokeJoin.miter;
    Path lines(List<Offset> points){
      final p=Path()..moveTo(points.first.dx*s.width,points.first.dy*s.height);
      for(final x in points.skip(1)){p.lineTo(x.dx*s.width,x.dy*s.height);}
      return p;
    }
    canvas.drawPath(lines(const [
      Offset(.88,.305),Offset(.88,.25),Offset(.5,.045),Offset(.12,.25),
      Offset(.12,.75),Offset(.5,.955),Offset(.88,.75),Offset(.88,.695)
    ]),pen);
    canvas.drawPath(lines(const [
      Offset(.78,.376),Offset(.5,.239),Offset(.305,.35),Offset(.305,.65),
      Offset(.5,.763),Offset(.78,.62)
    ]),pen);
    canvas.drawPath(lines(const [Offset(.305,.50),Offset(.70,.50)]),pen);
  }
  @override bool shouldRepaint(covariant _BrandPainter old)=>old.color!=color;
}
class BrandLockup extends StatelessWidget{
  const BrandLockup({super.key,this.dark=false,this.compact=false});
  final bool dark,compact;
  @override Widget build(BuildContext context)=>Row(mainAxisSize:MainAxisSize.min,children:[
    BrandMark(size:compact?29:38),
    SizedBox(width:compact?8:10),
    Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
      Text('CYTECH',style:TextStyle(fontSize:compact?13:17,fontWeight:FontWeight.w900,
        letterSpacing:1.8,color:dark?Colors.white:cyNavy)),
      const Text('ENGINEERING',style:TextStyle(fontSize:8,fontWeight:FontWeight.w900,
        letterSpacing:2.8,color:cyOrange)),
    ]),
  ]);
}
class CyCard extends StatelessWidget{
  const CyCard({super.key,required this.child,this.padding=const EdgeInsets.all(15),
    this.onTap,this.color=Colors.white,this.margin=EdgeInsets.zero});
  final Widget child; final EdgeInsets padding,margin;final VoidCallback? onTap;final Color color;
  @override Widget build(BuildContext context){
    final inner=Container(margin:margin,padding:padding,decoration:BoxDecoration(color:color,
      borderRadius:BorderRadius.circular(17),border:Border.all(color:cyLine),
      boxShadow:const [BoxShadow(color:Color(0x07102037),blurRadius:18,offset:Offset(0,4))]),child:child);
    if(onTap==null)return inner;
    return InkWell(onTap:onTap,borderRadius:BorderRadius.circular(17),child:inner);
  }
}
class SectionTitle extends StatelessWidget{
  const SectionTitle(this.title,{super.key,this.action,this.onTap});
  final String title;final String? action;final VoidCallback? onTap;
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(top:18,bottom:11),
    child:Row(children:[
      Expanded(child:Text(title,style:const TextStyle(fontSize:15,fontWeight:FontWeight.w900,color:cyNavy))),
      if(action!=null)TextButton(onPressed:onTap,child:Text(action!,style:const TextStyle(
        color:cyOrange,fontSize:12,fontWeight:FontWeight.w800)))
    ]));
}
class StatusPill extends StatelessWidget{
  const StatusPill(this.label,{super.key,this.tint=cyOrange,this.background=cyOrangeSoft,this.icon});
  final String label;final Color tint,background;final IconData? icon;
  @override Widget build(BuildContext context)=>Container(
    padding:const EdgeInsets.symmetric(horizontal:9,vertical:6),
    decoration:BoxDecoration(color:background,borderRadius:BorderRadius.circular(8)),
    child:Row(mainAxisSize:MainAxisSize.min,children:[
      if(icon!=null)...[Icon(icon,size:12,color:tint),const SizedBox(width:4)],
      Text(label,style:TextStyle(fontSize:10,color:tint,fontWeight:FontWeight.w800))
    ]));
}
class PersonAvatar extends StatelessWidget{
  const PersonAvatar(this.person,{super.key,this.size=39});
  final Person person;final double size;
  @override Widget build(BuildContext context){
    final colors=[const Color(0xFFFFE9E0),const Color(0xFFE5E9FF),const Color(0xFFE2F5EB),const Color(0xFFFFE8F2)];
    final inks=[const Color(0xFFD35822),const Color(0xFF5948A9),const Color(0xFF16875A),const Color(0xFFB45678)];
    final index=person.name.codeUnits.fold<int>(0,(n,x)=>n+x)%4;
    final name=person.name.trim().split(' ');
    final letters=(name.isNotEmpty?name.first.substring(0,1):'')+(name.length>1?name.last.substring(0,1):'');
    return Container(width:size,height:size,alignment:Alignment.center,
      decoration:BoxDecoration(color:colors[index],borderRadius:BorderRadius.circular(size*.33)),
      child:Text(letters.toUpperCase(),style:TextStyle(fontSize:size*.3,fontWeight:FontWeight.w900,color:inks[index])));
  }
}
class AvatarStack extends StatelessWidget{
  const AvatarStack({super.key,required this.ids,required this.store});
  final List<String> ids;final AppStore store;
  @override Widget build(BuildContext context)=>SizedBox(height:27,
    child:Row(mainAxisSize:MainAxisSize.min,children:[
      for(final id in ids.take(4))Align(widthFactor:.76,child:Container(padding:const EdgeInsets.all(1.5),
        decoration:const BoxDecoration(color:Colors.white,shape:BoxShape.circle),
        child:ClipOval(child:PersonAvatar(store.person(id),size:24)))),
      if(ids.length>4)Padding(padding:const EdgeInsets.only(left:9),
        child:Text('+'+(ids.length-4).toString(),
          style:const TextStyle(fontSize:10,fontWeight:FontWeight.bold,color:cyMuted))),
    ]));
}
class GroupArtwork extends StatelessWidget{
  const GroupArtwork({super.key,required this.group,this.size=53});
  final WorkGroup group;final double size;
  @override Widget build(BuildContext context){
    final border=BorderRadius.circular(size*.31);
    if(group.imageBase64!=null&&group.imageBase64!.isNotEmpty){
      try {return ClipRRect(borderRadius:border,child:Image.memory(
        base64Decode(group.imageBase64!),width:size,height:size,fit:BoxFit.cover));}
      catch(_){/* Revert to illustrated group badge. */}
    }
    final palette=group.name.codeUnits.fold<int>(0,(n,x)=>n+x)%3;
    final colors=[cyNavy,cyOrange,const Color(0xFF247C83)];
    return Container(width:size,height:size,decoration:BoxDecoration(
      gradient:LinearGradient(colors:[colors[palette],Color.lerp(colors[palette],Colors.black,.2)!]),
      borderRadius:border),
      child:Stack(children:[
        Positioned(right:-14,top:-14,child:Transform.rotate(angle:.5,
          child:Container(width:size*.7,height:size*.7,decoration:BoxDecoration(
            border:Border.all(color:Colors.white.withValues(alpha:.13),width:7),
            borderRadius:BorderRadius.circular(10))))),
        const Center(child:Icon(Icons.groups_rounded,color:Colors.white,size:29)),
      ]));
  }
}
class InfoBanner extends StatelessWidget{
  const InfoBanner(this.text,{super.key,this.icon=Icons.info_outline_rounded,this.color=cyNavy});
  final String text;final IconData icon;final Color color;
  @override Widget build(BuildContext context)=>Container(
    padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:color.withValues(alpha:.07),
      borderRadius:BorderRadius.circular(12)),
    child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Icon(icon,color:color,size:18),const SizedBox(width:9),
      Expanded(child:Text(text,style:TextStyle(color:color,fontSize:11,height:1.5)))
    ]));
}
class EmptyPanel extends StatelessWidget{
  const EmptyPanel({super.key,required this.title,required this.message,this.icon=Icons.inbox_outlined});
  final String title,message;final IconData icon;
  @override Widget build(BuildContext context)=>CyCard(child:Padding(
    padding:const EdgeInsets.symmetric(vertical:28),child:Center(child:Column(children:[
      Container(padding:const EdgeInsets.all(16),decoration:const BoxDecoration(
        color:cyOrangeSoft,shape:BoxShape.circle),child:Icon(icon,color:cyOrange,size:26)),
      const SizedBox(height:13),Text(title,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:15)),
      const SizedBox(height:5),Text(message,textAlign:TextAlign.center,
        style:const TextStyle(fontSize:11,color:cyMuted,height:1.6)),
    ]))));
}
class AppPageHeader extends StatelessWidget{
  const AppPageHeader({super.key,required this.title,this.subtitle,this.actions=const []});
  final String title;final String? subtitle;final List<Widget> actions;
  @override Widget build(BuildContext context)=>Padding(
    padding:const EdgeInsets.fromLTRB(20,12,14,9),child:Row(children:[
      IconButton(onPressed:()=>Navigator.of(context).maybePop(),icon:const Icon(Icons.arrow_back_ios_new_rounded,size:19),
        style:IconButton.styleFrom(backgroundColor:Colors.white)),
      const SizedBox(width:7),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        if(subtitle!=null)Text(subtitle!.toUpperCase(),style:const TextStyle(
          fontSize:9,letterSpacing:1.5,color:cyOrange,fontWeight:FontWeight.w900)),
        Text(title,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(
          fontSize:19,fontWeight:FontWeight.w900,color:cyNavy))
      ])),
      ...actions,
    ]));
}
class FormLabel extends StatelessWidget{
  const FormLabel(this.text,{super.key});
  final String text;
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:8,top:15),
    child:Text(text,style:const TextStyle(color:cyNavy,fontSize:12,fontWeight:FontWeight.w800)));
}
class PagePadding extends StatelessWidget{
  const PagePadding({super.key,required this.child});
  final Widget child;
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(horizontal:19),child:child);
}
void toast(BuildContext context,String message){
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(message)));
}
