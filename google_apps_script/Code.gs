var SHEET_ID = "YOUR_GOOGLE_SHEET_ID_HERE"; // Replace with your Sheet ID

// users columns: A=name, B=password, C=role, D=number, E=must_change

function doPost(e) {
  var data = JSON.parse(e.postData.contents);
  var action = data.action;

  if (action === "login")          return login(data);
  if (action === "parkVehicle")    return parkVehicle(data);
  if (action === "getTodayLogs")   return getTodayLogs();
  if (action === "getDashboard")   return getDashboard();
  if (action === "assignNumber")   return assignNumber(data);
  if (action === "resetPassword")  return resetPassword(data);
  if (action === "changePassword") return changePassword(data);

  return respond({ success: false, message: "Unknown action" });
}

// ── HASH HELPER ────────────────────────────────────────
function sha256(text) {
  var bytes = Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256, text, Utilities.Charset.UTF_8);
  return bytes.map(function(b) {
    return ('0' + (b & 0xFF).toString(16)).slice(-2);
  }).join('');
}

// ── LOGIN ──────────────────────────────────────────────
// Employees login with their code (number column D)
// Admin logs in with name (column A) as code
function login(data) {
  var sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName("users");
  var rows  = sheet.getDataRange().getValues();

  var inputCode = data.code.toString().trim();
  var inputPass = data.password.toString().trim();

  for (var i = 1; i < rows.length; i++) {
    var name       = rows[i][0].toString().trim();
    var storedHash = rows[i][1].toString().trim();
    var role       = rows[i][2].toString().trim();
    var empCode    = rows[i][3].toString().trim(); // column D = number/code
    var mustChange = rows[i][4].toString().trim().toUpperCase(); // column E

    // Match by employee code (column D) for employees
    // Match by name (column A) for admin (admin has no number)
    var codeMatch = (empCode !== "" && empCode === inputCode) ||
                    (role === "admin" && name.toLowerCase() === inputCode.toLowerCase());

    if (codeMatch && storedHash === inputPass) {
      return respond({
        success:     true,
        name:        name,
        role:        role,
        must_change: mustChange === "TRUE"
      });
    }
  }
  return respond({ success: false, message: "Invalid code or password" });
}

// ── PARK VEHICLE ───────────────────────────────────────
function parkVehicle(data) {
  var sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName("parking_log");

  var now       = new Date();
  var timestamp = Utilities.formatDate(now, Session.getScriptTimeZone(), "yyyy-MM-dd HH:mm:ss");
  var date      = Utilities.formatDate(now, Session.getScriptTimeZone(), "yyyy-MM-dd");

  sheet.appendRow([data.user_name, data.vehicle_no, timestamp, date]);
  return respond({ success: true, message: "Vehicle parked successfully" });
}

// ── GET TODAY LOGS (Admin) ─────────────────────────────
function getTodayLogs() {
  var sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName("parking_log");
  var rows  = sheet.getDataRange().getValues();

  var now   = new Date();
  var today = Utilities.formatDate(now, Session.getScriptTimeZone(), "yyyy-MM-dd");

  var logs = [];
  for (var i = 1; i < rows.length; i++) {
    if (rows[i][3].toString() === today) {
      logs.push({ user_name: rows[i][0], vehicle_no: rows[i][1], timestamp: rows[i][2] });
    }
  }
  return respond({ success: true, count: logs.length, logs: logs });
}

// ── ASSIGN NUMBER TO EMPLOYEE (Admin) ─────────────────
function assignNumber(data) {
  var sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName("users");
  var rows  = sheet.getDataRange().getValues();

  for (var i = 1; i < rows.length; i++) {
    if (rows[i][0].toString().trim() === data.name.trim()) {
      sheet.getRange(i + 1, 4).setValue(data.number); // column D
      return respond({ success: true, message: "Number assigned" });
    }
  }
  return respond({ success: false, message: "Employee not found" });
}

// ── CHANGE PASSWORD (Employee self — verifies old password) ──
function changePassword(data) {
  var sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName("users");
  var rows  = sheet.getDataRange().getValues();

  for (var i = 1; i < rows.length; i++) {
    var name       = rows[i][0].toString().trim();
    var storedHash = rows[i][1].toString().trim();

    if (name === data.name.trim()) {
      if (storedHash !== data.old_password.trim()) {
        return respond({ success: false, message: "Current password is incorrect" });
      }
      sheet.getRange(i + 1, 2).setValue(data.new_password); // update password
      sheet.getRange(i + 1, 5).setValue("FALSE");           // clear must_change flag
      return respond({ success: true, message: "Password changed successfully" });
    }
  }
  return respond({ success: false, message: "User not found" });
}

// ── RESET PASSWORD (Admin — sets must_change = TRUE) ──
function resetPassword(data) {
  var sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName("users");
  var rows  = sheet.getDataRange().getValues();

  for (var i = 1; i < rows.length; i++) {
    if (rows[i][0].toString().trim() === data.name.trim()) {
      sheet.getRange(i + 1, 2).setValue(data.new_password); // update password
      sheet.getRange(i + 1, 5).setValue("TRUE");            // force change on next login
      return respond({ success: true, message: "Password reset. Employee must change on next login." });
    }
  }
  return respond({ success: false, message: "Employee not found" });
}

// ── DASHBOARD (Admin) ─────────────────────────────────
function getDashboard() {
  var ss          = SpreadsheetApp.openById(SHEET_ID);
  var usersSheet  = ss.getSheetByName("users");
  var logSheet    = ss.getSheetByName("parking_log");

  var now   = new Date();
  var today = Utilities.formatDate(now, Session.getScriptTimeZone(), "yyyy-MM-dd");

  var userRows  = usersSheet.getDataRange().getValues();
  var employees = [];
  for (var i = 1; i < userRows.length; i++) {
    if (userRows[i][2].toString().trim() === "employee") {
      employees.push({
        name:   userRows[i][0].toString().trim(),
        number: userRows[i][3] ? userRows[i][3].toString().trim() : ""
      });
    }
  }

  var logRows   = logSheet.getDataRange().getValues();
  var parkedMap = {};
  for (var j = 1; j < logRows.length; j++) {
    if (logRows[j][3].toString() === today) {
      var empName = logRows[j][0].toString().trim();
      parkedMap[empName] = {
        vehicle_no: logRows[j][1],
        timestamp:  logRows[j][2].toString().substring(11, 16)
      };
    }
  }

  var parked = [], notParked = [];
  for (var k = 0; k < employees.length; k++) {
    var emp = employees[k];
    if (parkedMap[emp.name]) {
      parked.push({ name: emp.name, number: emp.number, vehicle_no: parkedMap[emp.name].vehicle_no, time: parkedMap[emp.name].timestamp });
    } else {
      notParked.push({ name: emp.name, number: emp.number });
    }
  }

  return respond({
    success: true, total: employees.length,
    parked_count: parked.length, not_parked_count: notParked.length,
    parked: parked, not_parked: notParked
  });
}

// ── HELPER ─────────────────────────────────────────────
function respond(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
