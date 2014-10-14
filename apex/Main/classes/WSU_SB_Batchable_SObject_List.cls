// This file is part of SafeBatch, a Limit avoidance utility for Batch Apex on the Force.com platform.
//
// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

public virtual class WSU_SB_Batchable_SObject_List extends WSU_SB_Batchable_SObject implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    public WSU_SB_Batchable_SObject_List(String implementationName, Map<String, Object> implementationArgs, Map<String, Object> options) {
        super(implementationName, implementationArgs, options);
    }

    public WSU_SB_Batchable_SObject_List() {
        super();
    }

    @TestVisible
    private static String sobjFieldMapToQueryFields(Map<String, Object> sobjFieldMap) {
        // This could probably be recursive + String.join(), but oh well.
        String toReturn = '';
        for (String sobjFieldKey : sobjFieldMap.keySet()) {
            Object sobjFieldValue = sobjFieldMap.get(sobjFieldKey);
            if (sobjFieldValue == null) {
                toReturn += sobjFieldKey + ',';
            } else {
                List<String> relatedFields = new List<String>();
                // Yeah, split() then join()...
                for(String relatedField : sobjFieldMapToQueryFields((Map<String, Object>)sobjFieldValue).split(',')) {
                    relatedFields.add(sobjFieldKey + '.' + relatedField);
                }
                toReturn += String.join(relatedFields, ',') + ',';
            }
        }
        return toReturn.substring(0, toReturn.length() - 1); // Strip off last comma
    }

    public virtual List<sObject> start(Database.BatchableContext bc) {
        List<sObject> toReturn = (List<sObject>)implementation.start(bc);
        if (toReturn.size() > 0) {
            querySObjectName = String.valueOf(toReturn.get(0).getSObjectType());
            Map<String, Object> sobjFieldMap = WSU_Util.getFieldNames(toReturn.get(0));
            queryFieldString = sobjFieldMapToQueryFields(sobjFieldMap);
        }

        return toReturn;
    }

    public void finish(Database.BatchableContext bc) {
        if (sobjsSkipped.size() > 0) {
            List<ID> skippedIds = new List<ID>();
            for (sObject sobj : sobjsSkipped) {
                skippedIds.add(sobj.Id);
            }
            Database.SaveResult result = Database.insert( // FIXME: check for length in Data__c and make more if needed
                new WSU_SB_Scope__c(
                    Data__c = JSON.serialize(skippedIds)
                )
            );
            // Reschedule the rest with Kyou!
            WSU_Kyou.enqueueBatch(WSU_SB_Batchable_Recovery_SObject_List.class, null, new Map<String, Object>{
                'safeBatchData' => JSON.serialize(new Map<String, Object>{
                    'class' => implementationType.getName(),
                    'sobject' => querySObjectName,
                    'fields' => queryFieldString,
                    'ids' => new List<ID>{result.getId()},
                    'options' => options
                }),
                'implementationArgsData' => JSON.serialize(implementationArgs)
            }, (ID)null, false, false, true);
            WSU_Kyou.doCommit();
        }
        implementation.finish(bc);
    }
}
