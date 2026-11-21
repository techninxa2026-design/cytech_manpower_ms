import 'dart:ui';

class PermitText {
  const PermitText(this.text,this.bounds,{this.confidence});
  final String text;
  final Rect bounds;
  final double? confidence;
}

class PermitMatch {
  const PermitMatch(this.code,this.bounds);
  final String code;
  final Rect bounds;
}

/// Match the printed serial in the supplied five-digit PTW form, not arbitrary
/// numbers elsewhere on the document. Coordinates are in upright image pixels.
class PermitMatcher {
  static String normalized(String text)=>text.toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'),' ').trim();
  static bool isCode(String value)=>RegExp(r'^[0-9]{5}$').hasMatch(value.trim());
  static PermitMatch? match(List<PermitText> lines,List<PermitText> words,Size page) {
    if(page.width<900||page.height<1100||page.height<page.width) return null;
    final w=page.width,h=page.height;
    final full=normalized(lines.map((x)=>x.text).join(' '));
    // Require the header, body and lower-page landmarks; a cropped label alone
    // is not an acceptable full-page work permit.
    if(!(full.contains('permit to work')||full.contains('permitto work')) ||
       !(full.contains('location of work')||full.contains('description of work')) ||
       !(full.contains('post permit measures')||full.contains('closure by ptw')||
         full.contains('acknowledgement by performing authority'))) return null;
    final headers=lines.where((l)=>normalized(l.text).contains('permit to work')||
      normalized(l.text).contains('permitto work')).where((l)=>l.bounds.center.dy<h*.34).toList();
    final labels=lines.where((l)=>RegExp(r'\bptw\s*no\b').hasMatch(normalized(l.text)) &&
      l.bounds.center.dx>w*.52&&l.bounds.center.dy<h*.34).toList();
    if(headers.isEmpty||labels.isEmpty)return null;
    final part=lines.where((l)=>RegExp(r'\bpart\s*1\b').hasMatch(normalized(l.text)) &&
      l.bounds.center.dy<h*.45).map((l)=>l.bounds.top).toList();
    final candidates=<PermitText>[];
    for(final token in [...words,...lines]){
      if(!isCode(token.text))continue;
      final b=token.bounds;
      if(b.height<12||b.width<27||b.center.dx<w*.56||b.center.dy>h*.37)continue;
      final confidence=token.confidence;
      if(confidence!=null&&confidence>0&&confidence<.65)continue;
      if(part.isNotEmpty&&part.every((y)=>b.center.dy>=y))continue;
      if(!labels.any((l){
        final a=l.bounds;
        return b.center.dx>=a.left-w*.055 && b.center.dx<=a.right+w*.22 &&
          b.center.dy>=a.top-h*.025 && b.center.dy<=a.bottom+h*.15;
      }))continue;
      candidates.add(token);
    }
    final codes=candidates.map((c)=>c.text.trim()).toSet();
    if(codes.length!=1)return null;
    // Prefer the smallest exact box when both line and element contain the code.
    candidates.sort((a,b)=>(a.bounds.width*a.bounds.height).compareTo(b.bounds.width*b.bounds.height));
    return PermitMatch(codes.single,candidates.first.bounds);
  }
}
