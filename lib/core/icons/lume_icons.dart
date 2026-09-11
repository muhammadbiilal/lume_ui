/// The Lume icon set — 112 symbols, one consistent 24 px stroke family.
///
/// Extracted mechanically from the reference sprite in `index.html`: the path
/// geometry, the `viewBox` and every per-symbol override were copied
/// byte-for-byte, and the presentation the sprite inherited from CSS `.ico` —
/// `fill: none`, `stroke: currentColor`, `stroke-width: 1.75`, round caps and
/// round joins — was written onto each asset's root element, because an asset
/// has no stylesheet to inherit from.
///
/// **Do not substitute a Material icon where a Lume icon exists.** The set has
/// one weight and one corner language; a Material glyph beside a Lume glyph is
/// visible at a glance, and `test/core/icons/icon_manifest_test.dart` fails if
/// an asset goes missing rather than letting a silent fallback ship.
library;

/// Every icon name. The string is the asset's basename under `assets/icons/`
/// and matches the reference's sprite id with its `i-` prefix removed.
abstract final class LumeIcons {
  static const String alarm = 'alarm';
  static const String alert = 'alert';
  static const String arrowDown = 'arrow-down';
  static const String arrowR = 'arrow-r';
  static const String arrowUp = 'arrow-up';
  static const String arrowUr = 'arrow-ur';
  static const String baby = 'baby';
  static const String backspace = 'backspace';
  static const String bank = 'bank';
  static const String battery = 'battery';
  static const String beads = 'beads';
  static const String bell = 'bell';
  static const String bellRing = 'bell-ring';
  static const String bolt = 'bolt';
  static const String book = 'book';
  static const String bookmark = 'bookmark';
  static const String cake = 'cake';
  static const String calculator = 'calculator';
  static const String calendar = 'calendar';
  static const String camera = 'camera';
  static const String car = 'car';
  static const String cart = 'cart';
  static const String check = 'check';
  static const String checkCircle = 'check-circle';
  static const String checkSquare = 'check-square';
  static const String chevD = 'chev-d';
  static const String chevL = 'chev-l';
  static const String chevR = 'chev-r';
  static const String clock = 'clock';
  static const String cloud = 'cloud';
  static const String cloudSun = 'cloud-sun';
  static const String coins = 'coins';
  static const String compass = 'compass';
  static const String cricket = 'cricket';
  static const String currency = 'currency';
  static const String cycle = 'cycle';
  static const String device = 'device';
  static const String divide = 'divide';
  static const String download = 'download';
  static const String droplet = 'droplet';
  static const String eye = 'eye';
  static const String eyeOff = 'eye-off';
  static const String flame = 'flame';
  static const String folder = 'folder';
  static const String fuel = 'fuel';
  static const String gauge = 'gauge';
  static const String globe = 'globe';
  static const String graduation = 'graduation';
  static const String grid = 'grid';
  static const String heart = 'heart';
  static const String help = 'help';
  static const String home = 'home';
  static const String image = 'image';
  static const String info = 'info';
  static const String key = 'key';
  static const String list = 'list';
  static const String lock = 'lock';
  static const String login = 'login';
  static const String logout = 'logout';
  static const String lume = 'lume';
  static const String mail = 'mail';
  static const String message = 'message';
  static const String minus = 'minus';
  static const String moon = 'moon';
  static const String moonStar = 'moon-star';
  static const String mosque = 'mosque';
  static const String navigation = 'navigation';
  static const String news = 'news';
  static const String note = 'note';
  static const String package = 'package';
  static const String percent = 'percent';
  static const String phone = 'phone';
  static const String pill = 'pill';
  static const String pin = 'pin';
  static const String plane = 'plane';
  static const String play = 'play';
  static const String plus = 'plus';
  static const String prayer = 'prayer';
  static const String pulse = 'pulse';
  static const String qr = 'qr';
  static const String quote = 'quote';
  static const String receipt = 'receipt';
  static const String refresh = 'refresh';
  static const String route = 'route';
  static const String ruler = 'ruler';
  static const String scales = 'scales';
  static const String scan = 'scan';
  static const String search = 'search';
  static const String settings = 'settings';
  static const String share = 'share';
  static const String shield = 'shield';
  static const String signal = 'signal';
  static const String sliders = 'sliders';
  static const String sparkles = 'sparkles';
  static const String star = 'star';
  static const String stopwatch = 'stopwatch';
  static const String sun = 'sun';
  static const String swap = 'swap';
  static const String syringe = 'syringe';
  static const String target = 'target';
  static const String ticket = 'ticket';
  static const String timer = 'timer';
  static const String train = 'train';
  static const String trash = 'trash';
  static const String trending = 'trending';
  static const String user = 'user';
  static const String users = 'users';
  static const String utensils = 'utensils';
  static const String wallet = 'wallet';
  static const String wifi = 'wifi';
  static const String wind = 'wind';
  static const String x = 'x';

  /// Every name in the set, for manifest-completeness checks and the gallery.
  static const List<String> all = <String>[
    alarm,
    alert,
    arrowDown,
    arrowR,
    arrowUp,
    arrowUr,
    baby,
    backspace,
    bank,
    battery,
    beads,
    bell,
    bellRing,
    bolt,
    book,
    bookmark,
    cake,
    calculator,
    calendar,
    camera,
    car,
    cart,
    check,
    checkCircle,
    checkSquare,
    chevD,
    chevL,
    chevR,
    clock,
    cloud,
    cloudSun,
    coins,
    compass,
    cricket,
    currency,
    cycle,
    device,
    divide,
    download,
    droplet,
    eye,
    eyeOff,
    flame,
    folder,
    fuel,
    gauge,
    globe,
    graduation,
    grid,
    heart,
    help,
    home,
    image,
    info,
    key,
    list,
    lock,
    login,
    logout,
    lume,
    mail,
    message,
    minus,
    moon,
    moonStar,
    mosque,
    navigation,
    news,
    note,
    package,
    percent,
    phone,
    pill,
    pin,
    plane,
    play,
    plus,
    prayer,
    pulse,
    qr,
    quote,
    receipt,
    refresh,
    route,
    ruler,
    scales,
    scan,
    search,
    settings,
    share,
    shield,
    signal,
    sliders,
    sparkles,
    star,
    stopwatch,
    sun,
    swap,
    syringe,
    target,
    ticket,
    timer,
    train,
    trash,
    trending,
    user,
    users,
    utensils,
    wallet,
    wifi,
    wind,
    x,
  ];

  /// The asset path for a name.
  static String asset(String name) => 'assets/icons/$name.svg';

  /// Icons that mean **forward or back in reading order**, and therefore
  /// mirror in a right-to-left layout.
  ///
  /// This is the whole list. `rtl.css` flips exactly seven selectors and every
  /// one of them holds a chevron or an arrow of this kind: a section link, a
  /// list row's trailing glyph, a private card's chevron, a route pair, a hero
  /// slide's call to action, the onboarding footer button, and the picker's
  /// back control.
  static const Set<String> directional = <String>{
    chevR,
    chevL,
    arrowR,
    arrowUr,
    login,
    logout,
    backspace,
  };

  /// Icons that must **never** mirror, however the page reads.
  ///
  /// A clock face, a play triangle and a compass needle are not statements
  /// about reading order — they are pictures of real things, and a mirrored
  /// clock is simply a wrong clock. The brief's §17 and the Design System's §9
  /// both say it: mirror direction and layout, not numbers or media controls.
  static const Set<String> neverMirror = <String>{
    clock,
    timer,
    stopwatch,
    alarm,
    play,
    compass,
    navigation,
    gauge,
    qr,
    scan,
    percent,
    divide,
  };

  /// Whether [name] should be mirrored when the layout is right-to-left.
  static bool mirrors(String name) =>
      directional.contains(name) && !neverMirror.contains(name);
}
