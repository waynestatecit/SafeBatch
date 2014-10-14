// This file is part of SafeBatch, a Limit avoidance utility for Batch Apex on the Force.com platform.
//
// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

public virtual class WSU_SB_Batchable_SObject extends WSU_SB_Batchable {
    @TestVisible
    protected List<sObject> sobjsSkipped;

    protected override void init() {
        if (initRun == null || !initRun) {
            sobjsSkipped = new List<sObject>();
            initRun = true;
        }
        super.init();
    }

    public WSU_SB_Batchable_SObject(String implementationName, Map<String, Object> implementationArgs, Map<String, Object> options) {
        super(implementationName, implementationArgs, options);
    }

    public WSU_SB_Batchable_SObject() {
        super();
    }

    public override void setImplementation() {
        if (implementationType != null) { // We might run this method more than once because it gets called from init()
            if (implementationType.newInstance() instanceof WSU_SB_Interface_SObject) {
                if (implementationArgs == null) {
                    this.implementation = (WSU_SB_Interface_SObject)implementationType.newInstance();
                } else {
                    this.implementation = (WSU_SB_Interface_SObject)JSON.deserialize(JSON.serialize(implementationArgs), implementationType);
                }
            } else {
                throw new SB_BatchableException('Implementation is not of type WSU_SB_Interface_SObject.');
            }
        }
    }

    protected override String limitCheck() {
        reserved = implementation.reserve();
        return super.limitCheck();
    }

    public void execute(Database.BatchableContext bc, List<sObject> sobjs) {
        implementation.preLoop(bc, sobjs);

        if (!options.containsKey('one_loop') || !(Boolean)options.get('one_loop')) {
            for (Integer i = 0; i < sobjs.size(); i++) {
                sObject sobj = sobjs.get(i);
                String checkResult = limitCheck();
                if (checkResult == null) {
                    implementation.prepLoopBody(bc, sobj);
                } else {
                    throw new SB_BatchableException('Limit for ' + checkResult + ' encountered in first loop.');
                }
            }
        }

        implementation.setReserveForMainLoop(bc, sobjs);

        for (Integer i = 0; i < sobjs.size(); i++) {
            sObject sobj = sobjs.get(i);
            String checkResult = limitCheck();
            if (checkResult == null) {
                implementation.mainLoopBody(bc, sobj);
            } else {
                if (i == 0) {
                    throw new SB_BatchableException('Infinite recovery loop detected - SafeBatch is unable to complete one sObject before reaching Limit cutoff for ' + checkResult + ' .');
                }
                for (Integer j = i; j < sobjs.size(); j++) {
                    sobjsSkipped.add(sobjs.get(j));
                }
                break;
            }
        }

        implementation.setReserveForPostLoop(bc, sobjs);

        String checkResult = limitCheck();
        if (checkResult == null) {
            implementation.postLoop(bc, sobjs);
        } else {
            throw new SB_BatchableException('postLoop() blocked - SafeBatch detects a limit problem for ' + checkResult + ' before postLoop().');
        }
    }
}
