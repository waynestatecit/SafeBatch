// This file is part of SafeBatch, a Limit avoidance utility for Batch Apex on the Force.com platform.
//
// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

public class WSU_SB_Batchable_Recovery_Object extends WSU_SB_Batchable_Object {
    private String sobjName;
    private String fields;
    private List<Object> objs;

    private String safeBatchData {
        private get;
        private set {
            Map<String, Object> safeBatch = (Map<String, Object>)JSON.deserializeUntyped(value);
            optionsData = JSON.serialize((Map<String, Object>)safeBatch.get('options'));
            implementationType = Type.forName((String)safeBatch.get('class'));
            objs = (List<Object>)safeBatch.get('objects');
            init();
        }
    }

    public WSU_SB_Batchable_Recovery_Object() {
        init();
    }

    public WSU_SB_Batchable_Recovery_Object(String implementationType, Map<String, Object> implementationArgs, Map<String, Object> options) {
        super(implementationType, implementationArgs, options);
    }

    public override List<Object> start(Database.BatchableContext bc) {
        return objs;
    }
}
