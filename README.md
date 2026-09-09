# Case Spam Zapper

One-click spam handling for Email-to-Case. Agents check a **Spam** checkbox on a Case; automation instantly closes it and moves it to a dedicated **Spam Queue**, and a daily scheduled job permanently deletes spam Cases after a 2-day retention period.

## What's included

| Component | API Name | Type |
|---|---|---|
| Flow | `Case_Before_Save_Spam_Auto_Close` | Record-Triggered (before save) on Case |
| Flow | `Case_Scheduled_Delete_Spam_Cases` | Schedule-Triggered on Case (Daily, 3:00 AM UTC) |
| Field | `Case.Spam__c` | Checkbox — the agent-facing spam flag |
| Field | `Case.Case_Owner_Name__c` | Formula (Text) — Owner name, used by the scheduled Flow's entry conditions |

Not included (created manually during setup): the **Spam Queue** (a Case Queue whose Developer Name must be exactly `Spam_Queue`). Queues are not packageable metadata that fits this solution's portability goals, so setup takes two minutes in the target org — see the guide.

## Installation & setup

Full instructions, screenshots, verification steps, and troubleshooting live in **[docs/GUIDE.md](docs/GUIDE.md)**.

Short version:

1. Install the package (or `sf project deploy start -o <org>` from this repo).
2. Create the **Spam Queue** (Developer Name `Spam_Queue`, supports Case).
3. Add the Spam checkbox to Case layouts + grant field-level security to agent profiles.
4. Activate both Flows and confirm the scheduled Flow runs Daily.

## Known limitations

- Flag spam on **existing** Cases. Cases *created* pre-flagged through channels that run Case Assignment Rules will have the queue re-routing overridden by the assignment rule (rules run after before-save flows).
- The scheduled Flow matches Cases by the queue's label ("Spam Queue") via the Case Owner Name formula — don't rename the queue.
- Deletion is a hard delete (Recycle Bin, then gone).

See the [guide](docs/GUIDE.md#known-limitations--troubleshooting) for the full list.

After installing a package version in a test org, complete the manual setup in [docs/GUIDE.md](docs/GUIDE.md) before testing.

## Versioning

| Version | Notes |
|---|---|
| 1.1 | Fixed spam-flag field reference in the before-save Flow; scheduled Flow set to Daily; retention aligned to 2 days; full documentation |
| 1.0 | Initial release |
