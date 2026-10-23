# Framework Laptop 16 USB-C PD/UCSI firmware issue

Investigated on `fn` on 2026-10-10/11.

## System

- Framework Laptop 16, AMD Ryzen 7040 series
- UMA graphics; no discrete GPU
- BIOS: `04.04`, released 2026-03-23
- EC: `lotus-4.0.4-3050f2d`
- CCG8 PD controllers: `0.0.21` on both sides
- NixOS kernel: `6.18.54`

## Symptoms

Connecting a USB-C PD source produces messages such as:

```text
ucsi_acpi USBC000:00: unknown error 256
ucsi_acpi USBC000:00: unknown error 0
ucsi_acpi USBC000:00: UCSI_GET_PDOS failed (-5)
ucsi_acpi USBC000:00: UCSI_GET_PDOS failed (-95)
ucsi_acpi USBC000:00: ucsi_handle_connector_change: GET_CONNECTOR_STATUS failed (-95)
ucsi_acpi USBC000:00: con4: failed to register partner alt modes (-95)
```

When PD is connected during boot, the entire machine can become extremely slow. Boot takes several times longer and the resulting session can be unusable.

Power delivery itself may still work. During investigation, the controller successfully negotiated a 20 V, 6.5 A, 130 W contract and charged the battery while the UCSI metadata queries failed.

## Conclusion

This is a Framework platform-firmware problem, not a NixOS configuration or Linux-kernel regression.

The likely failure chain is:

```text
PD source present during EC/BIOS initialization
    -> CCG8/EC enters an inconsistent PD/UCSI state
    -> EC/AMD SMU power state may become stuck at minimum performance
    -> firmware, bootloader, kernel, and desktop become extremely slow
    -> Linux later reports the accompanying UCSI command failures
```

The journal messages do not themselves cause the pre-Linux slowdown. Both the slowdown and the messages are consequences of the bad firmware state.

## Meaning of the errors

- `256` is UCSI error bit 8, `UCSI_ERROR_UNDEFINED`. It is **not** the overcurrent bit; overcurrent is bit 7 (`128`).
- `0` means the platform signalled a UCSI error, but `GET_ERROR_STATUS` returned no error bits.
- `-5` is Linux `EIO`.
- `-95` is Linux `EOPNOTSUPP`.

Linux reads the platform's error response in [`drivers/usb/typec/ucsi/ucsi.c`](https://github.com/torvalds/linux/blob/master/drivers/usb/typec/ucsi/ucsi.c) and reports it. The Linux driver is not generating error `256` independently.

## Concrete EC firmware defect

The exact Framework EC source branch corresponding to installed EC build `3050f2d` contains an error while selecting `GET_ERROR_STATUS` responses from the two CCG8 controllers:

```c
uint16_t error_information =
    (pd_chip_ucsi_info[i].message_in[1] << 8) |
    pd_chip_ucsi_info[i].message_in[1];
```

The low byte should evidently be `message_in[0]`, not a second copy of `message_in[1]`. This can cause the EC to select the wrong controller response or return an empty error status, explaining at least some occurrences of `unknown error 0`.

The defect was introduced by Framework/Compal commit [`95b509498`](https://github.com/FrameworkComputer/EmbeddedController/commit/95b509498de130bcf0f5e5e3c0c7764b51a26509) in August 2025 and is present in the [EC branch used by BIOS 4.04](https://github.com/FrameworkComputer/EmbeddedController/blob/fwk-tulip-29169/zephyr/program/framework/src/ucsi.c#L583-L590).

This typo does not itself create error `0x0100`. The CCG8 PD firmware appears to return the undefined error for `GET_PDOS`; the EC defect can misselect or lose the corresponding error response.

## Boot evidence

Retained boots show that the bad state affects stages that run before the Linux UCSI driver loads:

| State | Firmware | Loader | Kernel | Userspace |
|---|---:|---:|---:|---:|
| Healthy example | 7.6 s | 0.75 s | 0.71 s | 8.3 s |
| Bad example 1 | 31.1 s | 7.2 s | 10.1 s | 40.9 s |
| Bad example 2 | 38.9 s | 12.8 s | 9.4 s | 51.9 s |

The last affected session also logged 50 UCSI failures over approximately 16 minutes, including repeated PDO, connector-status, and alternate-mode failures.

The retained journal contains `unknown error 256` as far back as 2026-07-14 under kernel 7.1.1. The complete `256 -> 0 -> GET_PDOS -5` sequence appears from 2026-07-21. Therefore kernel 6.18.54 and the current NixOS generation did not introduce the problem.

Framework lists an intermittent 545 MHz CPU-frequency lock as a known FW16 7040 firmware issue. Related reports include:

- [CPU frequency stuck at low values on FW16 AMD 7040](https://github.com/FrameworkComputer/SoftwareFirmwareIssueTracker/issues/91)
- [FW16 AMD 7040 stuck at 0.55 GHz after BIOS 3.07 to 4.02](https://github.com/FrameworkComputer/SoftwareFirmwareIssueTracker/issues/133)
- [Adapter connection, UCSI failures, EC events, and minimum-clock lock](https://github.com/FrameworkComputer/SoftwareFirmwareIssueTracker/issues/243)
- [Exact UCSI error sequence after FW16 BIOS 3.07 to 4.02](https://github.com/FrameworkComputer/SoftwareFirmwareIssueTracker/issues/132)

At the time of investigation, the current healthy boot allowed cores to reach approximately 5 GHz, temperatures were 37-40 C, and `h_prochot_l=1`, meaning hardware PROCHOT was not asserted.

## Immediate recovery

1. Shut the laptop down completely.
2. Disconnect the charger and every USB-C device.
3. Wait at least three minutes so the EC and PD controllers fully lose power.
4. Boot on battery.
5. Connect the charger only after reaching the desktop.

If that does not clear the state, use **BIOS -> Advanced -> Battery Disconnect**, allow the machine to shut down, then reconnect the charger to start it again.

A normal reboot may preserve the bad EC state.

## Confirming the clock lock

Run these commands while the machine is slow:

```bash
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq | sort -n | uniq -c
sudo ectool gpioget h_prochot_l
sudo ectool temps all
```

If all cores remain around 544 MHz to 1.1 GHz under load, the platform-level frequency lock is confirmed. Power-profile, governor, and `amd_pstate` changes generally cannot clear a limit imposed by the EC/SMU.

## Durable fix options

### 1. Obtain Framework's corrected PD test BIOS

Framework states that a PD fix has been validated on laptop platforms and that a model-specific test BIOS is being distributed through Support ahead of a formal Q4 release. Open a [Framework Support](https://frame.work/support) case and reference [PD tracker issue #225](https://github.com/FrameworkComputer/SoftwareFirmwareIssueTracker/issues/225#issuecomment-5490733359).

Include:

- FW16 AMD 7040, UMA graphics
- BIOS `04.04`
- EC `lotus-4.0.4-3050f2d`
- CCG8 PD firmware `0.0.21`
- the UCSI messages above
- the fact that booting with any PD source attached triggers severe slowdown
- the boot-phase timing comparison
- the EC source defect and commit `95b509498`

Request the test BIOS specifically for the FW16 AMD 7040. Do not install a test image intended for another Framework model.

### 2. Public-firmware workaround: downgrade to BIOS 3.07

This system is UMA-only. Framework's [BIOS 4.04 release notes](https://community.frame.work/t/framework-laptop-16-ryzen-7040-bios-4-04-release-stable/81740) explicitly permit downgrading an UMA or RX 7700 system to BIOS 3.05 or newer.

BIOS 3.07:

- uses older PD firmware `0.0.1E`;
- predates the BIOS 4.02 change to UCSI 2.0 associated with these errors;
- includes an earlier fix for the 545 MHz resume lock;
- includes more security fixes than BIOS 3.05.

Use only Framework's [official BIOS 3.07 package and instructions](https://community.frame.work/t/framework-laptop-16-ryzen-7040-bios-3-07-release-stable/75370). The published SHA-256 for the EFI archive is:

```text
6241F5EDF3D3DB347FCF9A5E9CD08438EFBFE49A51EEC5579F59EF2278EA0FC2
```

Before flashing firmware:

- back up important data and record BIOS settings;
- cold-reset the EC first;
- ensure adequate battery charge and stable AC power;
- disconnect all unnecessary peripherals;
- never interrupt the update.

If 3.07 still reproduces the problem, BIOS 3.05 is the stronger last-known-good fallback. Its release notes explicitly mention a fix for a 500 MHz CPU lock caused by greater-than-100-W PD sources through some multifunction hubs. However, it lacks later firmware security fixes. See the [official BIOS 3.05 release](https://community.frame.work/t/framework-laptop-16-ryzen-7040-bios-3-05-release/60735).

### BIOS 4.05 is not a confirmed fix

BIOS 4.05 retains CCG8 PD firmware `0.0.21` and still lists the intermittent 545 MHz lock as a known issue. Its [release notes](https://community.frame.work/t/framework-laptop-16-ryzen-7040-bios-4-05-release-stable/83533) do not claim to fix this failure. On this machine, `fwupdmgr get-updates` currently reports no available update.

## Optional Linux containment

Blacklisting `ucsi_acpi` may stop the post-login UCSI retry loop:

```nix
boot.blacklistedKernelModules = [ "ucsi_acpi" ];
```

This is not a firmware fix and cannot prevent the pre-Linux slowdown. It may also break USB-C display alternate modes, docks, partner information, and Type-C power-supply reporting. Use it only as a temporary diagnostic or containment measure.

No NixOS configuration changes were made during this investigation.
