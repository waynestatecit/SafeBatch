// This file is part of SafeBatch, a Limit avoidance utility for Batch Apex on the Force.com platform.
//
// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

public class WSU_SB_Test_Object_List implements WSU_SB_Interface_Object, Database.Stateful, Database.AllowsCallouts {
    public static String passback;

    static {
        staticInit();
    }

    public WSU_SB_Test_Object_List() {
        init();
    }

    private Map<String, Integer> reserved;

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
            counter = 0;
            reserved = new Map<String, Integer>();
            initRun = true;
        }
    }

    private List<sObject> cons;
    private Integer counter;

    public List<Object> start(Database.BatchableContext bc) {
        if (options != null && options.containsKey('long') && (Boolean)options.get('long')) {
            List<Object> toReturn = new List<Object>();
            for (Integer i = 0; i < 200; i++) {
                toReturn.add('fake@fake.com');
            }
            return toReturn;
        } else {
            return new List<Object>{
                (Object)new Map<String, Object>{
                    'one' => 1,
                    'two' => 2
                },
                3.14159,
                'fake@fake.com'
            };
        }
    }

    public void execute(Database.BatchableContext bc, List<Object> objs) {
        preLoop(bc, objs);
        for (Object obj : objs) {
            mainLoopBody(bc, obj);
        }
        postLoop(bc, objs);
    }

    public void preLoop(Database.BatchableContext bc, List<Object> objs) {
        cons.clear();
        if (options != null && options.containsKey('long') && (Boolean)options.get('long')) {
            cons = [select Id, Email from Contact];
        }
    }

    public void prepLoopBody(Database.BatchableContext bc, Object obj) {
    }

    public void setReserveForMainLoop(Database.BatchableContext bc, List<Object> objs) {
    }

    public void mainLoopBody(Database.BatchableContext bc, Object obj) {
        List<Account> accts = [select Id from Account];
        if (options != null && options.containsKey('long') && (Boolean)options.get('long')) {
            (cons.get(counter)).put('Email', (String)obj);
            counter += 1;
        } else {
            if (obj instanceof String) {
                List<Contact> tenCons = [select Id, Email from Contact limit 10];
                for (Contact con : tenCons) {
                    con.Email = (String)obj;
                    cons.add(con);
                }
            }
        }
    }

    public void setReserveForPostLoop(Database.BatchableContext bc, List<Object> objs) {
        reserved.put('DMLStatements', 1);
        if (options != null) {
            if(options.containsKey('save_postloop_failure')) {
                reserved.put('Queries', null);
            }
        }
    }

    public void postLoop(Database.BatchableContext bc, List<Object> objs) {
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
