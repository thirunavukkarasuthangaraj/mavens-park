var SHEET_ID = "1liGAr2mp1_89fTJoW3_7U8rEyNTHw-PiyZw6glmRX18";

// ── Single sheet: "employees" ───────────────────────────
// Columns: A=emp_code, B=name, C=email, D=password, E=role, F=number, G=must_change
// parking_log sheet: A=emp_code, B=name, C=vehicle_no, D=timestamp, E=date

// doGet handles CORS for Flutter Web/Chrome
function doGet(e) {
  var data = JSON.parse(decodeURIComponent(e.parameter.data || '{}'));
  return handleRequest(data);
}

function doPost(e) {
  var data = JSON.parse(e.postData.contents);
  return handleRequest(data);
}

function handleRequest(data) {
  var action = data.action;
  if (action === "login")          return login(data);
  if (action === "parkVehicle")    return parkVehicle(data);
  if (action === "getDashboard")   return getDashboard(data);
  if (action === "assignNumber")   return assignNumber(data);
  if (action === "resetPassword")  return resetPassword(data);
  if (action === "changePassword") return changePassword(data);
  return respond({ success: false, message: "Unknown action" });
}


// ── SHA-256 hash ────────────────────────────────────────
function sha256(text) {
  var bytes = Utilities.computeDigest(
    Utilities.DigestAlgorithm.SHA_256, text, Utilities.Charset.UTF_8);
  return bytes.map(function(b) {
    return ('0' + (b & 0xFF).toString(16)).slice(-2);
  }).join('');
}

// ── LOGIN ───────────────────────────────────────────────
// employees columns: A=emp_code, B=name, C=email, D=password, E=role, F=number, G=must_change
function login(data) {
  var sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName("employees");
  var rows  = sheet.getDataRange().getValues();
  var inputCode = data.code.toString().trim();
  var inputPass = data.password.toString().trim();

  for (var i = 1; i < rows.length; i++) {
    var empCode    = rows[i][0].toString().trim(); // A
    var name       = rows[i][1].toString().trim(); // B
    var email      = rows[i][2].toString().trim(); // C
    var storedHash = rows[i][3].toString().trim(); // D
    var role       = rows[i][4].toString().trim(); // E
    var number     = rows[i][5].toString().trim(); // F
    var mustChange = rows[i][6].toString().trim().toUpperCase(); // G

    // Match by emp_code for employees, or by name for admin (no code)
    var match = empCode === inputCode ||
                (role === "admin" && name.toLowerCase() === inputCode.toLowerCase());

    if (match && storedHash === inputPass) {
      return respond({
        success:     true,
        emp_code:    empCode,
        name:        name,
        email:       email,
        role:        role,
        number:      number,
        must_change: mustChange === "TRUE"
      });
    }
  }
  return respond({ success: false, message: "Invalid code or password" });
}

// ── PARK VEHICLE ────────────────────────────────────────
function parkVehicle(data) {
  var sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName("parking_log");
  var now       = new Date();
  var timestamp = Utilities.formatDate(now, Session.getScriptTimeZone(), "yyyy-MM-dd HH:mm:ss");
  var date      = Utilities.formatDate(now, Session.getScriptTimeZone(), "yyyy-MM-dd");
  sheet.appendRow([data.emp_code, data.user_name, data.vehicle_no, timestamp, date]);
  return respond({ success: true, message: "Vehicle parked successfully" });
}

// ── DASHBOARD (Admin) ───────────────────────────────────
// data.date = "yyyy-MM-dd" (optional, defaults to today)
function getDashboard() {
  var data = arguments[0] || {};
  var ss        = SpreadsheetApp.openById(SHEET_ID);
  var empSheet  = ss.getSheetByName("employees");
  var logSheet  = ss.getSheetByName("parking_log");
  var now       = new Date();
  var today     = data.date
    ? data.date.toString().trim()
    : Utilities.formatDate(now, Session.getScriptTimeZone(), "yyyy-MM-dd");

  // All employees (role = employee)
  var empRows   = empSheet.getDataRange().getValues();
  var employees = [];
  for (var i = 1; i < empRows.length; i++) {
    if (empRows[i][4].toString().trim() === "employee") {
      employees.push({
        emp_code: empRows[i][0].toString().trim(),
        name:     empRows[i][1].toString().trim(),
        email:    empRows[i][2].toString().trim(),
        number:   empRows[i][5] ? empRows[i][5].toString().trim() : ""
      });
    }
  }

  // Today's parking logs
  var logRows   = logSheet.getDataRange().getValues();
  var parkedMap = {}; // emp_code -> { vehicle_no, time }
  for (var j = 1; j < logRows.length; j++) {
    if (logRows[j][4].toString() === today) {
      var code = logRows[j][0].toString().trim();
      parkedMap[code] = {
        vehicle_no: logRows[j][2],
        time:       logRows[j][3].toString().substring(11, 16)
      };
    }
  }

  var parked = [], notParked = [];
  for (var k = 0; k < employees.length; k++) {
    var emp = employees[k];
    if (parkedMap[emp.emp_code]) {
      parked.push({
        emp_code:   emp.emp_code,
        name:       emp.name,
        email:      emp.email,
        number:     emp.number,
        vehicle_no: parkedMap[emp.emp_code].vehicle_no,
        time:       parkedMap[emp.emp_code].time
      });
    } else {
      notParked.push({
        emp_code: emp.emp_code,
        name:     emp.name,
        email:    emp.email,
        number:   emp.number
      });
    }
  }

  return respond({
    success: true,
    date:             today,
    total:            employees.length,
    parked_count:     parked.length,
    not_parked_count: notParked.length,
    parked:           parked,
    not_parked:       notParked
  });
}

// ── ASSIGN NUMBER ───────────────────────────────────────
function assignNumber(data) {
  var sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName("employees");
  var rows  = sheet.getDataRange().getValues();
  for (var i = 1; i < rows.length; i++) {
    if (rows[i][0].toString().trim() === data.emp_code.trim()) {
      sheet.getRange(i + 1, 6).setValue(data.number); // column F
      return respond({ success: true, message: "Number assigned" });
    }
  }
  return respond({ success: false, message: "Employee not found" });
}

// ── CHANGE PASSWORD (employee self) ─────────────────────
function changePassword(data) {
  var sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName("employees");
  var rows  = sheet.getDataRange().getValues();
  for (var i = 1; i < rows.length; i++) {
    if (rows[i][1].toString().trim() === data.name.trim()) {
      if (rows[i][3].toString().trim() !== data.old_password.trim()) {
        return respond({ success: false, message: "Current password is incorrect" });
      }
      sheet.getRange(i + 1, 4).setValue(data.new_password); // column D
      sheet.getRange(i + 1, 7).setValue("FALSE");           // column G
      return respond({ success: true, message: "Password changed successfully" });
    }
  }
  return respond({ success: false, message: "User not found" });
}

// ── RESET PASSWORD (admin — sets must_change = TRUE) ────
function resetPassword(data) {
  var sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName("employees");
  var rows  = sheet.getDataRange().getValues();
  for (var i = 1; i < rows.length; i++) {
    if (rows[i][1].toString().trim() === data.name.trim()) {
      sheet.getRange(i + 1, 4).setValue(data.new_password); // column D
      sheet.getRange(i + 1, 7).setValue("TRUE");            // column G
      return respond({ success: true, message: "Password reset. Employee must change on next login." });
    }
  }
  return respond({ success: false, message: "Employee not found" });
}

// ── HELPER ──────────────────────────────────────────────
function respond(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
