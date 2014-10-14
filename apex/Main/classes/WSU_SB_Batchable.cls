// This file is part of SafeBatch, a Limit avoidance utility for Batch Apex on the Force.com platform.
//
// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

public virtual class WSU_SB_Batchable {
    public WSU_SB_Interface_SObject implementation;
    public WSU_SB_Interface_Object implementationObject;
    protected Type implementationType;
    protected Map<String, Object> implementationArgs;
    protected Map<String, Integer> reserved;

    @TestVisible
    protected String queryFieldString;
    @TestVisible
    protected String querySObjectName;

    protected Boolean initRun;

    public String safeBatchData {
        private get;
        protected set {
            Map<String, Object> safeBatch = (Map<String, Object>)JSON.deserializeUntyped(value);
            optionsData = JSON.serialize((Map<String, Object>)safeBatch.get('options'));
            implementationType = Type.forName((String)safeBatch.get('class'));
            init();
        }
    }

    public Map<String, Object> options;
    public String optionsData {
        protected get;
        protected set {
            options = (Map<String, Object>)JSON.deserializeUntyped(value);
            if (options == null) {
                options = new Map<String, Object>();
            }
            init();
        }
    }

    public String implementationArgsData {
        private get;
        protected set {
            this.implementationArgs = (Map<String, Object>)JSON.deserializeUntyped(value);
            init();
        }
    }

    protected virtual void init() {
        // Subclasses do the initRun checking now, as they handle different instance variables
        setImplementation();
    }

    public WSU_SB_Batchable(String implementationName, Map<String, Object> implementationArgs, Map<String, Object> options) {
        this.optionsData = JSON.serialize(options);
        implementationType = Type.forName(implementationName);
        this.implementationArgs = implementationArgs;
        init();
    }

    public WSU_SB_Batchable() {
        init();
    }

    public virtual void setImplementation() {
    }

    private Integer tripLimit(String limitName) {
        if (reserved != null && reserved.containsKey(limitName)) {
            if (reserved.get(limitName) == null) { // Override options
                return 0;
            } else {
                return (Integer)reserved.get(limitName);
            }
        } else {
            return options.containsKey(limitName) ? (Integer)options.get(limitName) : 0;
        }
    }

    protected virtual String limitCheck() {
        // Subclasses will set reserved
        if (Limits.getQueries() > Limits.getLimitQueries() - tripLimit('Queries')) {
            return 'Queries';
        } else if (Limits.getQueryRows() > Limits.getLimitQueryRows() - tripLimit('QueryRows')) {
            return 'QueryRows';
        } else if (Limits.getCallouts() > Limits.getLimitCallouts() - tripLimit('Callouts')) {
            return 'Callouts';
        } else if (Limits.getDMLStatements() > Limits.getLimitDMLStatements() - tripLimit('DMLStatements')) {
            return 'DMLStatements';
        } else if (Limits.getDMLRows() > Limits.getLimitDMLRows() - tripLimit('DMLRows')) {
            return 'DMLRows';
        } else if (Limits.getHeapSize() > Limits.getLimitHeapSize() - tripLimit('HeapSize')) {
            return 'HeapSize';
        } else {
            return null;
        }
    }

    public class SB_BatchableException extends Exception {}
}
