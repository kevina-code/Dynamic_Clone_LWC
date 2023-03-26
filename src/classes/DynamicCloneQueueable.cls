/**
 * Author       : Kevin Antonioli (braveitnow@pm.me)
 * Description  : Queueable apex class to leverage when:
 *                the number of records to clone is high enough to cause a CPU timeout synchronously.
 *                This raises the CPU time limit from 10 to 60 seconds.
 * Created      : 03.25.2023
 *
 * Revisions:
 * Date : Name : Notes
 */
public without sharing class DynamicCloneQueueable implements Queueable {
  private List<SObject> clonesToInsert;

  // Constructor:
  public DynamicCloneQueueable(List<SObject> clonesToInsertParam) {
    this.clonesToInsert = clonesToInsertParam;
  }

  /**
   * @description: clone records in an async context
   * @param     QueueableContext context
   * @return    void
   */
  public void execute(QueueableContext context) {
    try {
      insert clonesToInsert;
    } catch (Exception ex) {
      String exceptionMessage =
        'AsyncOrderingQueueable.execute() exception: ' +
        ex.getMessage() +
        ' Stack trace: ' +
        ex.getStackTraceString();
      System.debug(exceptionMessage);
    }
  }
}