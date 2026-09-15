// File: AuthService.gs

var AuthService = (function() {
  
  function login(params) {
    var idToken = params.idToken;
    if (!idToken) throwError('MISSING_TOKEN', 'Không tìm thấy idToken trong request.');
    
    // Gọi API của Google để verify token thật
    var verifyUrl = 'https://oauth2.googleapis.com/tokeninfo?id_token=' + idToken;
    var email = null;
    try {
      var response = UrlFetchApp.fetch(verifyUrl);
      var tokenInfo = JSON.parse(response.getContentText());
      email = tokenInfo.email;
    } catch (e) {
      throwError('INVALID_TOKEN', 'Token đăng nhập Google không hợp lệ hoặc đã hết hạn.');
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
    
    return {
      token: sessionToken,
      user: matchedUser
    };
  }

  return {
    login: login
  };
})();
