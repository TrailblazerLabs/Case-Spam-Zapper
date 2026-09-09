# Case Spam Zapper — Setup & User Guide

## Overview

When using Email-to-Case, spam messages create Cases that clog up your support Queue. The **Case Spam Zapper** solution lets agents deal with spam in one click: checking the **Spam** checkbox on a Case immediately closes it and moves it out of the working queue into a dedicated **Spam Queue**. A scheduled job then permanently deletes spam Cases after they have sat in the Spam Queue for the retention period (2 days).

The solution consists of two Flows and one custom field, supported by a Queue you create during setup:

- **Case - Before Save - Spam Auto Close** — record-triggered Flow that closes and re-routes flagged Cases
- **Case - Scheduled - Delete Spam Cases** — schedule-triggered Flow that deletes old spam Cases daily

## How It Works

![Flow Builder canvas of the Case - Before Save - Spam Auto Close flow](images/01-before-save-flow-canvas.png)

1. **User flags spam.** A user checks the **Spam** checkbox on a Case and saves.
2. **Case closes and moves.** Before the record is saved, the Flow sets the Case Status to **Closed** and changes the Owner to the **Spam Queue**. Because this happens before save, no extra update is needed and the change is instant.
3. **Scheduled cleanup.** The scheduled Flow finds Cases owned by the Spam Queue that are flagged as Spam, and deletes them on the schedule you set. Deleted Cases go to the Recycle Bin.

![Flow Builder canvas of the Case - Scheduled - Delete Spam Cases flow](images/04-scheduled-flow-canvas.png)

## Flow Details

### Case - Before Save - Spam Auto Close

Record-Triggered Flow on **Case** (created or updated), running **before save** (fast field update).

![Start element entry conditions](images/02-before-save-entry-conditions.png)

| Element | Type | What it does |
|---|---|---|
| Start | Record trigger (before save) | Fires when a Case is created or updated with **Spam = true**, only when the record is changed to meet the condition. |
| Get Spam Queue | Get Records | Looks up the Queue (Group object) where Type = *Queue* and Developer Name = **Spam_Queue** (first record only). |
| Close and assign to Spam Queue | Assignment | Sets Status = **Closed** and Owner = the Spam Queue. Committed with the triggering save — no separate update. |

![Get Spam Queue configuration](images/03a-get-spam-queue-config.png)
![Assignment configuration](images/03b-assignment-config.png)

### Case - Scheduled - Delete Spam Cases

Schedule-Triggered Flow on **Case**, runs on a schedule you set. Runs as the Automated Process user.

![Schedule configuration](images/05a-scheduled-trigger-schedule.png)
![Entry conditions](images/05b-scheduled-entry-conditions.png)

| Element | Type | What it does |
|---|---|---|
| Start | Schedule trigger (Daily) | Selects Cases where **Case Owner Name = "Spam Queue"** and **Spam = true**. |
| f_TwoDaysAgo | Formula (Date) | `{!$Flow.CurrentDate} - 2` — the retention cutoff. |
| 2 Days in Spam Queue? | Decision | Checks the Case's **Closed Date** is earlier than the cutoff. |
| Delete Spam Case | Delete Records | Deletes the Case. It goes to the Recycle Bin. |

## Data Dictionary

| Component | API Name (unmanaged / packaged) | Type | Purpose |
|---|---|---|---|
| Flow | `Case_Before_Save_Spam_Auto_Close` | Record-Triggered Flow (before save) | Closes flagged Cases and reassigns them to the Spam Queue |
| Flow | `Case_Scheduled_Delete_Spam_Cases` | Schedule-Triggered Flow | Deletes spam Cases on a schedule you set |
| Field | `Case.Spam__c` | Checkbox | User-facing spam flag; entry condition for both Flows |
| Field | `Case.Case_Owner_Name__c` | Formula (Text) | Case Owner's name; used by the scheduled Flow's entry conditions |
| Queue | `Spam_Queue` ("Spam Queue") | Queue on Case | Holding queue for flagged Cases; looked up by Developer Name — **created manually during setup** |

## Installation

Install the **Case Spam Zapper** from this repository's source. Then complete the manual setup below.

## Setup (Manual Configuration)

1. **Create the Spam Queue and Public Group.** Setup → Queues → New.
   - Label: **Spam Queue**
   - Queue Name (Developer Name): must be exactly **`Spam_Queue`** — the Flow looks it up by this API name.
   - Supported Objects: add **Case**.
   - Public Group: Create a public group of Users so that can review the queue prior to deletion, if review is important to your organization.

   ![Spam Queue setup page](images/06-spam-queue-setup.png)

2. **Expose the Spam checkbox.** Add the **Spam** field to the Case page layout(s)/Lightning record pages used by your support team, and grant Edit access on the field (field-level security) to user profiles or permission sets.

   ![Case record with Spam checkbox](images/07-case-spam-checkbox.png)

3. **Confirm a Closed status exists.** The Flow sets Status to **Closed**; make sure your Case support process includes it.

4. **Activate the Flows.** Both Flows must be Active. For *Case - Scheduled - Delete Spam Cases*, set the schedule with a future start date/time.

## Verifying the Setup

1. Create a test Case (any origin) and check the **Spam** checkbox, then save.
2. Confirm the Case is now **Closed** and owned by **Spam Queue**.

   ![Spam Queue list view with a flagged, closed Case](images/08-spam-queue-list-view.png)

3. Deletion can be verified after the retention period, or by opening the scheduled Flow in Flow Builder and using **Debug**.

## Considerations & Troubleshooting

- **Flag spam on existing Cases.** If a Case is *created* with the Spam checkbox already checked through a channel that runs Case Assignment Rules (Email-to-Case, API with auto-assign, or the "Assign using active assignment rules" checkbox), the assignment rule runs after this automation and overrides the owner — the Case ends up closed but back in the working queue, and it will not be auto-deleted. The normal pattern — an agent checking Spam on an existing Case and saving — is unaffected.
- **Do not rename the Spam Queue.** The scheduled Flow matches Cases by the queue's *name* ("Spam Queue") via the Case Owner Name formula field. Renaming the queue label silently stops deletion. Renaming the queue's Developer Name breaks the before-save re-routing.
- **Deletion is real.** Deleted Cases go to the Recycle Bin (recoverable for 15 days by an admin), then are gone. Flagged Cases also count toward data storage until deleted.
- **Nothing happens when I check Spam:** confirm both Flows are Active, the queue Developer Name is exactly `Spam_Queue`, and the user has edit access to the Spam field.
- **Cases aren't being deleted:** open the scheduled Flow and confirm the schedule is set with a start date in the past or today; check that flagged Cases are owned by the Spam Queue and that the status equals closed.
- **Un-flagging:** unchecking Spam does not reopen the Case or move it back — manually change Status and Owner if a Case was flagged in error, and do it within the retention window.
