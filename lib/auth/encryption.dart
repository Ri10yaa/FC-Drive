import 'dart:convert'; // For Base64 encoding
import 'package:encrypt/encrypt.dart' as encrypt;

String encrypt_it(String firebaseUid) {
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

String decrypt_it(String base64EncryptedUid) {
  final String encryptionKey = 'thisismyfcdriveencryptsecretkey1'; // 32 bytes for AES-256
  final key = encrypt.Key.fromUtf8(encryptionKey);

  // Decode the Base64-encoded string
  final encryptedBytes = base64Decode(base64EncryptedUid);

  // Extract IV and encrypted data
  final iv = encrypt.IV(encryptedBytes.sublist(0, 16));
  final encryptedData = encryptedBytes.sublist(16);

  // Decrypt using AES CBC
  final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  final decrypted = encrypter.decrypt(
    encrypt.Encrypted(encryptedData),
    iv: iv,
  );

  return decrypted;
}