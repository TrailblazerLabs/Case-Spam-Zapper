/**
 * Demo utility for the Case Spam solution.
 *
 * Reproduces on demand what the scheduled flow "Case - Scheduled - Delete Spam Cases"
 * does at its daily 03:00 UTC run, so the deletion step can be shown in a live demo
 * without waiting for the scheduler.
 *
 * The flow deletes Cases where:
 *   Spam__c = true
 *   AND Case_Owner_Name__c = 'Spam Queue'
 *   AND ClosedDate < (run date - 2 days)
 *
 * Usage (Setup > Developer Console > Execute Anonymous, or `sf apex run`):
 *   CaseSpamDeletionDemo.preview();  // list what tonight's run would delete - no changes
 *   CaseSpamDeletionDemo.run();      // do exactly what tonight's scheduled run will do
 *   CaseSpamDeletionDemo.run(0);     // demo mode: ignore the 2-day retention and delete
 *                                    // every spam Case currently closed in the Spam Queue
 */
public with sharing class CaseSpamDeletionDemo {

    /** Retention used by the scheduled flow (days a spam Case sits in the queue before deletion). */
    public static final Integer RETENTION_DAYS = 2;

    /** Lists the Cases the scheduled flow would delete today, without deleting them. */
    public static List<Case> preview() {
        return preview(RETENTION_DAYS);
    }

    public static List<Case> preview(Integer retentionDays) {
        List<Case> eligible = findEligible(retentionDays);
        System.debug(LoggingLevel.INFO, '=== Case Spam deletion preview (retention: ' + retentionDays + ' days) ===');
        System.debug(LoggingLevel.INFO, eligible.size() + ' Case(s) eligible for deletion:');
        for (Case c : eligible) {
            System.debug(LoggingLevel.INFO, '  ' + c.CaseNumber + ' | closed ' + c.ClosedDate + ' | ' + c.Subject);
        }
        return eligible;
    }

    /** Runs the same deletion the scheduled flow performs, using its 2-day retention. */
    public static Integer run() {
        return run(RETENTION_DAYS);
    }

    /**
     * Runs the deletion with an overridable retention. Pass 0 in a live demo to delete
     * everything currently sitting closed in the Spam Queue, regardless of age.
     */
    public static Integer run(Integer retentionDays) {
        List<Case> eligible = preview(retentionDays);
        if (!eligible.isEmpty()) {
            delete eligible;
        }
        System.debug(LoggingLevel.INFO, 'Deleted ' + eligible.size() + ' spam Case(s).');
        return eligible.size();
    }

    /**
     * Mirrors the scheduled flow's criteria. The flow compares the ClosedDate date/time
     * against a Date formula (today - retention), so the cutoff here is that date at
     * midnight GMT - close enough to the flow's boundary for demo purposes. A retention
     * of 0 or less means "no retention": every Case currently closed in the Spam Queue.
     * (The cutoff sits 1 minute in the future because SOQL compares date/times at
     * second granularity - a strict "< now" misses Cases closed within the same second.)
     */
    private static List<Case> findEligible(Integer retentionDays) {
        Datetime cutoff = retentionDays <= 0
            ? Datetime.now().addMinutes(1)
            : Datetime.newInstanceGmt(Date.today().addDays(-retentionDays), Time.newInstance(0, 0, 0, 0));
        return [
            SELECT Id, CaseNumber, Subject, ClosedDate
            FROM Case
            WHERE Spam__c = true
              AND Case_Owner_Name__c = 'Spam Queue'
              AND ClosedDate < :cutoff
            ORDER BY ClosedDate
        ];
    }
}
