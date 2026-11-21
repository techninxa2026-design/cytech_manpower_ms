import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/cytech_theme.dart';
import '../core/permit_scanner.dart';

/// A required, read-only OCR result. The user can retake the photo, never
/// manually type/override the number.
class WorkPermitField extends StatefulWidget {
  const WorkPermitField({super.key, required this.onChanged, this.locked=false});
  final ValueChanged<PermitScan?> onChanged;
  final bool locked;
  @override State<WorkPermitField> createState()=>_WorkPermitFieldState();
}
class _WorkPermitFieldState extends State<WorkPermitField>{
  PermitScan? scan;
  bool busy=false,confirmed=false;
  String? error;
  Future<void> pick(ImageSource source)async{
    if(busy||widget.locked)return;
    setState((){busy=true;error=null;scan=null;confirmed=false;});
    widget.onChanged(null);
    try{
      final picked=await ImagePicker().pickImage(source:source,
        maxWidth:3200,maxHeight:3200,imageQuality:97);
      if(picked==null)return;
      final next=await PermitScanner().scan(await picked.readAsBytes());
      if(mounted)setState(()=>scan=next);
    } on PermitScanException catch(e){
      if(mounted)setState(()=>error=e.message);
    } catch(_){
      if(mounted)setState(()=>error='Unable to read the photo. Use a clear JPEG or PNG and try again.');
    } finally{
      if(mounted)setState(()=>busy=false);
    }
  }
  void preview(PermitScan s){
    showDialog<void>(context:context,builder:(ctx)=>Dialog.fullscreen(
      backgroundColor:cyNavy,child:SafeArea(child:Column(children:[
        Row(children:[
          IconButton(onPressed:()=>Navigator.pop(ctx),
            icon:const Icon(Icons.close_rounded,color:Colors.white)),
          const Expanded(child:Text('Work Permit · zoom to inspect',
            style:TextStyle(color:Colors.white,fontWeight:FontWeight.w800))),
        ]),
        Expanded(child:InteractiveViewer(minScale:1,maxScale:6,
          child:Center(child:Image.memory(s.photo,fit:BoxFit.contain)))),
      ]))));
  }
  @override Widget build(BuildContext context){
    final s=scan;
    final enabled=!busy&&!widget.locked;
    return CyCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[
        Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(
          color:cyOrangeSoft,borderRadius:BorderRadius.circular(13)),
          child:const Icon(Icons.document_scanner_outlined,color:cyOrange,size:25)),
        const SizedBox(width:11),
        const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Work Permit',style:TextStyle(color:cyNavy,fontSize:16,fontWeight:FontWeight.w900)),
          Text('Required for every new attendance',style:TextStyle(color:cyMuted,fontSize:11)),
        ])),
        StatusPill(confirmed?'VERIFIED':'REQUIRED',
          tint:confirmed?const Color(0xFF138457):cyOrange,
          background:confirmed?const Color(0xFFE7F8EF):cyOrangeSoft)
      ]),
      const SizedBox(height:13),
      if(s==null)Container(
        width:double.infinity,padding:const EdgeInsets.all(17),
        decoration:BoxDecoration(color:cyCanvas,borderRadius:BorderRadius.circular(15),
          border:Border.all(color:cyLine)),
        child:const Column(children:[
          Icon(Icons.center_focus_strong_rounded,color:cyOrange,size:47),
          SizedBox(height:8),
          Text('Scan the entire permit page',textAlign:TextAlign.center,
            style:TextStyle(color:cyNavy,fontSize:14,fontWeight:FontWeight.w900)),
          SizedBox(height:6),
          Text('Keep all corners visible. Focus on the printed 5-digit PTW number at the upper right. Avoid glare, shadows and blur.',
            textAlign:TextAlign.center,style:TextStyle(color:cyMuted,fontSize:11,height:1.55)),
        ])),
      if(busy)...[
        const SizedBox(height:12),
        const LinearProgressIndicator(),
        const SizedBox(height:8),
        const Text('Scanning document, checking clarity and reading permit code…',
          style:TextStyle(fontSize:11,color:cyNavy,fontWeight:FontWeight.w800)),
      ],
      if(s!=null)...[
        InkWell(onTap:()=>preview(s),child:ClipRRect(
          borderRadius:BorderRadius.circular(14),
          child:SizedBox(height:178,width:double.infinity,
            child:Image.memory(s.photo,fit:BoxFit.contain)))),
        const SizedBox(height:8),
        const Center(child:Text('Tap full photo to inspect and zoom',
          style:TextStyle(color:cyMuted,fontSize:10))),
        const SizedBox(height:12),
        Container(width:double.infinity,padding:const EdgeInsets.all(13),
          decoration:BoxDecoration(color:const Color(0xFFE7F8EF),
            borderRadius:BorderRadius.circular(13)),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Row(children:[
              Icon(Icons.verified_rounded,color:Color(0xFF138457),size:18),
              SizedBox(width:6),
              Expanded(child:Text('PERMIT NUMBER DETECTED',
                style:TextStyle(color:Color(0xFF138457),fontWeight:FontWeight.w900,fontSize:10))),
            ]),
            const SizedBox(height:7),
            SelectableText(s.code,style:const TextStyle(color:cyNavy,
              fontSize:28,fontWeight:FontWeight.w900,letterSpacing:3)),
            const SizedBox(height:7),
            ClipRRect(borderRadius:BorderRadius.circular(6),child:SizedBox(
              width:155,height:47,child:Image.memory(s.numberPreview,fit:BoxFit.contain))),
          ])),
        CheckboxListTile(
          key:const Key('confirm_permit_scan'),contentPadding:EdgeInsets.zero,
          controlAffinity:ListTileControlAffinity.leading,
          value:confirmed,onChanged:enabled?(value){
            setState(()=>confirmed=value==true);
            widget.onChanged(confirmed?s:null);
          }:null,
          title:const Text('I confirm the detected number matches this photo.',
            style:TextStyle(fontWeight:FontWeight.w800,fontSize:12)),
          subtitle:const Text('If it does not match, retake or replace the scan.',
            style:TextStyle(fontSize:11))),
      ],
      if(error!=null)...[
        const SizedBox(height:9),
        InfoBanner(error!,icon:Icons.warning_amber_rounded,color:const Color(0xFFB63D3D)),
      ],
      const SizedBox(height:12),
      LayoutBuilder(builder:(context,box){
        final camera=FilledButton.icon(key:const Key('permit_camera'),
          onPressed:enabled?()=>pick(ImageSource.camera):null,
          icon:const Icon(Icons.camera_alt_outlined,size:18),
          label:Text(s==null?'Scan camera':'Retake'));
        final gallery=OutlinedButton.icon(key:const Key('permit_gallery'),
          onPressed:enabled?()=>pick(ImageSource.gallery):null,
          icon:const Icon(Icons.photo_library_outlined,size:18),label:const Text('Gallery'));
        return box.maxWidth<260
          ?Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            camera,const SizedBox(height:8),gallery])
          :Row(children:[Expanded(child:camera),const SizedBox(width:8),Expanded(child:gallery)]);
      }),
      const SizedBox(height:10),
      const Text('On-device OCR · no manual code entry · scan must pass both recognition checks.',
        style:TextStyle(color:cyMuted,fontSize:10,height:1.55)),
    ]));
  }
}
