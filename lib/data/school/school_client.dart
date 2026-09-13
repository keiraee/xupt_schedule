import 'dart:convert';
import 'dart:io';

import 'rsa.dart';
import 'schedule_parser.dart';
import 'school_models.dart';

export 'school_models.dart';

class _Cookie {
  _Cookie(this.name, this.value, {this.domain = '', this.path = '/'});

  String name;
  String value;
  String domain;
  String path;

  bool matches(Uri uri) {
    final host = uri.host.toLowerCase();
    var d = domain.toLowerCase();
    if (d.startsWith('.')) d = d.substring(1);
    if (d.isNotEmpty && host != d && !host.endsWith('.$d')) return false;
    final p = path.isEmpty ? '/' : path;
    return uri.path == p ||
        uri.path.startsWith(p.endsWith('/') ? p : '$p/') ||
        p == '/';
  }
}

class _CookieJar {
  final List<_Cookie> _items = [];

  void set(String name, String value, {String domain = '', String path = '/'}) {
    _items.removeWhere((item) =>
        item.name == name &&
        item.domain.toLowerCase() == domain.toLowerCase() &&
        item.path == path);
    _items.add(_Cookie(name, value, domain: domain, path: path));
  }

  void absorb(Uri uri, List<String> setCookieHeaders) {
    for (final raw in setCookieHeaders) {
      final parts = raw.split(';');
      if (parts.isEmpty) continue;
      final nv = parts.first.trim();
      final eq = nv.indexOf('=');
      if (eq <= 0) continue;
      final name = nv.substring(0, eq).trim();
      final value = nv.substring(eq + 1).trim();
      var domain = uri.host;
      var path = '/';
      for (final attr in parts.skip(1)) {
        final kv = attr.trim();
        final lower = kv.toLowerCase();
        if (lower.startsWith('domain=')) {
          domain = kv.substring(7).trim();
        } else if (lower.startsWith('path=')) {
          path = kv.substring(5).trim();
          if (path.isEmpty) path = '/';
        }
      }
      if (value.isEmpty) {
        _items.removeWhere((item) =>
            item.name == name &&
            item.domain.toLowerCase() == domain.toLowerCase() &&
            item.path == path);
      } else {
        set(name, value, domain: domain, path: path);
      }
    }
  }

  String headerFor(Uri uri) {
    return _items
        .where((item) => item.matches(uri))
        .map((item) => '${item.name}=${item.value}')
        .join('; ');
  }

  bool hasGmisSession() {
    return _items.any((item) =>
        item.domain.contains('xupt.edu.cn') && item.name == 'ASP.NET_SessionId');
  }

  void clearGmis() {
    _items.removeWhere((item) => item.domain.contains('gmis.xupt.edu.cn'));
  }

  String? valueOf(String name) {
    for (final item in _items) {
      if (item.name == name) return item.value;
    }
    return null;
  }

  Map<String, dynamic> dump() => {
        'cookies': _items
            .map((item) => {
                  'name': item.name,
                  'value': item.value,
                  'domain': item.domain,
                  'path': item.path,
                })
            .toList(),
      };

  void load(Map<String, dynamic> payload) {
    _items.clear();
    final list = payload['cookies'];
    if (list is! List) return;
    for (final item in list) {
      if (item is Map) {
        set(
          item['name']?.toString() ?? '',
          item['value']?.toString() ?? '',
          domain: item['domain']?.toString() ?? '',
          path: item['path']?.toString() ?? '/',
        );
      }
    }
  }
}

class _HttpResult {
  _HttpResult({
    required this.statusCode,
    required this.headers,
    required this.body,
    required this.url,
    this.location,
  });

  final int statusCode;
  final HttpHeaders headers;
  final String body;
  final Uri url;
  final String? location;

  bool get isRedirect =>
      statusCode == 301 ||
      statusCode == 302 ||
      statusCode == 303 ||
      statusCode == 307 ||
      statusCode == 308;

  bool get looksJson {
    final type = headers.contentType?.mimeType ?? '';
    return type.contains('json') || body.trimLeft().startsWith('{');
  }
}

class SchoolClient {
  SchoolClient() {
    _client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..idleTimeout = const Duration(seconds: 30)
      ..maxConnectionsPerHost = 2
      ..autoUncompress = true
      ..userAgent =
          'Mozilla/5.0 (Linux; Android 13; 25102RKBEC) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36';
  }

  static const authOrigin = 'https://auth.xupt.edu.cn';
  static const schoolLogin = 'https://gmis.xupt.edu.cn/pyxx/Logincas.aspx';
  static const schoolHome = 'https://gmis.xupt.edu.cn/pyxx/default.aspx';
  static const schoolLeftMenu = 'https://gmis.xupt.edu.cn/pyxx/leftmenu.aspx';
  static const schoolTopBanner = 'https://gmis.xupt.edu.cn/pyxx/topbanner.aspx';
  static const schoolStudentInfo =
      'https://gmis.xupt.edu.cn/pyxx/grgl/xsinfoshow.aspx';
  static const schoolSchedule =
      'https://gmis.xupt.edu.cn/pyxx/pygl/kbcx_xs.aspx';
  static const schoolAppId = '2125472503248718134';

  static const authPolicy = '$authOrigin/esc-sso/api/v3/auth/policy';
  static const authLogin = '$authOrigin/esc-sso/api/v3/auth/doLogin';
  static const authMfaPolicy = '$authOrigin/esc-sso/api/v3/auth/queryAllValid';
  static const authQueryUser = '$authOrigin/esc-sso/api/v3/auth/queryUserValid';
  static const authSmsSend = '$authOrigin/esc-sso/api/v3/sms/send';

  static const methodLabels = <String, String>{
    'webSmsAuth': '手机验证码',
    'webOtpAuth': '动态口令 OTP',
    'webQrCodeAuth': '手机扫码',
    'webWechatMsgAuth': '微信公众号',
    'webWechatMsgAuthTwo': '微信公众号',
    'webWorkWechatMsgAuth': '企业微信',
    'webWorkWechatMsgAuthTwo': '企业微信',
    'webDingdingMsgAuth': '钉钉',
    'webDingdingMsgAuthTwo': '钉钉',
    'webLocalAuth': '账号密码',
  };

  late HttpClient _client;
  final _CookieJar _jar = _CookieJar();
  String _knownStudentId = '';
  String _knownStudentName = '';

  void restore(Map<String, dynamic> payload) => _jar.load(payload);

  Map<String, dynamic> dump() => _jar.dump();

  void rememberStudent(String id, String name) {
    if (id.isNotEmpty) _knownStudentId = id;
    if (name.isNotEmpty) _knownStudentName = name;
  }

  void close() => _client.close(force: true);

  int _ms() => DateTime.now().millisecondsSinceEpoch;

  bool _ok(String? code) {
    final value = (code ?? '').trim();
    return value == '0' || value == 'OK' || value == 'ok' || value == '200';
  }

  Uri _abs(Uri base, String target) =>
      target.startsWith('http') ? Uri.parse(target) : base.resolve(target);

  Map<String, String> _ssoHeaders() {
    final headers = <String, String>{
      'Referer': '$authOrigin/esc-sso/login/page',
      'Origin': authOrigin,
      'Accept-Language': 'zh-CN',
      'language': 'zh-CN',
      'Accept': 'application/json, text/plain, */*',
    };
    final browserId = _jar.valueOf('ssoBrowserId');
    if (browserId != null && browserId.isNotEmpty) {
      headers['browserid'] = browserId;
    }
    return headers;
  }

  Map<String, String> _gmisHeaders([String referer = '']) {
    final headers = <String, String>{
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
    };
    if (referer.isNotEmpty) headers['Referer'] = referer;
    return headers;
  }

  Future<_HttpResult> _request(
    String method,
    Uri uri, {
    Map<String, String> headers = const {},
    Object? body,
    bool followRedirects = false,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
      try {
        return await _requestOnce(
          method,
          uri,
          headers: headers,
          body: body,
          followRedirects: followRedirects,
        );
      } on HttpException catch (err) {
        lastError = err;
      } on SocketException catch (err) {
        lastError = err;
      } on HandshakeException catch (err) {
        lastError = err;
      }
    }
    throw SchoolException(
      '连接学校服务器失败：$lastError\n请检查校园网/VPN 后重试。',
      code: 'network_error',
    );
  }

  Future<_HttpResult> _requestOnce(
    String method,
    Uri uri, {
    Map<String, String> headers = const {},
    Object? body,
    bool followRedirects = false,
  }) async {
    final request = await _client.openUrl(method, uri);
    request.followRedirects = followRedirects;
    request.maxRedirects = 15;
    // School server often drops keep-alive sockets mid-response.
    request.persistentConnection = false;
    headers.forEach((key, value) => request.headers.set(key, value));
    final cookie = _jar.headerFor(uri);
    if (cookie.isNotEmpty) {
      request.headers.set(HttpHeaders.cookieHeader, cookie);
    }
    if (body is String) {
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(body));
    } else if (body is Map) {
      request.headers.contentType =
          ContentType('application', 'x-www-form-urlencoded', charset: 'utf-8');
      request.add(utf8.encode(_form(body)));
    }

    final response = await request.close().timeout(const Duration(seconds: 45));
    _jar.absorb(uri, response.headers[HttpHeaders.setCookieHeader] ?? const []);
    final bytes =
        await response.fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));
    final location = response.headers.value(HttpHeaders.locationHeader);
    return _HttpResult(
      statusCode: response.statusCode,
      headers: response.headers,
      body: utf8.decode(bytes, allowMalformed: true),
      url: uri,
      location: location,
    );
  }

  String _form(Map map) => map.entries
      .map((e) =>
          '${Uri.encodeQueryComponent('${e.key}')}=${Uri.encodeQueryComponent('${e.value}')}')
      .join('&');

  Future<Map<String, dynamic>> _json(_HttpResult response) async {
    if (!response.looksJson) {
      throw SchoolException('服务器返回了非 JSON 响应。', code: 'session_expired');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map) return decoded.cast<String, dynamic>();
    throw SchoolException('无法解析统一认证响应。');
  }

  Future<void> _bootstrap() async {
    final service = Uri.encodeComponent(schoolLogin);
    final entry = Uri.parse('$authOrigin/esc-sso/login?service=$service');
    final response = await _request('GET', entry, headers: _ssoHeaders());
    if (response.isRedirect && (response.location ?? '').isNotEmpty) {
      final next = _abs(response.url, response.location!);
      if (next.host.contains('auth.xupt.edu.cn')) {
        await _request('GET', next, headers: _ssoHeaders());
        return;
      }
    }
    await _request('GET', Uri.parse('$authOrigin/esc-sso/login/page'),
        headers: _ssoHeaders());
  }

  Future<Map<String, dynamic>> _policy() async {
    final response = await _request(
      'GET',
      Uri.parse(authPolicy).replace(queryParameters: {'_': '${_ms()}'}),
      headers: _ssoHeaders(),
    );
    final policy = await _json(response);
    if (!_ok('${policy['code']}') && policy['data'] == null) {
      throw SchoolException(policy['msg']?.toString() ?? '无法获取统一认证策略。');
    }
    return policy;
  }

  Future<Map<String, dynamic>> _doLogin(Map<String, dynamic> body) async {
    final response = await _request(
      'POST',
      Uri.parse(authLogin).replace(queryParameters: {'_': '${_ms()}'}),
      headers: {
        ..._ssoHeaders(),
        'Content-Type': 'application/json;charset=UTF-8',
      },
      body: jsonEncode(body),
    );
    return _json(response);
  }

  Never _failLogin(Map<String, dynamic> payload) {
    final code = '${payload['code'] ?? ''}';
    final message = payload['msg']?.toString() ?? '用户名或密码错误。';
    if (code == 'SSO10023' || code == 'SSO10093') {
      throw SchoolException('学校要求图形验证码，请先在浏览器完成一次登录。',
          code: 'captcha_required');
    }
    if (code == 'SSO10024' || code == 'SSO10094') {
      throw SchoolException('学校要求滑块验证码，请先在浏览器完成一次登录。',
          code: 'captcha_required');
    }
    throw SchoolException(message, code: 'auth_failed');
  }

  bool _isLoginUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('auth.xupt.edu.cn')) {
      return lower.contains('/esc-sso/login') || lower.contains('/oauth');
    }
    if (lower.contains('gmis.xupt.edu.cn')) {
      if (lower.contains('login.aspx') && !lower.contains('logincas.aspx')) {
        return true;
      }
      if (lower.contains('logincas.aspx')) {
        final query = Uri.tryParse(url)?.query.toLowerCase() ?? '';
        return !query.contains('ticket=') && !query.contains('st-');
      }
    }
    return false;
  }

  Future<_HttpResult> _follow(Uri start) async {
    var response = await _request('GET', start, headers: _ssoHeaders());
    for (var hop = 0; hop < 15; hop++) {
      if (response.looksJson) {
        final payload = await _json(response);
        final data = payload['data'];
        var next = '';
        if (data is Map) {
          next = (data['redirect'] ?? data['redirectUrl'] ?? '').toString();
        }
        if (next.isEmpty) next = (payload['redirect'] ?? '').toString();
        if (_ok('${payload['code']}') && next.isNotEmpty) {
          response = await _request('GET', _abs(response.url, next),
              headers: _ssoHeaders());
          continue;
        }
      }
      if (response.isRedirect && (response.location ?? '').isNotEmpty) {
        response = await _request('GET', _abs(response.url, response.location!),
            headers: _ssoHeaders());
        continue;
      }
      break;
    }
    return response;
  }

  Future<void> _enterCas() async {
    _jar.clearGmis();
    final service = Uri.encodeComponent(schoolLogin);
    final response = await _follow(
      Uri.parse('$authOrigin/esc-sso/login?service=$service'),
    );
    if (response.url.host.contains('gmis.xupt.edu.cn')) {
      await _request('GET', Uri.parse(schoolHome), headers: _gmisHeaders());
    }
    if (!_jar.hasGmisSession()) {
      throw SchoolException('登录跳转未完成，学校会话未建立，请重试。',
          code: 'session_expired');
    }
  }

  Future<void> _enterAppForward(String accountNo) async {
    final account = accountNo.trim();
    if (account.isEmpty) {
      throw SchoolException('无法进入教务系统。', code: 'session_expired');
    }
    _jar.clearGmis();
    final response = await _follow(Uri.parse(
      '$authOrigin/esc-sso/app/forward?ssoType=regex&appId=${Uri.encodeComponent(schoolAppId)}&accountNo=${Uri.encodeComponent(account)}',
    ));
    if (response.url.host.contains('gmis.xupt.edu.cn')) {
      await _request('GET', Uri.parse(schoolHome),
          headers: _gmisHeaders(response.url.toString()));
    }
    if (!_jar.hasGmisSession()) {
      throw SchoolException('应用跳转未完成，学校会话未建立，请重试。',
          code: 'session_expired');
    }
  }

  Future<void> _enterSchool(String accountNo) async {
    final errors = <String>[];
    try {
      await _enterCas();
      return;
    } catch (err) {
      errors.add('$err');
    }
    try {
      await _enterAppForward(accountNo);
      return;
    } catch (err) {
      errors.add('$err');
    }
    throw SchoolException(errors.join('；'), code: 'session_expired');
  }

  bool _broken(String redirect) {
    final text = redirect.trim();
    return text.isEmpty || text.endsWith('code=');
  }

  bool _mfaRedirect(String redirect) {
    final text = redirect.toLowerCase();
    return text.contains('mfalogin') || text.contains('/login/mfa');
  }

  List<AuthMethod> _extractMethods(Map<String, dynamic> payload) {
    final data = payload['data'];
    final candidates = <dynamic>[];
    if (data is Map) {
      for (final key in [
        'authMethods',
        'authTypeList',
        'authTypes',
        'methods',
        'validAuthTypes',
        'secondAuthTypes',
        'loginAuthTypes',
      ]) {
        final value = data[key];
        if (value is List) {
          candidates.addAll(value);
          break;
        }
      }
      if (candidates.isEmpty) {
        data.forEach((key, value) {
          if (key is String &&
              key.endsWith('Auth') &&
              value != null &&
              value != false &&
              value != 0 &&
              value != '0') {
            candidates.add(key);
          }
        });
      }
    } else if (data is List) {
      candidates.addAll(data);
    }

    final methods = <AuthMethod>[];
    final seen = <String>{};
    for (final item in candidates) {
      var authType = '';
      if (item is String) {
        authType = item;
      } else if (item is Map) {
        authType = (item['authType'] ??
                item['type'] ??
                item['code'] ??
                item['name'] ??
                '')
            .toString();
      }
      if (authType.isEmpty || !seen.add(authType)) continue;
      methods.add(AuthMethod(
        authType: authType,
        label: methodLabels[authType] ?? authType,
      ));
    }
    if (methods.isEmpty) {
      methods.add(const AuthMethod(authType: 'webSmsAuth', label: '手机验证码'));
    }
    return methods;
  }

  Future<List<AuthMethod>> _queryMethods() async {
    final response = await _request(
      'GET',
      Uri.parse(authMfaPolicy).replace(queryParameters: {'_': '${_ms()}'}),
      headers: _ssoHeaders(),
    );
    return _extractMethods(await _json(response));
  }

  Future<void> sendMfaSms(String username) async {
    final user = username.trim();
    if (user.isEmpty) {
      throw SchoolException('缺少用户名，无法发送短信验证码。', code: 'mfa_failed');
    }
    final check = await _request(
      'GET',
      Uri.parse(authQueryUser).replace(queryParameters: {
        'username': user,
        'authType': 'webSmsAuth',
        '_': '${_ms()}',
      }),
      headers: _ssoHeaders(),
    );
    final checkPayload = await _json(check);
    if (!_ok('${checkPayload['code']}')) {
      throw SchoolException(
        checkPayload['msg']?.toString() ?? '当前账号无法使用短信二次认证。',
        code: 'mfa_failed',
      );
    }
    final response = await _request(
      'GET',
      Uri.parse(authSmsSend).replace(queryParameters: {
        'username': user,
        '_': '${_ms()}',
      }),
      headers: _ssoHeaders(),
    );
    final payload = await _json(response);
    if (!_ok('${payload['code']}')) {
      throw SchoolException(payload['msg']?.toString() ?? '短信验证码发送失败。',
          code: 'mfa_failed');
    }
  }

  Future<void> _completeSso(Map<String, dynamic> payload,
      {required String username}) async {
    final data = (payload['data'] is Map)
        ? (payload['data'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    var redirect = (data['redirect'] ?? data['redirectUrl'] ?? '').toString();
    final authCode = (data['code'] ?? '').toString();
    if (redirect.endsWith('code=') && authCode.isNotEmpty) {
      redirect = '$redirect$authCode';
    }

    if (_mfaRedirect(redirect)) {
      await _request('GET', _abs(Uri.parse(authOrigin), redirect),
          headers: _ssoHeaders());
      throw MfaRequiredException(
        username: username.trim(),
        methods: await _queryMethods(),
        message: '检测到异常登录风险，请完成二次认证后继续。',
      );
    }

    if (_broken(redirect)) {
      await _enterSchool(username);
      return;
    }

    if (redirect.isNotEmpty) {
      try {
        final chain = await _follow(_abs(Uri.parse(authOrigin), redirect));
        if (!_jar.hasGmisSession() &&
            chain.url.host.contains('gmis.xupt.edu.cn')) {
          await _request('GET', Uri.parse(schoolHome),
              headers: _gmisHeaders(chain.url.toString()));
        }
      } catch (_) {
        await _enterSchool(username);
      }
      if (!_jar.hasGmisSession()) await _enterSchool(username);
      return;
    }

    final ticket = data['code'];
    final authType = data['authType'];
    if (ticket != null && authType != null) {
      final ticketPayload = await _doLogin({
        'authType': authType,
        'dataField': {'ticket': ticket.toString()},
        'redirectUri': schoolLogin,
      });
      if (!_ok('${ticketPayload['code']}')) _failLogin(ticketPayload);
      final ticketData = (ticketPayload['data'] is Map)
          ? (ticketPayload['data'] as Map).cast<String, dynamic>()
          : <String, dynamic>{};
      final next =
          (ticketData['redirect'] ?? ticketData['redirectUrl'] ?? '').toString();
      if (_mfaRedirect(next)) {
        await _request('GET', _abs(Uri.parse(authOrigin), next),
            headers: _ssoHeaders());
        throw MfaRequiredException(
          username: username.trim(),
          methods: await _queryMethods(),
          message: '检测到异常登录风险，请完成二次认证后继续。',
        );
      }
      if (_broken(next)) {
        await _enterSchool(username);
        return;
      }
      if (next.isEmpty) {
        throw SchoolException('登录票据交换成功，但未返回跳转地址。',
            code: 'auth_failed');
      }
      try {
        await _follow(_abs(Uri.parse(authOrigin), next));
      } catch (_) {
        await _enterSchool(username);
      }
      return;
    }

    await _enterSchool(username);
  }

  String? _studentIdFromHtml(String html) {
    final text = html.replaceAll('&amp;', '&');
    final q =
        RegExp(r'[?&]xh=(\d{6,20})', caseSensitive: false).firstMatch(text);
    if (q != null) return q.group(1);
    final s = RegExp(r'\bxh["' "'" r']?\s*[:=]\s*["' "'" r']?(\d{6,20})',
            caseSensitive: false)
        .firstMatch(text);
    return s?.group(1);
  }

  String _cleanName(String value) {
    var name =
        value.replaceAll('\xa0', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    name = name.replaceAll(RegExp(r'^[()（）\[\]【】]+|[()（）\[\]【】]+$'), '');
    if (name.isEmpty || RegExp(r'^\d+$').hasMatch(name)) return '';
    const banned = {'同学', '老师', '管理员', '姓名', '学生姓名'};
    if (banned.contains(name)) return '';
    if (!RegExp(r'^[一-龥·A-Za-z]{2,20}$').hasMatch(name)) return '';
    return name;
  }

  String _nameFromHtml(String html) {
    final text = html.replaceAll('&nbsp;', ' ').replaceAll('&amp;', '&');
    final preferred = RegExp(
      r'id=["' "'" r']lblxm1["' "'" r'][^>]*>\s*([^<]+?)\s*</span>',
      caseSensitive: false,
    ).firstMatch(text);
    if (preferred != null) {
      final name = _cleanName(preferred.group(1) ?? '');
      if (name.isNotEmpty) return name;
    }
    for (final pattern in [
      r'姓名[：:]\s*([^\s<>&，,。；;]{2,20})',
      r'欢迎您[：:]\s*([^\s<>&，,。；;]{2,20})',
    ]) {
      final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
      if (match != null) {
        final name = _cleanName(match.group(1) ?? '');
        if (name.isNotEmpty) return name;
      }
    }
    return '';
  }

  Future<String> _resolveName(String studentId) async {
    final pages = <String>[
      if (studentId.trim().isNotEmpty)
        '$schoolStudentInfo?tab=1&xh=${studentId.trim()}',
      schoolTopBanner,
      schoolLeftMenu,
      schoolHome,
    ];
    for (final url in pages) {
      try {
        final response = await _request('GET', Uri.parse(url),
            headers: _gmisHeaders(schoolHome));
        if (_isLoginUrl(response.url.toString())) continue;
        final name = _nameFromHtml(response.body);
        if (name.isNotEmpty) return name;
      } catch (_) {}
    }
    return '';
  }

  Future<String> _resolveStudentId(String loginUsername) async {
    if (_knownStudentId.isNotEmpty) return _knownStudentId;

    final home =
        await _request('GET', Uri.parse(schoolHome), headers: _gmisHeaders());
    var studentId = _studentIdFromHtml(home.body);
    if (studentId != null) {
      _knownStudentId = studentId;
      return studentId;
    }

    final left = await _request('GET', Uri.parse(schoolLeftMenu),
        headers: _gmisHeaders(schoolHome));
    if (!_isLoginUrl(left.url.toString())) {
      studentId = _studentIdFromHtml(left.body);
      if (studentId != null) {
        _knownStudentId = studentId;
        return studentId;
      }
    }

    final username = loginUsername.trim();
    if (RegExp(r'^\d{6,20}$').hasMatch(username)) {
      // Login username is often the student id; try schedule page directly.
      try {
        final probe = await _request(
          'GET',
          Uri.parse('$schoolSchedule?xh=$username'),
          headers: _gmisHeaders(schoolHome),
        );
        if (probe.body.contains('MainWork_DataGrid1') &&
            !_isLoginUrl(probe.url.toString())) {
          _knownStudentId = username;
          return username;
        }
      } catch (_) {}
    }
    if (_isLoginUrl(left.url.toString()) || _isLoginUrl(home.url.toString())) {
      throw SchoolException('学校登录状态已失效，请重新登录。',
          code: 'session_expired');
    }
    return '';
  }

  Future<LoginResult> _finish(String username) async {
    final studentId = await _resolveStudentId(username);
    if (studentId.isEmpty) {
      throw SchoolException('登录成功，但未能识别学号，请稍后重试。',
          code: 'student_missing');
    }
    final name = await _resolveName(studentId);
    _knownStudentId = studentId;
    _knownStudentName = name;
    return LoginResult(studentId: studentId, studentName: name);
  }

  Future<LoginResult> login(String username, String password) async {
    await _bootstrap();
    final policy = await _policy();
    final data = (policy['data'] is Map)
        ? (policy['data'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final param = (data['param'] is Map)
        ? (data['param'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final publicKey = param['publicKey']?.toString() ?? '';
    final publicKeyId = param['publicKeyId']?.toString() ?? '';
    if (publicKey.isEmpty || publicKeyId.isEmpty) {
      throw SchoolException('统一认证未返回 RSA 公钥，无法登录。');
    }

    final payload = await _doLogin({
      'authType': 'webLocalAuth',
      'redirectUri': schoolLogin,
      'dataField': {
        'username': username.trim(),
        'password': rsaEncryptPassword(password, publicKey),
        'publicKeyId': publicKeyId,
      },
    });
    if (!_ok('${payload['code']}')) _failLogin(payload);
    await _completeSso(payload, username: username.trim());
    return _finish(username);
  }

  Future<LoginResult> completeMfaSms(String username, String smsCode) async {
    final user = username.trim();
    final code = smsCode.trim();
    if (user.isEmpty || code.isEmpty) {
      throw SchoolException('请输入短信验证码。', code: 'mfa_failed');
    }
    final payload = await _doLogin({
      'authType': 'webSmsAuth',
      'redirectUri': schoolLogin,
      'dataField': {'username': user, 'smsCode': code},
    });
    if (!_ok('${payload['code']}')) {
      throw SchoolException(payload['msg']?.toString() ?? '二次认证失败，请检查验证码。',
          code: 'mfa_failed');
    }
    try {
      await _completeSso(payload, username: user);
    } on MfaRequiredException {
      throw SchoolException('二次认证后仍需额外验证，请稍后重试。', code: 'mfa_failed');
    }
    if (!_jar.hasGmisSession()) await _enterSchool(user);
    return _finish(user);
  }

  Future<ScheduleData> fetchSchedule({
    String termCode = '',
    String studentIdHint = '',
  }) async {
    final studentId = await _resolveStudentId(studentIdHint);
    if (studentId.isEmpty) {
      throw SchoolException('无法识别当前账号学号。', code: 'student_missing');
    }

    // Warm up session on home page — school gateway sometimes resets
    // the first request after long idle.
    try {
      await _request('GET', Uri.parse(schoolHome), headers: _gmisHeaders());
    } catch (_) {}

    final scheduleUrl = '$schoolSchedule?xh=$studentId';
    Object? lastError;
    String html = '';
    var ok = false;
    for (var attempt = 0; attempt < 3 && !ok; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 600 * attempt));
        // Fresh client helps when the old socket was half-closed.
        _client.close(force: true);
        _client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 30)
          ..idleTimeout = const Duration(seconds: 30)
          ..userAgent =
              'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36';
      }
      try {
        final response = await _request(
          'GET',
          Uri.parse(scheduleUrl),
          headers: {
            ..._gmisHeaders(schoolHome),
            'Connection': 'close',
          },
        );
        if (_isLoginUrl(response.url.toString())) {
          throw SchoolException('学校登录状态已失效，请重新登录。',
              code: 'session_expired');
        }
        if (!response.body.contains('MainWork_DataGrid1')) {
          lastError = '页面无课表数据';
          continue;
        }
        html = response.body;
        ok = true;
      } on SchoolException {
        rethrow;
      } catch (err) {
        lastError = err;
      }
    }
    if (!ok) {
      throw SchoolException(
        '拉取课表失败：$lastError\n请检查校园网后点刷新重试。',
        code: 'network_error',
      );
    }

    if (termCode.isNotEmpty &&
        RegExp(r'^[A-Za-z0-9_-]{1,40}$').hasMatch(termCode)) {
      html = await _switchTerm(html, termCode, scheduleUrl);
      if (!html.contains('MainWork_DataGrid1')) {
        throw SchoolException('切换学期失败，请刷新当前学期。',
            code: 'term_switch_failed');
      }
    }

    final data = parseScheduleHtml(html);
    data.studentId = data.studentId.isEmpty ? studentId : data.studentId;
    if (data.studentName.isEmpty && _knownStudentName.isNotEmpty) {
      data.studentName = _knownStudentName;
    }
    if (data.studentName.isEmpty) {
      data.studentName = await _resolveName(studentId);
    }
    _knownStudentId = data.studentId;
    if (data.studentName.isNotEmpty) _knownStudentName = data.studentName;
    return data;
  }

  Future<String> _switchTerm(
      String html, String termCode, String scheduleUrl) async {
    final state = extractWebformsState(html);
    final selected = state.selectedTerm;
    if (selected != null && selected.code == termCode) return html;
    if (!state.terms.any((item) => item.code == termCode)) return html;

    final name = state.termSelectName.isEmpty
        ? 'ctl00\$MainWork\$drpxq'
        : state.termSelectName;
    final body = <String, String>{...state.hidden};
    body['__EVENTTARGET'] = name;
    body['__EVENTARGUMENT'] = '';
    body[name] = termCode;
    final switched = await _request(
      'POST',
      Uri.parse(scheduleUrl),
      headers: {
        ..._gmisHeaders(scheduleUrl),
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );
    return switched.body;
  }
}
