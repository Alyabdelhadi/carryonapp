/// The app's named routes. [path] is the URL segment handed to
/// `GoRoute.path`; `name` (the enum member name) is what `GoRoute.name`
/// and named navigation (`context.pushNamed`) use.
///
/// Top-level routes carry absolute paths (leading `/`). Sub-routes carry
/// relative segments and nest under their parent in the route tree.
///
/// Mapping from the Ionic app: `home`→home, `parcel`→packages, `my`→trips,
/// `account`/`login`→account tab, `list`→matching, `order-detail`→
/// orderDetail, `pinfo`→packageInfo, `pview`/`pview1`→orderForm,
/// `paddress`→addressPicker, `select-address`→addresses, `address`→
/// addressForm, `setting`→profile, `trip`→tripForm, `offer`→
/// carbonCalculator, `success/:type`→success.
enum Routes {
  splash('/splash'),

  // Blocking gates: the app shows nothing else while they apply.
  updateRequired('/update-required'),
  verifyIdentity('/verify-identity'),

  // Bottom tabs (stateful shell branches).
  home('/home'),
  packages('/packages'),
  trips('/trips'),
  account('/account'),

  // Auth flow (pushed on the root navigator).
  login('/login'),
  signup('/signup'),
  forgotPassword('/forgot-password'),

  // Package flow.
  matching('/matching'),
  orderDetail('/order/:id'),
  packageInfo('/package-info'),
  orderForm('/order-form'),
  addressPicker('/address-picker'),
  success('/success/:type'),

  // Trips.
  tripForm('/trip-form'),

  // Account.
  profile('/profile'),
  addresses('/addresses'),
  addressForm('/address-form'),
  carbonCalculator('/carbon-calculator'),
  wallet('/wallet');

  const Routes(this.path);

  final String path;
}

/// Which confirmation the success screen shows (`/success/:type`).
enum SuccessType {
  /// An order was posted or updated.
  orderPlaced(1),

  /// A carrier accepted a package.
  packageAccepted(2),

  /// An order was cancelled.
  orderCancelled(3);

  const SuccessType(this.code);

  final int code;

  static SuccessType fromCode(String? raw) {
    final code = int.tryParse(raw ?? '');
    for (final t in values) {
      if (t.code == code) return t;
    }
    return orderPlaced;
  }
}
