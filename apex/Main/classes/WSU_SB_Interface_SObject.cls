public interface WSU_SB_Interface_SObject extends Database.Batchable<sObject> {
    void preLoop(Database.BatchableContext bc, List<sObject> sobjs);
    void prepLoopBody(Database.BatchableContext bc, sObject sobj);
    void setReserveForMainLoop(Database.BatchableContext bc, List<sObject> sobjs);
    void mainLoopBody(Database.BatchableContext bc, sObject sobj);
    void setReserveForPostLoop(Database.BatchableContext bc, List<sObject> sobjs);
    void postLoop(Database.BatchableContext bc, List<sObject> sobjs);
    Map<String, Integer> reserve();
}
