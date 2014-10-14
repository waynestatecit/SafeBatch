// This file is part of SafeBatch, a Limit avoidance utility for Batch Apex on the Force.com platform.
//
// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

public virtual class WSU_SB_Batchable_SObject_QL extends WSU_SB_Batchable_SObject implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    public WSU_SB_Batchable_SObject_QL(String implementationName, Map<String, Object> implementationArgs, Map<String, Object> options) {
        super(implementationName, implementationArgs, options);
    }

    public WSU_SB_Batchable_SObject_QL() {
        super();
    }

    public virtual Database.QueryLocator start(Database.BatchableContext bc) {
        Database.QueryLocator ql = (Database.QueryLocator)implementation.start(bc);
        Pattern patt = Pattern.compile('\\s*select\\s+(.+?)\\s+from\\s+(\\S+).*');
        Matcher match = patt.matcher(ql.getQuery());
        if (match.matches() && match.groupCount() == 2) {
            queryFieldString = match.group(1);
            querySObjectName = match.group(2);
        } else {
            throw new SB_BatchableException('Regex fails on query ' + ql.getQuery() + '.');
        }
        return ql;
    }

    public void finish(Database.BatchableContext bc) {
        if (sobjsSkipped.size() > 0) {
            List<List<ID>> skippedIds = new List<List<ID>>{new List<ID>()};
            for (sObject sobj : sobjsSkipped) {
                // Each ID here is 18 characters.  Add in the two double quotes and the comma OR closing right square bracket, and we use at least 21 characters per ID we add in once the List<ID> is serialized into JSON.
                // The maximum number of IDs we can put in a List<ID> if it's going to fit in a SB_Scope Data__c field (max length 32768) is Math.floor(32786.0/21.0).
                if (skippedIds.get(skippedIds.size() - 1).size() == Math.floor(32768.0 / 21.0)) {
                    skippedIds.add(new List<ID>());
                }
                skippedIds.get(skippedIds.size() - 1).add(sobj.Id);
            }

            List<WSU_SB_Scope__c> scopes = new List<WSU_SB_Scope__c>();
            for (List<ID> oneScopeList : skippedIds) {
                scopes.add(
                    new WSU_SB_Scope__c(
                        Data__c = JSON.serialize(oneScopeList)
                    )
                );
            }
            
            List<Database.SaveResult> results = Database.Insert(scopes);
            List<ID> scopeIds = new List<ID>();
            for (Database.SaveResult result : results) {
                scopeIds.add(result.getId());
            }
            // Reschedule the rest with Kyou!
            WSU_Kyou.enqueueBatch(WSU_SB_Batchable_Recovery_SObject_QL.class, null, new Map<String, Object>{
                'safeBatchData' => JSON.serialize(new Map<String, Object>{
                    'class' => implementationType.getName(),
                    'sobject' => querySObjectName,
                    'fields' => queryFieldString,
                    'ids' => scopeIds,
                    'options' => options
                }),
                'implementationArgsData' => JSON.serialize(implementationArgs)
            }, (ID)null, false);
            WSU_Kyou.doCommit();
        }
        implementation.finish(bc);
    }
}
