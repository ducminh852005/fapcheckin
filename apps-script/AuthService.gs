// File: AuthService.gs

// Shared OAuth Web client for the HTML UI and backend audience validation.
var GOOGLE_WEB_CLIENT_ID = '222111384223-rk24tqqmdp7bof592plvogk5u2ng2ci0.apps.googleusercontent.com';
var GOOGLE_DESKTOP_CLIENT_ID = '222111384223-bpv1gtbt3kqs8401b6ethio1gi69ahl1.apps.googleusercontent.com';
var GOOGLE_ALLOWED_CLIENT_IDS = [GOOGLE_WEB_CLIENT_ID, GOOGLE_DESKTOP_CLIENT_ID];

var AuthService = (function() {
  
  function login(params) {
    var idToken = params.idToken;
    if (!idToken) throwError('MISSING_TOKEN', 'Không tìm thấy idToken trong request.');
    
    // Gọi API của Google để verify token thật
    var verifyUrl = 'https://oauth2.googleapis.com/tokeninfo?id_token=' + encodeURIComponent(idToken);
    var email = null;
    try {
      var response = UrlFetchApp.fetch(verifyUrl);
      var tokenInfo = JSON.parse(response.getContentText());
      email = tokenInfo.email;
    } catch (e) {
      throwError('INVALID_TOKEN', 'Token đăng nhập Google không hợp lệ hoặc đã hết hạn.');
    }
    
    if (GOOGLE_ALLOWED_CLIENT_IDS.indexOf(tokenInfo.aud) === -1) {
      throwError(
        'INVALID_AUDIENCE',
        'Token Google không được cấp cho ứng dụng này. Audience nhận được: ' +
          String(tokenInfo.aud || '(trống)')
      );
    }

    if (tokenInfo.email_verified !== true && tokenInfo.email_verified !== 'true') {
      throwError('INVALID_TOKEN', 'Email Google chưa được xác minh.');
    }

    if (params.requireLoginNonce) {
      var nonce = tokenInfo.nonce;
      var nonceCache = CacheService.getScriptCache();
      var nonceKey = nonce ? 'google-login-nonce:' + nonce : '';
      if (!nonceKey || !nonceCache.get(nonceKey)) {
        throwError(
          'INVALID_TOKEN',
          'Yêu cầu đăng nhập Google đã hết hạn hoặc không hợp lệ.'
        );
      }
      nonceCache.remove(nonceKey);
    }

    if (!email) {
      throwError('INVALID_TOKEN', 'Không trích xuất được email từ token.');
    }
    
    // Tìm user trong sheet Users
    var users = SheetDB.getRowsAsObjects('Users');
    var matchedUser = null;
    
    for (var i = 0; i < users.length; i++) {
      if (users[i].email === email) {
        matchedUser = users[i];
        break;
      }
    }
    
    if (!matchedUser) {
      throwError('DOMAIN_NOT_ALLOWED', 'Tài khoản không thuộc hệ thống nhà trường hoặc chưa được phân quyền: ' + email);
    }
    
    // Tạo session token nội bộ cho user
    var sessionToken = Utilities.getUuid();
    CacheService.getScriptCache().put('auth:' + sessionToken, String(matchedUser.memberCode), 21600);
    
    return {
      token: sessionToken,
      user: matchedUser
    };
  }

  function requireTeacher(params) {
    var token = params && params.sessionToken;
    var memberCode = token && CacheService.getScriptCache().get('auth:' + token);
    if (!memberCode) throwError('UNAUTHORIZED', 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
    var user = SheetDB.getRowsAsObjects('Users').filter(function(u) {
      return String(u.memberCode) === memberCode;
    })[0];
    var role = user ? String(user.role).trim().toUpperCase() : '';
    if (['GV', 'TEACHER', 'GIANG_VIEN', 'GIẢNG VIÊN'].indexOf(role) === -1) {
      throwError('FORBIDDEN', 'Tài khoản không có quyền giảng viên.');
    }
    return user;
  }

  return {
    login: login,
    requireTeacher: requireTeacher
  };
})();
