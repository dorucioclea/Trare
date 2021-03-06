// Authors: Romain Guillot and Mamadou Diouldé Diallo
//
// Doc: Done.
// Tests: TODO
import 'package:app/shared/models/user.dart';
import 'package:app/user/profile_service.dart';
import 'package:flutter/widgets.dart';


/// State enum used to represent the current state of the [ProfileProvider]
enum ProfileProviderState {
  /// Not yet initialized
  not_initialized,

  /// An error occured to load the connected user
  error,

  /// The provider is initialized, all processes finished
  initialized
}



/// [ChangeNotifier] used to handle the current connected [user] 
/// 
/// [user] is the current connected user.
///  At the provider creation the [user] is null. Consider calling [loadUser()]
/// method to load the user at the provider creation.
/// 
/// [state] is the current state of the provider, it can take the following
/// values :
/// - [ProfileProviderState.not_initialized]
/// - [ProfileProviderState.error]
/// - [ProfileProviderState.initialized]
/// 
/// To edit the current connected user used the method [editUser].
/// The listeners will be automatically notify with the new connected [user].
/// 
/// The pattern Observer is used to define a subscription mecanisme to notify
/// objects when a new [user] is available.
/// The method [notfifListeners()] has to be used to notify listeners
/// 
/// Usage :
/// 
/// ```dart
/// // UI -> Create the widget that wraps the provider
/// ChangeNotifierProvider<ProfileProvider>( 
///   create: (_) => ProfileProvider(
///   profileService: locator<IProfileService>(),
/// )..loadUser()
/// 
/// 
/// // Use a consomer to listen its state
/// Consumer<ProfileProvider>(
///   builder: (context, provider, child) {
///     // do whatever accordingly to the provider state
///   }
/// )
/// 
/// // Call the provider to do an action
/// Provider.of<ProfileProvider>(context, listen: false).editUser(user);
/// ```
/// 
/// See https://refactoring.guru/design-patterns/observer to know more about the
/// Observer pattern
class ProfileProvider extends ChangeNotifier {

  /// Service used to perform action on the user (get, edit)
  final IProfileService _profileService;


  /// The current provider state (not initialized, error, initialized)
  /// 
  /// See [ProfileProviderState]
  ProfileProviderState _state = ProfileProviderState.not_initialized;
  ProfileProviderState get state => _state;
  set state(state) {
    _state = state;
    notifyListeners();
  } 
  

  /// The current connected user.
  /// 
  /// Can be null for many reason (you can check the current state with the 
  /// flags [isInit] and [error])
  User _user;
  User get user => _user;


  ProfileProvider({
    @required IProfileService profileService,
  }) : this._profileService = profileService;


  /// Load the current user and update the [state] accordingly
  ///
  /// It begins the the `not_initialized` state and then ask the service
  /// to get the current connectect user.
  /// 
  /// The [IProfileService.getUser()] method is called to get the current
  /// connected user. This mehtod returns either the connected user, or 
  /// return an exception. (never null)
  /// So the method is surrouned by a try-catch and update the state accordingly
  /// (`initialized` or `error`)
  Future loadUser() async {
    try {
      _user = await _profileService.getUser();
    } catch (e) {
      state = ProfileProviderState.error;
    }
    state = ProfileProviderState.initialized;
  }


  /// Edit the current connected user with [newUser] data
  /// 
  /// Returns true is the update succeed, false else.
  /// It update and notify listeners of the new updated user.
  /// 
  /// To edit the user the method [IProfileService.editUser()] is called.
  /// This mehtod returns the updated user OR returns an exception. It never 
  /// retunrs null (if error, ...).
  /// So the method is simply surrouned with a try-catch. 
  /// If the operation succeed [true] is returned (try block).
  /// Else (if an error occured), [flase] is returned (catch block)
  Future<bool> editUser(User newUser) async {
    try {
      _user = await _profileService.editUser(newUser);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}