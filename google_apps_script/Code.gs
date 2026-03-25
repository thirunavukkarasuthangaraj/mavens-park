var SHEET_ID = "1liGAr2mp1_89fTJoW3_7U8rEyNTHw-PiyZw6glmRX18";

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

// ── Helper: get date string from a cell value ────────────
function cellDate(val, tz) {
  if (val instanceof Date) return Utilities.formatDate(val, tz, "yyyy-MM-dd");
  return val.toString().trim().substring(0, 10);
}

function cellTime(val, tz) {
  if (val instanceof Date) return Utilities.formatDate(val, tz, "HH:mm");
  return val.toString().trim().substring(11, 16);
}

// ── LOGIN ────────────────────────────────────────────────
function login(data) {
  var sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName("employees");
  var rows  = sheet.getDataRange().getValues();
  var inputCode = data.code.toString().trim();
  var inputPass = data.password.toString().trim();

  for (var i = 1; i < rows.length; i++) {
    var empCode    = rows[i][0].toString().trim();
    var name       = rows[i][1].toString().trim();
    var email      = rows[i][2].toString().trim();
    var storedHash = rows[i][3].toString().trim();
    var role       = rows[i][4].toString().trim();
    var number     = rows[i][5].toString().trim();
    var mustChange = rows[i][6].toString().trim().toUpperCase();

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

// ── PARK VEHICLE (blocks duplicate on same day) ──────────
function parkVehicle(data) {
  var sheet  = SpreadsheetApp.openById(SHEET_ID).getSheetByName("parking_log");
  var tz     = Session.getScriptTimeZone();
  var now    = new Date();
  var today  = Utilities.formatDate(now, tz, "yyyy-MM-dd");
  var empCode = data.emp_code.toString().trim();

  // Reject empty emp_code
  if (!empCode) {
    return respond({ success: false, message: "Invalid employee code" });
  }

  // Check if already parked today
  var rows = sheet.getDataRange().getValues();
  for (var i = 1; i < rows.length; i++) {
    if (rows[i][0].toString().trim() === empCode &&
        cellDate(rows[i][3], tz) === today) {
      return respond({ success: false, message: "Already parked today" });
    }
  }

  var ts = Utilities.formatDate(now, tz, "yyyy-MM-dd HH:mm:ss");
  sheet.appendRow([empCode, data.user_name, data.vehicle_no, ts, today]);
  return respond({ success: true, message: "Vehicle parked successfully" });
}

// ── DASHBOARD ────────────────────────────────────────────
function getDashboard(data) {
  data = data || {};
  var ss       = SpreadsheetApp.openById(SHEET_ID);
  var empSheet = ss.getSheetByName("employees");
  var logSheet = ss.getSheetByName("parking_log");
  var tz       = Session.getScriptTimeZone();
  var today    = data.date
    ? data.date.toString().trim()
    : Utilities.formatDate(new Date(), tz, "yyyy-MM-dd");

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

  var logRows   = logSheet.getDataRange().getValues();
  var parkedMap = {};
  for (var j = 1; j < logRows.length; j++) {
    if (cellDate(logRows[j][3], tz) === today) {
      var code = logRows[j][0].toString().trim();
      parkedMap[code] = {
        vehicle_no: logRows[j][2].toString(),
        time:       cellTime(logRows[j][3], tz)
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
      notParked.push({ emp_code: emp.emp_code, name: emp.name, email: emp.email, number: emp.number });
    }
  }

  return respond({
    success:          true,
    date:             today,
    total:            employees.length,
    parked_count:     parked.length,
    not_parked_count: notParked.length,
    parked:           parked,
    not_parked:       notParked
  });
}

// ── ASSIGN NUMBER ────────────────────────────────────────
function assignNumber(data) {
  var sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName("employees");
  var rows  = sheet.getDataRange().getValues();
  for (var i = 1; i < rows.length; i++) {
    if (rows[i][0].toString().trim() === data.emp_code.trim()) {
      sheet.getRange(i + 1, 6).setValue(data.number);
      return respond({ success: true, message: "Number assigned" });
    }
  }
  return respond({ success: false, message: "Employee not found" });
}

// ── CHANGE PASSWORD ──────────────────────────────────────
function changePassword(data) {
  var sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName("employees");
  var rows  = sheet.getDataRange().getValues();
  for (var i = 1; i < rows.length; i++) {
    if (rows[i][1].toString().trim() === data.name.trim()) {
      if (rows[i][3].toString().trim() !== data.old_password.trim()) {
        return respond({ success: false, message: "Current password is incorrect" });
      }
      sheet.getRange(i + 1, 4).setValue(data.new_password);
      sheet.getRange(i + 1, 7).setValue("FALSE");
      return respond({ success: true, message: "Password changed successfully" });
    }
  }
  return respond({ success: false, message: "User not found" });
}

// ── RESET PASSWORD ───────────────────────────────────────
function resetPassword(data) {
  var sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName("employees");
  var rows  = sheet.getDataRange().getValues();
  for (var i = 1; i < rows.length; i++) {
    if (rows[i][1].toString().trim() === data.name.trim()) {
      sheet.getRange(i + 1, 4).setValue(data.new_password);
      sheet.getRange(i + 1, 7).setValue("TRUE");
      return respond({ success: true, message: "Password reset. Employee must change on next login." });
    }
  }
  return respond({ success: false, message: "Employee not found" });
}

// ── HELPER ───────────────────────────────────────────────
function respond(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
