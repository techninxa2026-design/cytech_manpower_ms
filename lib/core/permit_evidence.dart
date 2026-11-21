import 'dart:io';

/// A locally stored scan; legacy reports intentionally have no evidence.
class PermitEvidence {
  const PermitEvidence({required this.code, required this.imagePath,
    required this.scannedAt});
  final String code, imagePath, scannedAt;
  bool get isValid {
    if (!RegExp(r'^[0-9]{5}$').hasMatch(code) ||
        DateTime.tryParse(scannedAt) == null || imagePath.isEmpty) return false;
    try { return File(imagePath).existsSync() && File(imagePath).lengthSync() > 0; }
    on FileSystemException { return false; }
  }
  factory PermitEvidence.fromJson(Map<String,dynamic> json)=>PermitEvidence(
    code:json['code'] as String,imagePath:json['imagePath'] as String,
    scannedAt:json['scannedAt'] as String);
  Map<String,dynamic> toJson()=>{'code':code,'imagePath':imagePath,'scannedAt':scannedAt};
}
