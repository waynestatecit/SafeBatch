// This file is part of SafeBatch, a Limit avoidance utility for Batch Apex on the Force.com platform.
//
// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

public class WSU_SB {
    public static Database.Batchable<sObject> latestImplementation = null;
    public static Database.Batchable<Object> latestImplementationObject = null;

    public static ID enqueueBatch(Type batchable, Map<String, Object> args, Map<String, Object> options, Boolean tryNow) {
        return enqueueBatch(batchable, null, args, options, tryNow, false, false);
    }

    public static ID enqueueBatch(Type batchable, Integer batchSize, Map<String, Object> args, Map<String, Object> options, Boolean tryNow, Boolean startReturnsList) {
        return enqueueBatch(batchable, batchSize, args, options, tryNow, startReturnsList, false);
    }

    public static ID enqueueBatch(Type batchable, Integer batchSize, Map<String, Object> args, Map<String, Object> options, Boolean tryNow, Boolean startReturnsList, Boolean startReturnsObjectList) {
        Type sbBatchableType = null;
        if (startReturnsObjectList) {
            sbBatchableType = WSU_SB_Batchable_Object.class;
        } else {
            if (startReturnsList) {
                sbBatchableType = WSU_SB_Batchable_SObject_List.class;
            } else {
                sbBatchableType = WSU_SB_Batchable_SObject_QL.class;
            }
        }

        ID toReturn = WSU_Kyou.enqueueBatch(sbBatchableType, null, new Map<String, Object>{
            'safeBatchData' => JSON.serialize(new Map<String, Object>{
                'class' => batchable.getName(),
                'options' => options
            }),
            'implementationArgsData' => JSON.serialize(args)
        }, (Integer)null, tryNow, false, startReturnsList, startReturnsObjectList);

        if (startReturnsObjectList) {
            if (WSU_Kyou.latestImplementationObject != null) {
                latestImplementationObject = ((WSU_SB_Batchable_Object)WSU_Kyou.latestImplementationObject).implementationObject;
            } else {
                latestImplementationObject = null;
            }
        } else {
            if (WSU_Kyou.latestImplementation != null) {
                latestImplementation = ((WSU_SB_Batchable_SObject)WSU_Kyou.latestImplementation).implementation;
            } else {
                latestImplementation = null;
            }
        }

        return toReturn;
    }

    public static void doCommit() {
        WSU_Kyou.doCommit();
    }

    public class SB_Exception extends Exception {}
}
