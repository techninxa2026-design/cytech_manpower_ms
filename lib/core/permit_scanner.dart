import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart' show compute;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'permit_evidence.dart';
import 'permit_matcher.dart';

class PermitScanException implements Exception {
  const PermitScanException(this.message);
  final String message;
  @override String toString()=>message;
}

class PermitScan {
  const PermitScan._(this.code,this.photo,this.numberPreview,this.scannedAt);
  final String code, scannedAt;
  final Uint8List photo,numberPreview;
  /// Write the normalized full-page scan before the attendance record is saved.
  Future<PermitEvidence> persist() async {
    final root=await getApplicationDocumentsDirectory();
    final folder=await Directory(root.path+'/work_permits').create(recursive:true);
    final file=File(folder.path+'/permit_'+DateTime.now().microsecondsSinceEpoch.toString()+'.jpg');
    await file.writeAsBytes(photo,flush:true);
    return PermitEvidence(code:code,imagePath:file.path,scannedAt:scannedAt);
  }
}

/// Decode and rotate outside the UI isolate. Never upsample the full source to
/// satisfy minimum resolution checks.
Map<String,Object>? _upright((Uint8List,int) input){
  var source=img.decodeImage(input.$1);
  if(source==null)return null;
  source=img.bakeOrientation(source);
  if(input.$2!=0)source=img.copyRotate(source,angle:input.$2);
  if(source.width<900||source.height<1100||source.width>source.height)return null;
  if(source.height>3200)source=img.copyResize(source,height:3200);
  return {'bytes':img.encodeJpg(source,quality:96),'width':source.width,'height':source.height};
}

/// Check local contrast and edge detail of the serial itself, then enlarge its
/// crop for an independent second OCR pass.
Uint8List? _numberCrop((Uint8List,List<double>) input){
  final source=img.decodeImage(input.$1);
  if(source==null)return null;
  final b=input.$2;
  final x=(b[0]-b[3]*.30).floor().clamp(0,source.width-1).toInt();
  final y=(b[1]-b[3]*.20).floor().clamp(0,source.height-1).toInt();
  final right=(b[0]+b[2]+b[3]*.30).ceil().clamp(x+1,source.width).toInt();
  final bottom=(b[1]+b[3]*.20+b[3]).ceil().clamp(y+1,source.height).toInt();
  final patch=img.copyCrop(source,x:x,y:y,width:right-x,height:bottom-y);
  double gray(int a,int c){
    final p=patch.getPixel(a,c);
    return .299*p.r+.587*p.g+.114*p.b;
  }
  double minL=255,maxL=0,sum=0;int count=0;
  for(int j=1;j<patch.height-1;j++){
    for(int i=1;i<patch.width-1;i++){
      final v=gray(i,j);
      minL=math.min(minL,v);maxL=math.max(maxL,v);
      final lap=4*v-gray(i-1,j)-gray(i+1,j)-gray(i,j-1)-gray(i,j+1);
      sum+=lap*lap;count++;
    }
  }
  if(count==0||maxL-minL<35||math.sqrt(sum/count)<5)return null;
  return img.encodeJpg(img.copyResize(patch,width:patch.width*3,
    interpolation:img.Interpolation.cubic),quality:98);
}

class PermitScanner {
  Future<PermitScan> scan(Uint8List original) async {
    if(original.isEmpty||original.length>20*1024*1024) {
      throw const PermitScanException('Choose a readable image under 20 MB.');
    }
    final cache=await getTemporaryDirectory();
    final temp=await cache.createTemp('permit_scan_');
    final recognizer=TextRecognizer(script:TextRecognitionScript.latin);
    try{
      final fullFile=File(temp.path+'/full.jpg'),cropFile=File(temp.path+'/number.jpg');
      // EXIF orientation is normalized, then every right-angle orientation is tried.
      for(final angle in [0,90,270,180]){
        final frame=await compute(_upright,(original,angle));
        if(frame==null)continue;
        final bytes=frame['bytes'] as Uint8List;
        final size=Size((frame['width'] as int).toDouble(),(frame['height'] as int).toDouble());
        await fullFile.writeAsBytes(bytes,flush:true);
        final recognized=await recognizer.processImage(InputImage.fromFilePath(fullFile.path));
        final lines=<PermitText>[],words=<PermitText>[];
        for(final block in recognized.blocks){
          for(final line in block.lines){
            lines.add(PermitText(line.text,line.boundingBox,confidence:line.confidence));
            for(final word in line.elements){
              words.add(PermitText(word.text,word.boundingBox,confidence:word.confidence));
            }
          }
        }
        final match=PermitMatcher.match(lines,words,size);
        if(match==null)continue;
        final b=match.bounds;
        final crop=await compute(_numberCrop,(bytes,[b.left,b.top,b.width,b.height]));
        if(crop==null)continue;
        await cropFile.writeAsBytes(crop,flush:true);
        final repeated=await recognizer.processImage(InputImage.fromFilePath(cropFile.path));
        final number=repeated.text.trim().replaceAll(RegExp(r'\s+'),'');
        if(number!=match.code)continue;
        return PermitScan._(match.code,bytes,crop,DateTime.now().toIso8601String());
      }
      throw const PermitScanException('Work Permit number could not be verified. Capture the entire page, keep the printed PTW number sharp, avoid glare, and try again.');
    } finally {
      await recognizer.close();
      if(await temp.exists())await temp.delete(recursive:true);
    }
  }
}
