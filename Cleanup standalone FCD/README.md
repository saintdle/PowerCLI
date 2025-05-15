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
.\standalone-fcd-cleanup.ps1

# Delete orphaned FCDs (with confirmation prompt)
.\standalone-fcd-cleanup.ps1 -DryRun:$false

# Automatically delete orphaned FCDs without prompt (USE EXTREME CAUTION)
.\standalone-fcd-cleanup.ps1 -DryRun:$false -AutoDelete
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
### 🖥️ Example Terminal Output

```shell
PS /home/dean/ocp> .\standalone-fcd-cleanup.ps1 -DryRun:$false
==========================================
   vSphere Standalone FCD Cleanup Tool v5
==========================================

Existing vCenter session found: vcsa.veducate.lab
Use this session? Type YES to proceed, NO to select or connect: yes
2025-05-15 15:00:23 [INFO] ==========================================
2025-05-15 15:00:23 [INFO]  Connected to: vcsa.veducate.lab
2025-05-15 15:00:23 [INFO]  DryRun: False
2025-05-15 15:00:23 [INFO]  AutoDelete: False
2025-05-15 15:00:23 [INFO] ==========================================
2025-05-15 15:00:23 [INFO] Retrieving all FCDs...
2025-05-15 15:00:26 [INFO] Retrieving all CNS volumes...
2025-05-15 15:00:32 [WARNING] Found 136 orphaned FCD(s).
2025-05-15 15:00:32 [INFO] Exported report: .\\StandaloneFCDs-vcsa.veducate.lab-20250515-150023.csv
Delete these orphaned FCDs? Type YES to proceed: yes
2025-05-15 15:00:36 [INFO] Starting serial deletion...
2025-05-15 15:00:38 [ERROR] Failed to delete pvc-450172a4-4690-4907-927a-2e57c7495c5d [Datastore-datastore-15:038daa3e-7aed-4506-95ce-b2b6c10e18ea] - 15/05/2025 15:00:38	Remove-VDisk		The operation is not allowed in the current state.	
2025-05-15 15:00:40 [SUCCESS] Deleted: pvc-d87317f0-597b-4c60-aabd-769c833072bc [Datastore-datastore-15:04527884-c716-400d-83f7-0afe55f2ae85]
2025-05-15 15:00:42 [SUCCESS] Deleted: pvc-64d8f3e6-26b5-4890-ab0d-862cc8b11e50 [Datastore-datastore-15:0b6b5036-b220-4c4e-8edb-0357bf9bc718]
2025-05-15 15:00:44 [SUCCESS] Deleted: pvc-81fb0ca9-c79f-48dc-af38-382d35f6417e [Datastore-datastore-15:0d0c7653-0f9e-4dc5-ba5b-0bf39aa715d9]
2025-05-15 15:00:46 [SUCCESS] Deleted: pvc-c80ccc47-0e85-465f-9bc9-f0673623728c [Datastore-datastore-15:0e2d09d8-4667-432c-bab1-c34189c000b9]
2025-05-15 15:00:49 [SUCCESS] Deleted: pvc-6a82348d-0e9f-4d85-b584-26d0f6820c34 [Datastore-datastore-15:0e8703cd-cfa0-4132-b712-6a49269fd8b2]
2025-05-15 15:00:51 [SUCCESS] Deleted: pvc-68c2f06b-f8ae-42a7-ad81-d21c87f26531 [Datastore-datastore-15:0e920507-466d-4258-8eb0-d1c25e7c8df3]
2025-05-15 15:00:53 [SUCCESS] Deleted: pvc-f69416af-7b11-4311-8fd9-c1b2a3faf254 [Datastore-datastore-15:0eb22e06-3fee-4f32-aed2-b568c69d285e]
2025-05-15 15:00:55 [SUCCESS] Deleted: pvc-ffd69b63-fbdd-48cf-a01c-f9cd9331992e [Datastore-datastore-15:11963262-5c77-4d22-946b-9da130ca9056]
2025-05-15 15:00:57 [SUCCESS] Deleted: pvc-b42376c1-d235-4e08-bf3f-374587857453 [Datastore-datastore-15:12db7137-b57c-454b-8458-9f3e1fa64e66]
```

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
