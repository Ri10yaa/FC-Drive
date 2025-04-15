import 'dart:convert'; // For Base64 encoding
import 'package:encrypt/encrypt.dart' as encrypt;

String encryptFirebaseUid(String firebaseUid) {
  final String encryptionKey = 'thisismyfcdriveencryptsecretkey1'; // 32 bytes for AES-256
  final key = encrypt.Key.fromUtf8(encryptionKey);
  final iv = encrypt.IV.fromLength(16); // Random IV

  final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

  // Encrypt the Firebase UID
  final encrypted = encrypter.encrypt(firebaseUid, iv: iv);

  // Prepend IV to encrypted data
  final combined = iv.bytes + encrypted.bytes;

  // Encode combined data (IV + ciphertext) to Base64
  return base64Encode(combined);
}
