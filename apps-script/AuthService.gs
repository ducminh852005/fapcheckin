// File: AuthService.gs

var AuthService = (function() {
  
  function login(params) {
    var idToken = params.idToken;
    if (!idToken) throwError('MISSING_TOKEN', 'Không tìm thấy idToken trong request.');
    
    // Tạm thời mock việc verify token: 
    // Coi idToken như là email của user gửi lên để dev nhanh.
    // Thực tế sẽ cần gọi API Google hoặc thư viện để decode và verify: https://oauth2.googleapis.com/tokeninfo?id_token=...
    var email = idToken; // MOCK
    
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
      throwError('DOMAIN_NOT_ALLOWED', 'Tài khoản không thuộc hệ thống nhà trường hoặc chưa được cấp phép.');
    }
    
    // Tạo session token giả lập cho user (Thực tế nên mã hoá JWT)
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
