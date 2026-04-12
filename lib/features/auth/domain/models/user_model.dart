import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? profileImageUrl;
  final String subscriptionStatus;
  final String? productId;
  final String? basePlanId;
  final String? purchaseToken;
  final String? orderId;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final DateTime? expiryDate;
  final bool autoRenewing;
  final double? priceAmount;
  final String? priceCurrencyCode;
  final String? billingPeriod;
  final int aiImagesGenerated;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.profileImageUrl,
    this.subscriptionStatus = 'free',
    this.productId,
    this.basePlanId,
    this.purchaseToken,
    this.orderId,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.expiryDate,
    this.autoRenewing = false,
    this.priceAmount,
    this.priceCurrencyCode,
    this.billingPeriod,
    this.aiImagesGenerated = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      subscriptionStatus: data['subscriptionStatus'] ?? 'free',
      productId: data['productId'],
      basePlanId: data['basePlanId'],
      purchaseToken: data['purchaseToken'],
      orderId: data['orderId'],
      subscriptionStartDate: data['subscriptionStartDate'] is Timestamp 
          ? (data['subscriptionStartDate'] as Timestamp).toDate() 
          : null,
      subscriptionEndDate: data['subscriptionEndDate'] is Timestamp 
          ? (data['subscriptionEndDate'] as Timestamp).toDate() 
          : null,
      expiryDate: data['expiryDate'] is Timestamp 
          ? (data['expiryDate'] as Timestamp).toDate() 
          : null,
      autoRenewing: data['autoRenewing'] ?? false,
      priceAmount: (data['priceAmount'] as num?)?.toDouble(),
      priceCurrencyCode: data['priceCurrencyCode'],
      billingPeriod: data['billingPeriod'],
      aiImagesGenerated: data['aiImagesGenerated'] ?? 0,
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'subscriptionStatus': subscriptionStatus,
      'productId': productId,
      'basePlanId': basePlanId,
      'purchaseToken': purchaseToken,
      'orderId': orderId,
      'subscriptionStartDate': subscriptionStartDate != null ? Timestamp.fromDate(subscriptionStartDate!) : null,
      'subscriptionEndDate': subscriptionEndDate != null ? Timestamp.fromDate(subscriptionEndDate!) : null,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'autoRenewing': autoRenewing,
      'priceAmount': priceAmount,
      'priceCurrencyCode': priceCurrencyCode,
      'billingPeriod': billingPeriod,
      'aiImagesGenerated': aiImagesGenerated,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? name,
    String? profileImageUrl,
    String? subscriptionStatus,
    String? productId,
    String? basePlanId,
    String? purchaseToken,
    String? orderId,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    DateTime? expiryDate,
    bool? autoRenewing,
    double? priceAmount,
    String? priceCurrencyCode,
    String? billingPeriod,
    int? aiImagesGenerated,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      productId: productId ?? this.productId,
      basePlanId: basePlanId ?? this.basePlanId,
      purchaseToken: purchaseToken ?? this.purchaseToken,
      orderId: orderId ?? this.orderId,
      subscriptionStartDate: subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      expiryDate: expiryDate ?? this.expiryDate,
      autoRenewing: autoRenewing ?? this.autoRenewing,
      priceAmount: priceAmount ?? this.priceAmount,
      priceCurrencyCode: priceCurrencyCode ?? this.priceCurrencyCode,
      billingPeriod: billingPeriod ?? this.billingPeriod,
      aiImagesGenerated: aiImagesGenerated ?? this.aiImagesGenerated,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
