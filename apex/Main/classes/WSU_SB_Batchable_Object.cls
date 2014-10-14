// This file is part of SafeBatch, a Limit avoidance utility for Batch Apex on the Force.com platform.
//
// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

public virtual class WSU_SB_Batchable_Object extends WSU_SB_Batchable implements Database.Batchable<Object>, Database.Stateful, Database.AllowsCallouts {
    @TestVisible
    private List<Object> objsSkipped;

    protected override void init() {
        if (initRun == null || !initRun) {
            objsSkipped = new List<Object>();
            initRun = true;
        }
        super.init();
    }

    public WSU_SB_Batchable_Object(String implementationName, Map<String, Object> implementationArgs, Map<String, Object> options) {
        super(implementationName, implementationArgs, options);
    }

    public WSU_SB_Batchable_Object() {
        super();
    }

    public override void setImplementation() {
        if (implementationType != null) { // We might run this method more than once because it gets called from init()
            if (implementationType.newInstance() instanceof WSU_SB_Interface_Object) {
                if (implementationArgs == null) {
                    this.implementationObject = (WSU_SB_Interface_Object)implementationType.newInstance();
                } else {
                    this.implementationObject = (WSU_SB_Interface_Object)JSON.deserialize(JSON.serialize(implementationArgs), implementationType);
                }
            } else {
                throw new SB_BatchableException('Implementation is not of type WSU_SB_Interface_Object.');
            }
        }
    }

    protected override String limitCheck() {
        reserved = implementationObject.reserve();
        return super.limitCheck();
    }

    public virtual List<Object> start(Database.BatchableContext bc) {
        return (List<Object>)implementationObject.start(bc);
    }

    public void execute(Database.BatchableContext bc, List<Object> objs) {
        implementationObject.preLoop(bc, objs);

        if (!options.containsKey('one_loop') || !(Boolean)options.get('one_loop')) {
            for (Integer i = 0; i < objs.size(); i++) {
                Object obj = objs.get(i);
                String checkResult = limitCheck();
                if (checkResult == null) {
                    implementationObject.prepLoopBody(bc, obj);
                } else {
                    throw new SB_BatchableException('Limit for ' + checkResult + ' encountered in first loop.');
                }
            }
        }

        implementationObject.setReserveForMainLoop(bc, objs);

        for (Integer i = 0; i < objs.size(); i++) {
            Object obj = objs.get(i);
            String checkResult = limitCheck();
            if (checkResult == null) {
                implementationObject.mainLoopBody(bc, obj);
            } else {
                if (i == 0) {
                    throw new SB_BatchableException('Infinite recovery loop detected - SafeBatch is unable to complete one Object before reaching Limit cutoff for ' + checkResult + ' .');
                }
                for (Integer j = i; j < objs.size(); j++) {
                    objsSkipped.add(objs.get(j));
                }
                break;
            }
        }

        implementationObject.setReserveForPostLoop(bc, objs);

        String checkResult = limitCheck();
        if (checkResult == null) {
            implementationObject.postLoop(bc, objs);
        } else {
            throw new SB_BatchableException('postLoop() blocked - SafeBatch detects a limit problem for ' + checkResult + ' before postLoop().');
        }
    }

    public void finish(Database.BatchableContext bc) {
        if (objsSkipped.size() > 0) {
            // Reschedule the rest with Kyou!
            WSU_Kyou.enqueueBatch(WSU_SB_Batchable_Recovery_Object.class, null, new Map<String, Object>{
                'safeBatchData' => JSON.serialize(new Map<String, Object>{
                    'class' => implementationType.getName(),
                    'objects' => objsSkipped,
                    'options' => options
                }),
                'implementationArgsData' => JSON.serialize(implementationArgs)
            }, (ID)null, false, false, false, true);
            WSU_Kyou.doCommit();
        }
        implementationObject.finish(bc);
    }
}
