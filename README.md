## Running the GUI

From a Linux command prompt, start the application using:

```bash
tclsh ares_bmc_gui.tcl
```

This launches the Ares BMC GUI and performs automatic system checks and initialization.

---

## Prerequisites

Before running `ares_bmc_gui.tcl`, ensure the following requirements are met:

### 1. BMC Software Package Installed
The GUI depends on the Ares BMC tools being installed in the expected system location:

```
/usr/share/rxc-bmc-tools
```

If this directory is missing, the application will exit and prompt installation.  
Refer to the **Ares BMC User Guide** for installation instructions.

---

### 2. Target Hardware Board Connected
The script requires a detected hardware device at:

```
$devicePath
```

If no board is found:
- Ensure the board is physically connected
- Ensure it is powered on
- The GUI will retry detection periodically until the device appears

---

### 3. System Access / Permissions
The application assumes it has permission to:
- Access `/usr/share/rxc-bmc-tools`
- Communicate with the connected BMC hardware device via `$devicePath`

Depending on system configuration, this may require appropriate user permissions or udev rules.

---

### 4. Environment Behavior on Startup
On launch, the GUI automatically initializes default control settings:
- Fan mode → Auto
- I2C address → `0x50 (Carrier EEPROM)`
- PLL configuration → SoM PLL
- Power mode → Auto
- Power control remains disabled until initialization completes

---

### 5. Runtime Initialization
During startup, the application:
- Validates all prerequisites
- Begins continuous monitoring of:
  - Voltage
  - Current
  - Temperature
  - Tachometer
  - Frequency
  - System state
  - Event logs
- Automatically adjusts GUI layout for optimal display
```
