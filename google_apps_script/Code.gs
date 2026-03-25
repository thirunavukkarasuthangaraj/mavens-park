var SHEET_ID = "YOUR_GOOGLE_SHEET_ID_HERE"; // Replace with your Sheet ID

function doPost(e) {
  var data = JSON.parse(e.postData.contents);
  var action = data.action;

  if (action === "login") return login(data);
  if (action === "parkVehicle") return parkVehicle(data);
  if (action === "getTodayLogs") return getTodayLogs();
  if (action === "getDashboard") return getDashboard();
  if (action === "assignNumber") return assignNumber(data);
  if (action === "resetPassword") return resetPassword(data);

  return respond({ success: false, message: "Unknown action" });
}

// ── HASH HELPER ────────────────────────────────────────
function sha256(text) {
  var bytes  = Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256, text, Utilities.Charset.UTF_8);
  return bytes.map(function(b) {
    return ('0' + (b & 0xFF).toString(16)).slice(-2);
  }).join('');
}

// ── LOGIN ──────────────────────────────────────────────
function login(data) {
  var sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName("users");
  var rows  = sheet.getDataRange().getValues();

  // data.password is already SHA-256 hashed from Flutter
  for (var i = 1; i < rows.length; i++) {
    var name         = rows[i][0].toString().trim();
    var storedHash   = rows[i][1].toString().trim();
    var role         = rows[i][2].toString().trim();

    if (name === data.name.trim() && storedHash === data.password.trim()) {
      return respond({ success: true, name: name, role: role });
    }
  }
  return respond({ success: false, message: "Invalid name or password" });
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
      logs.push({
        user_name:  rows[i][0],
        vehicle_no: rows[i][1],
        timestamp:  rows[i][2]
      });
    }
  }

  return respond({ success: true, count: logs.length, logs: logs });
}

// ── ASSIGN NUMBER TO EMPLOYEE (Admin) ─────────────────
function assignNumber(data) {
  var sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName("users");
  var rows  = sheet.getDataRange().getValues();

  // users columns: 0=name, 1=password, 2=role, 3=number
  for (var i = 1; i < rows.length; i++) {
    if (rows[i][0].toString().trim() === data.name.trim()) {
      sheet.getRange(i + 1, 4).setValue(data.number); // column D = number
      return respond({ success: true, message: "Number assigned" });
    }
  }
  return respond({ success: false, message: "Employee not found" });
}

// ── RESET PASSWORD (Admin) ────────────────────────────
function resetPassword(data) {
  var sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName("users");
  var rows  = sheet.getDataRange().getValues();

  // data.new_password is already SHA-256 hashed from Flutter
  for (var i = 1; i < rows.length; i++) {
    if (rows[i][0].toString().trim() === data.name.trim()) {
      sheet.getRange(i + 1, 2).setValue(data.new_password); // column B = password
      return respond({ success: true, message: "Password updated" });
    }
  }
  return respond({ success: false, message: "Employee not found" });
}

// ── DASHBOARD (Admin) ─────────────────────────────────
function getDashboard() {
  var ss       = SpreadsheetApp.openById(SHEET_ID);
  var usersSheet  = ss.getSheetByName("users");
  var logSheet    = ss.getSheetByName("parking_log");

  var now   = new Date();
  var today = Utilities.formatDate(now, Session.getScriptTimeZone(), "yyyy-MM-dd");

  // Get all employees (name, number)
  var userRows = usersSheet.getDataRange().getValues();
  var employees = []; // { name, number }
  for (var i = 1; i < userRows.length; i++) {
    if (userRows[i][2].toString().trim() === "employee") {
      employees.push({
        name:   userRows[i][0].toString().trim(),
        number: userRows[i][3] ? userRows[i][3].toString().trim() : ""
      });
    }
  }

  // Get today's parking logs
  var logRows = logSheet.getDataRange().getValues();
  var parkedMap = {}; // name -> { vehicle_no, timestamp }
  for (var j = 1; j < logRows.length; j++) {
    if (logRows[j][3].toString() === today) {
      var empName = logRows[j][0].toString().trim();
      parkedMap[empName] = {
        vehicle_no: logRows[j][1],
        timestamp:  logRows[j][2].toString().substring(11, 16) // HH:mm
      };
    }
  }

  // Split into parked / not parked
  var parked    = [];
  var notParked = [];
  for (var k = 0; k < employees.length; k++) {
    var emp = employees[k];
    if (parkedMap[emp.name]) {
      parked.push({
        name:       emp.name,
        number:     emp.number,
        vehicle_no: parkedMap[emp.name].vehicle_no,
        time:       parkedMap[emp.name].timestamp
      });
    } else {
      notParked.push({ name: emp.name, number: emp.number });
    }
  }

  return respond({
    success:       true,
    total:         employees.length,
    parked_count:  parked.length,
    not_parked_count: notParked.length,
    parked:        parked,
    not_parked:    notParked
  });
}

// ── HELPER ─────────────────────────────────────────────
function respond(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
