# BitReaper – Security Notes

## How `diskpart clean all` Works

`diskpart clean all` is a built-in Windows command that writes **zeros to every sector** on a selected disk. Unlike `cipher /w`, which only targets free space, `clean all` overwrites the entire disk surface including:

- All file data (allocated and unallocated)
- All partitions and partition tables
- All filesystem metadata (MFT, journals, boot records)
- All Volume Shadow Copies

After `clean all` completes, the disk is left in a **raw, uninitialized state** with no partitions and no filesystem. It will appear as "Not Initialized" in Windows Disk Management and cannot be used until it is re-initialized (MBR or GPT) and new volumes are created and formatted.

> **Important:** `diskpart clean all` performs a single zero-pass overwrite. For HDDs, this is sufficient to prevent software-based recovery. For the highest assurance on HDDs, physical destruction remains the gold standard.

---

## How `cipher /w` Works

`cipher /w` is a built-in Windows command that overwrites **unallocated disk clusters** (free space) to prevent recovery of previously deleted data.

Internally it performs **three passes**:

| Pass | Written value    |
|------|-----------------|
| 1    | 0x00 (all zeros) |
| 2    | 0xFF (all ones)  |
| 3    | Random data      |

This approach is consistent with the **US DoD 5220.22-M (E)** standard for media sanitisation, though it is not formally certified.

> **Important:** `cipher /w` only overwrites _free space_. It does **not** target live files. Always delete the file first (Option 1 or 2) before wiping free space.

---

## Windows Filesystem Considerations

### NTFS Journal and Metadata

NTFS maintains a **change journal** (`$UsnJrnl`) and **MFT** (Master File Table) that may retain metadata about deleted files (filename, timestamps, size). `cipher /w` does not erase these structures.

For highly sensitive scenarios, consider:

- Using a forensic-grade tool such as **Eraser** or a DBAN bootable disk.
- Encrypting the volume _before_ storing data (BitLocker, VeraCrypt) so that deletion is equivalent to losing the key.

### SSD / Flash Storage

On **solid-state drives**, the storage controller remaps sectors transparently. This means:

- `cipher /w` may not reach every physical NAND cell that held the original data.
- `diskpart clean all` writes zeros sector-by-sector, but the SSD controller may still retain copies in remapped or over-provisioned cells not visible to the OS.
- The SSD's internal wear-levelling may preserve copies in cells not visible to the OS.
- For SSDs, the most reliable sanitisation method is **ATA Secure Erase** (via the manufacturer's tool or `hdparm` under Linux), or full-drive encryption before first use.

### File System Snapshots (VSS)

Windows **Volume Shadow Copy Service (VSS)** may retain previous versions of files. BitReaper does not delete shadow copies. To remove them manually:

```cmd
vssadmin delete shadows /for=C: /all /quiet
```

Run this command as Administrator before performing a free-space wipe if VSS recovery is a concern.

### Encrypted File System (EFS)

If a file is protected by **Windows EFS**, deleting it removes the ciphertext but the decryption key may remain in the user profile. Ensure the EFS certificate and private key are also removed when decommissioning a machine.

---

## Limitations of BitReaper

| Limitation | Explanation |
|---|---|
| No SSD guarantee | NAND wear-levelling makes sector-level overwrites unreliable on SSDs (applies to both `cipher /w` and `diskpart clean all`) |
| NTFS metadata | Filename and timestamps may persist in the MFT / journal (Options 1–4 only; Option 5 erases the entire disk) |
| VSS snapshots | Shadow copies are not deleted automatically (Options 1–4 only; Option 5 removes all partitions) |
| Network drives | `cipher /w` behaviour on mapped network drives varies by server OS |
| Elevated rights | Without Administrator privileges, `cipher /w` may skip system-owned clusters and `diskpart` will not run |
| System disk | Option 5 refuses to wipe the disk containing the Windows system drive for safety |

---

## Recommendations

1. **Encrypt first, delete later** — storing data on an encrypted volume means deletion is equivalent to key destruction.
2. **Run as Administrator** — ensures `cipher /w` can reach all free clusters and `diskpart` can run.
3. **Delete VSS shadows** before wiping free space on critical volumes.
4. **For full disk sanitisation** — use Option 5 (Full Disk Wipe) to zero every sector and remove all partitions. This leaves the disk blank and unusable.
5. **For SSDs** — use the drive manufacturer's secure-erase utility or rely on full-disk encryption. `diskpart clean all` provides reasonable assurance but cannot overcome hardware-level wear-levelling.
6. **Physical destruction** — for the highest assurance (decommissioned hardware), degaussing or physical shredding is the only guaranteed method.

---

## References

- [Microsoft Docs — cipher](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/cipher)
- [NIST SP 800-88 — Guidelines for Media Sanitization](https://csrc.nist.gov/publications/detail/sp/800-88/rev-1/final)
- [DoD 5220.22-M National Industrial Security Program Operating Manual](https://www.esd.whs.mil/Portals/54/Documents/DD/issuances/dodm/522022M.pdf)
