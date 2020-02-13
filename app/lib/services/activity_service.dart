// Authors: Romain Guillot and Mamadou Diouldé Diallo
//
// Doc: Done
// Tests: TODO
import 'dart:async';

import 'package:app/models/activity.dart';
import 'package:app/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';



/// Services used to retreive activities store in database
///
/// For now, it has only one method to query activity base on their poisition
abstract class IActivitiesService {

  /// Performs a geoquery to retreive activities
  /// 
  /// Returns activities within the radius defined by [radius].(from [position])
  /// null is never returned
  /// An exception can be throwed if an error occured
  Future<List<Activity>> retreiveActivities({@required Position position, @required double radius});
}



/// Implementation of [IActivitiesService] that uses Firestore noSQL database
///
/// See interface-level documentation to know more. 
/// See the corresponding specification `documents > archi_server.md` (french)
/// 
/// Note:
///   - the package `geolocator` is used to performs geo queries
class FirestoreActivitiesService implements IActivitiesService {

  final _firestore = Firestore.instance;
  final geo = Geoflutterfire(); // used to perform geo queries
  

  /// See interface-level doc [IActivitiesService.retreiveActivities()] (specs)
  ///
  /// `geolocator` is used to perfoms to geo query thanks to the geohash store
  /// for each activity. [position] is transforms for [GeoFirePoint] and
  /// then the query is perfomed with the tranformed position and [radius]
  /// 
  /// Then, we retreive all activities data that we adapt with 
  /// [_FirestoreActivityAdapter] adapter to obtain [Activity] objects.
  /// We use [Completer] to complete the future once we retreive all activities
  @override
  Future<List<Activity>> retreiveActivities({@required Position position, @required double radius}) async {
    var completer = Completer<List<Activity>>();
    StreamSubscription subscribtion;
    
    var geoPosition = geo.point(
      latitude: position.latitude, 
      longitude: position.longitude
    );
    var activitiesCol = _firestore.collection(_Identifiers.ACTIVITIES_COL);
    subscribtion = geo.collection(collectionRef: activitiesCol).within(
      center: geoPosition, 
      radius: radius, 
      field: _Identifiers.ACTIVITY_LOCATION,
      strictMode: true
    ).listen((docSnaps) {
      var activities = List<Activity>();
      for (var docSnap in docSnaps) {
        var activity = _FirestoreActivityAdapter(data: docSnap.data);
        activities.add(activity);
      }
      completer.complete(activities);
      subscribtion.cancel();
    });
    return completer.future;
  }
}



/// Adpater used to adapt noSQL data ([Map]) to [Activity]
///
/// So it implements [Activity], and take a [Map] as constructor paramater
/// to build out [Activity] from the noSQL data. It allows to hide the complexity
/// of transformation.
/// 
/// See https://refactoring.guru/design-patterns/adapter to know more about the
/// adapter pattern.
class _FirestoreActivityAdapter implements Activity {
  
  @override DateTime createdDate;
  @override String title;
  @override User user;
  @override String description;
  @override DateTime beginDate;
  @override DateTime endDate;
  @override Position location;


  _FirestoreActivityAdapter({@required Map<String, dynamic> data}) {
    createdDate = data[_Identifiers.ACTIVITY_CREATED_DATE];
    title = data[_Identifiers.ACTIVITY_TITLE];
    user = data[_Identifiers.ACTIVITY_USER];
    description = data[_Identifiers.ACTIVITY_DESCRIPTION];
    beginDate = data[_Identifiers.ACTIVITY_BEGIN_DATE];
    endDate = data[_Identifiers.ACTIVITY_END_DATE];
    location = _buildPosition(data[_Identifiers.ACTIVITY_LOCATION]);
  }

  Position _buildPosition(dynamic data) {
    try {
      var geoPoint = data['geopoint'] as GeoPoint;
      return Position(latitude: geoPoint.latitude, longitude: geoPoint.longitude);
    } catch(_) {
      return null;
    }
  }
}



/// Identifiers (name of collections / fields) used in the Cloud Firestore
/// noSQL database to store activities
/// 
/// See the corresponding specification `documents > archi_server.md` (french)
class _Identifiers {
  static const ACTIVITIES_COL = "activities";

  static const ACTIVITY_CREATED_DATE = "createdDate";
  static const ACTIVITY_TITLE = "title";
  static const ACTIVITY_USER = "user";
  static const ACTIVITY_DESCRIPTION = "description";
  static const ACTIVITY_BEGIN_DATE = "beginDate";
  static const ACTIVITY_END_DATE = "endDate";
  static const ACTIVITY_LOCATION = "location";
}