public interface WSU_SB_Interface_Object extends Database.Batchable<Object> {
    void preLoop(Database.BatchableContext bc, List<Object> sobjs);
    void prepLoopBody(Database.BatchableContext bc, Object obj);
    void setReserveForMainLoop(Database.BatchableContext bc, List<Object> objs);
    void mainLoopBody(Database.BatchableContext bc, Object obj);
    void setReserveForPostLoop(Database.BatchableContext bc, List<Object> objs);
    void postLoop(Database.BatchableContext bc, List<Object> objs);
    Map<String, Integer> reserve();
}
