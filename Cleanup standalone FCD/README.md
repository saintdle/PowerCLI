# vSphere Standalone FCD Cleanup Tool

A PowerShell / PowerCLI tool to safely identify and optionally delete standalone First Class Disks (FCDs) in VMware vSphere that are not associated with any Container Native Storage (CNS) volumes.

This version includes advanced features like:
- Auto-detect and use existing vCenter sessions
- Multi-vCenter session handling
- Dry-run mode (default, safe)
- Parallel deletion for large-scale environments (PowerShell 7+)
- Full structured logging and CSV export for audits
- Clean human-readable logs

---

## 🔧 Prerequisites

- VMware PowerCLI module installed
- PowerShell 7+ (`pwsh`) strongly recommended (especially for parallel mode)
- Connection to vSphere 7.0+ environment
- Sufficient permissions to list and delete VDisks

---

## 💻 Usage

```powershell
# Dry run (default, safe mode)
.\standalone-fcd-cleanup-v2.ps1

# Delete orphaned FCDs (with confirmation prompt)
.\standalone-fcd-cleanup-v2.ps1 -DryRun:$false

# Automatically delete orphaned FCDs without prompt (USE EXTREME CAUTION)
.\standalone-fcd-cleanup-v2.ps1 -DryRun:$false -AutoDelete
```

The script will:
1. Check for existing `$global:defaultviserver` connections and offer to reuse it.
2. If no default, list all active vCenter sessions and allow selection.
3. Otherwise, prompt for new vCenter connection.
4. Scan for orphaned standalone FCDs not associated with CNS.
5. Export a full CSV report of findings.
6. Optionally delete orphaned FCDs after confirmation.
---

## ⚠️ Important Safety Notice

The script is **safe by default** (`DryRun:$true`).  
**No deletions will occur unless you explicitly disable Dry Run.**

If using `-AutoDelete`, the script will delete orphaned FCDs without asking.  
**This is highly dangerous in production environments. Only use if fully confident.**

Always review the exported CSV report before deletion.

---

## 📝 Example Output Files

- `FCD-Cleanup-<vCenter>-<timestamp>.log` → Full log of all actions
- `StandaloneFCDs-<vCenter>-<timestamp>.csv` → List of orphaned FCDs

---

## 🤝 Ownership and Licensing

Author: [Dean Lewis](https://bsky.app/profile/saintdle.bsky.social)  
GitHub: [https://github.com/saintdle/PowerCLI](https://github.com/saintdle/PowerCLI)

Licensed under the MIT License.  
See [`LICENSE`](../LICENSE) file for full license text.

---

## 🙏 Acknowledgements

This script was inspired by community best practices and operational challenges in managing large vSphere environments.  
Special thanks to VMware PowerCLI maintainers and the broader VMware community.

---

## 📣 Feedback and Contributions

Pull requests and feedback are welcome!  
Please open an issue or PR at: [https://github.com/saintdle/PowerCLI](https://github.com/saintdle/PowerCLI)
