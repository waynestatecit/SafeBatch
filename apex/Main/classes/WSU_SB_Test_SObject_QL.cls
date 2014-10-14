// This file is part of SafeBatch, a Limit avoidance utility for Batch Apex on the Force.com platform.
//
// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

public class WSU_SB_Test_SObject_QL implements WSU_SB_Interface_SObject, Database.Stateful, Database.AllowsCallouts {
    public static String passback;

    static {
        staticInit();
    }

    private Map<String, Integer> reserved;
    public String query {
        private get;
        protected set {
            query = value;
            init();
        }
    }

    private Map<String, Object> options;
    public String optionsData {
        private get;
        protected set {
            optionsData = value;
            options = (Map<String, Object>)JSON.deserializeUntyped(optionsData);
            init();
        }
    }
    private static Boolean staticInitRun;
    private static void staticInit() {
        if (staticInitRun == null || !staticInitRun) {
            staticInitRun = true;
        }
    }
    private Boolean initRun;
    private void init() {
        if (initRun == null || !initRun) {
            cons = new List<sObject>();
            reserved = new Map<String, Integer>();
            initRun = true;
        }
    }

    private List<sObject> cons;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (query == null) {
            query = 'select Id, LastName, FirstName, Email from Contact';
        }
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<sObject> sobjs) {
        preLoop(bc, sobjs);
        for (sObject sobj : sobjs) {
            mainLoopBody(bc, sobj);
        }
        postLoop(bc, sobjs);
    }

    public void preLoop(Database.BatchableContext bc, List<sObject> sobjs) {
        cons.clear();
    }

    public void prepLoopBody(Database.BatchableContext bc, sObject sobj) {
    }

    public void setReserveForMainLoop(Database.BatchableContext bc, List<sObject> sobjs) {
    }

    public void mainLoopBody(Database.BatchableContext bc, sObject sobj) {
        List<Account> accts = [select Id from Account];
        Contact con = (Contact)sobj;
        con.Email = 'new@email.com';
        cons.add(con);
    }

    public void setReserveForPostLoop(Database.BatchableContext bc, List<sObject> sobjs) {
        reserved.put('DMLStatements', 1);
        if (options != null) {
            if(options.containsKey('save_postloop_failure')) {
                reserved.put('Queries', null);
            }
            if(options.containsKey('change_queries_reservation')) {
                reserved.put('Queries', (Integer)options.get('change_queries_reservation'));
            }
        }
    }

    public void postLoop(Database.BatchableContext bc, List<sObject> sobjs) {
        update cons;
    }

    public Map<String, Integer> reserve() {
        return reserved;
    }

    public String getPassback() {
        return passback;
    }

    public void finish(Database.BatchableContext bc) {
        if (options != null && options.containsKey('passback_value')) {
            passback = (String)options.get('passback_value');
        }
    }
}
