@echo off
setlocal enabledelayedexpansion

rem Test script to simulate 100 concurrent login requests
set API_URL=https://script.google.com/macros/s/AKfycbxCSdtFgIjs8kCwELMOjxdaEe3SPHv6tNHU35H7n2poBIRrLFMX442T_EXVeB5llmXp/exec
set CONCURRENT_REQUESTS=100

echo Starting concurrent login test with %CONCURRENT_REQUESTS% requests
echo API URL: %API_URL%
echo Test started at: %date% %time%
echo ==================================

rem Create temp directory for results
if not exist test_results mkdir test_results
del /Q test_results\* 2>nul

echo Launching %CONCURRENT_REQUESTS% concurrent requests...

rem Create a simple PowerShell script to handle concurrent requests
(
echo $apiUrl = "%API_URL%"
echo $requests = %CONCURRENT_REQUESTS%
echo $testData = '{"action":"login","code":"101","password":"1234"}'
echo $encodedData = [System.Uri]::EscapeDataString($testData^)
echo $url = "$apiUrl" + "?data=" + $encodedData
echo 
echo Write-Host "Making $requests concurrent requests to:"
echo Write-Host $url
echo Write-Host ""
echo 
echo $jobs = @(^)
echo for ($i = 1; $i -le $requests; $i++^) {
echo     $jobs += Start-Job -ScriptBlock {
echo         param($url, $id^)
echo         $start = Get-Date
echo         try {
echo             $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 45
echo             $end = Get-Date
echo             $duration = ($end - $start^).TotalSeconds
echo             $result = @{
echo                 Id = $id
echo                 Status = $response.StatusCode
echo                 Duration = $duration
echo                 Content = $response.Content
echo                 Success = $true
echo             }
echo         } catch {
echo             $end = Get-Date
echo             $duration = ($end - $start^).TotalSeconds
echo             $result = @{
echo                 Id = $id
echo                 Status = "ERROR"
echo                 Duration = $duration
echo                 Content = $_.Exception.Message
echo                 Success = $false
echo             }
echo         }
echo         return $result
echo     } -ArgumentList $url, $i
echo     Write-Host "Started request $i"
echo }
echo 
echo Write-Host "Waiting for all requests to complete..."
echo $results = $jobs ^| Wait-Job ^| Receive-Job
echo $jobs ^| Remove-Job
echo 
echo Write-Host "=================================="
echo Write-Host "Test completed at: $(Get-Date^)"
echo Write-Host ""
echo Write-Host "RESULTS SUMMARY:"
echo Write-Host "================"
echo 
echo $totalRequests = $results.Count
echo $successfulRequests = ($results ^| Where-Object { $_.Success -eq $true -and $_.Status -eq 200 }^).Count
echo $httpErrors = ($results ^| Where-Object { $_.Success -eq $false }^).Count
echo $apiErrors = 0
echo 
echo foreach ($result in $results^) {
echo     if ($result.Success -and $result.Content -like "*success.*false*"^) {
echo         $apiErrors++
echo     }
echo }
echo 
echo Write-Host "Total requests: $totalRequests"
echo Write-Host "HTTP 200 responses: $successfulRequests"  
echo Write-Host "HTTP errors: $httpErrors"
echo Write-Host "API errors: $apiErrors"
echo 
echo Write-Host ""
echo Write-Host "RESPONSE TIME ANALYSIS:"
echo Write-Host "======================"
echo 
echo $durations = $results ^| ForEach-Object { $_.Duration }
echo $minTime = ($durations ^| Measure-Object -Minimum^).Minimum
echo $maxTime = ($durations ^| Measure-Object -Maximum^).Maximum  
echo $avgTime = ($durations ^| Measure-Object -Average^).Average
echo $slowRequests = ($durations ^| Where-Object { $_ -gt 10 }^).Count
echo $timeoutRequests = ($durations ^| Where-Object { $_ -gt 30 }^).Count
echo 
echo Write-Host "Min response time: $([math]::Round($minTime, 2^)^)s"
echo Write-Host "Max response time: $([math]::Round($maxTime, 2^)^)s" 
echo Write-Host "Average response time: $([math]::Round($avgTime, 2^)^)s"
echo Write-Host "Requests > 10s: $slowRequests"
echo Write-Host "Requests > 30s: $timeoutRequests"
echo 
echo Write-Host "=================================="
echo 
echo # Save detailed results
echo $results ^| Export-Csv "test_results\detailed_results.csv" -NoTypeInformation
echo Write-Host "Detailed results saved to test_results\detailed_results.csv"
) > test_concurrent.ps1

rem Run the PowerShell script
powershell -ExecutionPolicy Bypass -File test_concurrent.ps1

rem Clean up
del test_concurrent.ps1

pause