import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';

/// School SSO returns base64 DER. Common shapes:
/// 1) SubjectPublicKeyInfo  — SEQUENCE { alg, BIT STRING { SEQUENCE { n, e } } }
/// 2) PKCS#1 RSAPublicKey   — SEQUENCE { n, e }
String rsaEncryptPassword(String password, String publicKeyB64) {
  final cleaned = publicKeyB64
      .replaceAll(RegExp(r'\s'), '')
      .replaceAll(RegExp(r'^-+BEGIN [^-]+-+'), '')
      .replaceAll(RegExp(r'-+END [^-]+-+$'), '');
  if (cleaned.isEmpty) {
    throw StateError('RSA 公钥为空。');
  }

  Uint8List der;
  try {
    der = base64.decode(cleaned);
  } catch (_) {
    der = base64Url.decode(base64Url.normalize(cleaned));
  }

  final key = _parsePublicKey(der);
  final cipher = PKCS1Encoding(RSAEngine())
    ..init(true, PublicKeyParameter<RSAPublicKey>(key));
  return base64
      .encode(cipher.process(Uint8List.fromList(utf8.encode(password))));
}

RSAPublicKey _parsePublicKey(Uint8List der) {
  try {
    return _parseSpki(der);
  } catch (_) {
    // fall through
  }
  try {
    return _parsePkcs1(der);
  } catch (_) {
    // fall through
  }
  // Some servers send only the raw modulus+exponent SEQUENCE with BIT STRING wrapper variants
  final preview = der.take(24).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  throw StateError('无法解析学校 RSA 公钥（DER 前缀：$preview）。');
}

RSAPublicKey _parseSpki(Uint8List der) {
  final parser = ASN1Parser(der);
  final seq = parser.nextObject() as ASN1Sequence;
  final elements = seq.elements!;
  if (elements.length < 2) {
    throw StateError('SPKI 字段不足');
  }
  // algorithm identifier is elements[0]; public key bit string is elements[1]
  final bitString = elements[1];
  Uint8List keyBytes;
  if (bitString is ASN1BitString) {
    keyBytes = bitString.stringValues as Uint8List;
  } else {
    throw StateError('SPKI 第二段不是 BIT STRING');
  }
  return _parsePkcs1(keyBytes);
}

RSAPublicKey _parsePkcs1(Uint8List der) {
  final parser = ASN1Parser(der);
  final seq = parser.nextObject() as ASN1Sequence;
  final elements = seq.elements!;
  if (elements.length < 2) {
    throw StateError('PKCS#1 字段不足');
  }
  final n = _intBigInt(elements[0]);
  final e = _intBigInt(elements[1]);
  return RSAPublicKey(n, e);
}

BigInt _intBigInt(ASN1Object obj) {
  if (obj is ASN1Integer) {
    final value = obj.integer;
    if (value != null) return value;
  }
  throw StateError('不是 INTEGER');
}
