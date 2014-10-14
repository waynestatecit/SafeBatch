// This file is part of SafeBatch, a Limit avoidance utility for Batch Apex on the Force.com platform.
//
// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

public class WSU_SB_Batchable_Recovery_SObject_QL extends WSU_SB_Batchable_SObject_QL {
    private String sobjName;
    private String fields;
    private List<ID> ids;

    private String safeBatchData {
        private get;
        private set {
            Map<String, Object> safeBatch = (Map<String, Object>)JSON.deserializeUntyped(value);
            optionsData = JSON.serialize((Map<String, Object>)safeBatch.get('options'));
            implementationType = Type.forName((String)safeBatch.get('class'));
            sobjName = (String)safeBatch.get('sobject');
            fields = (String)safeBatch.get('fields');
            if (ids == null) {
                ids = new List<ID>();
            }
            for (Object idObj : (List<Object>)safeBatch.get('ids')) {
                ids.add((ID)idObj);
            }
            init();
        }
    }

    public WSU_SB_Batchable_Recovery_SObject_QL() {
        init();
    }

    public WSU_SB_Batchable_Recovery_SObject_QL(String implementationType, Map<String, Object> implementationArgs, Map<String, Object> options) {
        super(implementationType, implementationArgs, options);
    }

    public override Database.QueryLocator start(Database.BatchableContext bc) {
        Database.QueryLocator ql = super.start(bc); // Call this in case it sets up stuff, but ignore returned scope
        List<WSU_SB_Scope__c> scopes = [select Data__c from WSU_SB_Scope__c where Id in :ids];
        List<ID> sobjIds = new List<ID>();
        for (WSU_SB_Scope__c scope : scopes) {
            sobjIds.addAll((List<ID>)JSON.deserialize(scope.Data__c, List<ID>.class));
        }
        Database.QueryLocator newql = Database.getQueryLocator('select {fields} from {sobjName} where Id in :sobjIds'
            .replace('{fields}', fields)
            .replace('{sobjName}', sobjName)
        );
        List<Database.DeleteResult> results = Database.Delete(scopes);
        return newql;
    }

    public class SB_Batchable_Recovery_SObject_QLException extends Exception {}
}
