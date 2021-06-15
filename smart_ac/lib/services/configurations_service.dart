import 'package:cloud_firestore/cloud_firestore.dart';

class ConfigurationsService {

  static const _COLLECTION = 'configurations';
  static const _FAN_ID = 'fan';
  static final _instance = ConfigurationsService._getInstance();
  final _firestore = FirebaseFirestore.instance;

  ConfigurationsService._getInstance();

  factory ConfigurationsService.instance() => _instance;

  Future<int> getFanDistance() => _firestore.collection(_COLLECTION)
      .doc(_FAN_ID)
      .get()
      .then((snapshot) {
        if (!snapshot.exists || snapshot?.data()['distance'] == null) {
          return 0;
        }

        return snapshot.data()['distance'] as int;
      });

  Future<void> setFanDistance(int distance) => _firestore.collection(_COLLECTION)
      .doc(_FAN_ID)
      .set({ 'distance': distance });
}