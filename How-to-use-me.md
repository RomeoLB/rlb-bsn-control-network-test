# How to Use BrightSign Network Check Report

This document provides instructions on how to use the BrightSign Network Check Report tool.

---

## Overview

The BrightSign Network Check Report is a Node.js application that tests network connectivity to BrightSign Cloud services and validates path information including DNS resolution, TCP connectivity, HTTP/HTTPS access, WebSocket connectivity, NTP time sync, and file downloads.

---

## Features

- **DNS Resolution Tests**: Validates domain name resolution and retrieves all resolved IP addresses
- **TCP Connectivity Tests**: Checks TCP connectivity to specified hosts and ports
- **HTTP/HTTPS Tests**: Tests HTTP and HTTPS connectivity with status code reporting
- **WebSocket Tests**: Validates WebSocket (WSS) connectivity to BrightSign services
- **NTP Time Sync Tests**: Tests Network Time Protocol connectivity
- **File Download Tests**: Tests downloading files from specified URLs with TLS issuer information
- **Path Validation**: Advanced path analysis including:
  - Resolved IPs for target host
  - Connected IP (actual connection source)
  - TLS certificate issuer information
  - Proxy detection
- **HTML Report Generation**: Generates a comprehensive HTML report of all test results
- **Network Interface Information**: Captures live wired network interface status
- **Device Information**: Captures BrightSign device info when running on hardware

---

## Getting Started

### What You Need

- A BrightSign media player
- An SD card (minimum 4GB recommended)
- An SD card reader on your computer
- The following 3 files:
  - `autorun.brs`
  - `bs-player-netcheck-report.html`
  - `bundle.js`

### Installation Steps

1. **Insert SD Card**: Insert your SD card into an SD card reader connected to your computer.

2. **Copy Files**: Copy the 3 provided files to the root of the SD card:
   - `autorun.brs`
   - `bs-player-netcheck-report.html`
   - `bundle.js`

3. **Eject SD Card**: Safely eject the SD card from your computer.

4. **Insert into Player**: Insert the SD card into your BrightSign player.

5. **Power On**: Switch on the BrightSign player. The application will automatically start running network connectivity tests.

---

## Using the Application

### View Test Results

Once the player is powered on, the application automatically starts running network connectivity tests. The results are saved to the SD card and can be viewed in two ways:

**Option 1: View on the Player**
- The BrightSign player displays the connectivity report directly on the player's screen or connected display. A mouse with a scroller can be used to scroll down the report when viewing the results from the player.

**Option 2: View on Your Computer**
1. Remove the SD card from the player
2. Insert it into your computer's SD card reader
3. Locate the following files on the SD card:
   - `bs-player-netcheck-report.html` (the report file)
   - `connectivity-test-results.json` (the test data)
4. Open `bs-player-netcheck-report.html` with any web browser
5. The report will display all connectivity test results

### Generated Files

When the tests run, the following files are created on the SD card:
- **bs-player-netcheck-report.html**: The visual report (open with web browser)
- **connectivity-test-results.json**: Raw test data in JSON format
- **kernel.log**: System kernel log dump for technical diagnostics

---

## Report Structure

### Test Summary Section

Displays:
- Test start and end times
- Platform information (BrightSign or other OS)
- Node.js version
- Timeout settings per check
- Total hosts tested and pass/fail counts
- Platform detection (BrightSign device if applicable)

### Device Information

If running on a BrightSign device, displays:
- Device model
- Serial number
- Operating system version

### Network Information

Displays current eth0 (primary Ethernet) interface details:
- IP Address
- MAC Address
- Link status (Connected/Disconnected)
- Connection type

### Path Validation

Shows advanced path analysis for the sample host:
- **Resolved IPs**: All IP addresses discovered for the domain
- **Connected IP**: The actual IP address connected to
- **TLS Issuer**: Certificate issuer organization name
- **Proxy Detected**: Whether HTTP proxy environment variables are set

### Host Connectivity Tests

Detailed table showing each test target with:
- Host name
- Overall pass/fail status
- Individual check results (DNS, TCP, HTTP/HTTPS, WSS, NTP)
- Latency measurements for each check
- Detailed response information or error messages

### File Download Tests

For each file download URL, displays:
- URL and filename
- Success/failure status
- HTTP status code
- Download latency
- Bytes downloaded
- File save location
- **TLS Issuer** (for HTTPS downloads)
- Error information if applicable

### Top Slowest Hosts

Lists the 5 hosts with the highest maximum latency among all performed checks.

---

## Configuration

The application comes pre-configured to test all BrightSign Cloud services. No additional configuration is required for normal use.


---

## Understanding Test Results

The connectivity report shows the status of various network tests:

- **PASS (✓)**: The test was successful and the connection/service is working
- **FAIL (✗)**: The test failed; the connection/service is not reachable or not working

Each host shows multiple test types:
- **DNS**: Domain name resolution
- **TCP**: Basic connection to a port
- **HTTP/HTTPS**: Web service connectivity
- **WSS**: WebSocket connectivity
- **NTP**: Time synchronization service
- **File Download**: File retrieval from the internet

---

## Output Files

The application generates three files on your SD card:

1. **bs-player-netcheck-report.html** - The main connectivity report (open with any web browser)
2. **connectivity-test-results.json** - Raw test data in JSON format (human-readable text file with all test details)
3. **kernel.log** - System kernel log dump for technical diagnostics

Simply open the HTML file with a web browser to view all your test results in an easy-to-read format.

---

## How Often Are Tests Run?

The application runs connectivity tests automatically:
- **On startup**: Tests run immediately when the player powers on
- **Continuously**: The player remains online and the report is updated as test data becomes available
- **On demand**: Refresh your browser to see the latest test results

---

## Advanced Information

### What is Path Validation?

Path Validation tests one of the key BrightSign services (ws.bsn.cloud) and reports:
- **Resolved IPs**: All IP addresses found for the service
- **Connected IP**: The actual IP address your player connected to
- **TLS Issuer**: The security certificate provider (indicates a secure connection)
- **Proxy Detected**: Whether your network uses a proxy server

### File Download Tests

The application tests downloading files from BrightSign services and reports:
- Success or failure of each download
- Download speed and file size
- Security certificate information for HTTPS downloads

---

## Troubleshooting

### Can't Access the Report
- **Check player is powered on**: Ensure the BrightSign player is powered on and has been running for at least 30 seconds
- **Try viewing on the player**: Check the player's connected display to see if the report is showing there
- **Check the SD card**: Remove the SD card and insert it into your computer's card reader
- **Verify files exist**: Look for `bs-player-netcheck-report.html` and `connectivity-test-results.json` on the SD card root
- **Try a different browser**: If opening the HTML file on your computer, try a different web browser
- **Wait a moment**: The first test run may take a minute to complete

### Some Tests Show FAIL
- **Network connectivity**: Verify the player has a stable internet connection
- **Firewall settings**: Check if your network firewall is blocking outbound connections
- **DNS issues**: Your network's DNS server may not be working properly
- **Service outage**: The BrightSign service being tested may be temporarily unavailable
- **Proxy or VPN**: Check if your network uses a proxy server that may be interfering

### All Tests Show FAIL
- **No internet connection**: Verify the player is connected to the internet
- **Network cable**: Check that the Ethernet cable is properly connected
- **Network settings**: Verify the player's IP configuration (DHCP or static IP)
- **Firewall blocking**: Check if a firewall is blocking all outbound connections
- **Contact support**: If issues persist, contact your BrightSign support representative

---

## Support

If you experience issues with the BrightSign Network Check application:

1. **Check the troubleshooting section above** for common solutions
2. **Note any FAIL tests** and which services are not reachable
3. **Contact your network administrator** to verify firewall and proxy settings
4. **Contact BrightSign support** with details about which tests are failing
