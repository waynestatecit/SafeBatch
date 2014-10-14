// This file is part of SafeBatch, a Limit avoidance utility for Batch Apex on the Force.com platform.
//
// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

@isTest
public class WSU_SBTest {
    static {
        List<Database.SaveResult> results = Database.insert(
            new List<Contact>{
                new Contact(
                    LastName = 'ONETESTLAST1',
                    FirstName = 'FIRSWSUEST1',
                    Email = 'email@mail.com'
                )
            }
        );

        List<Contact> cons = new List<Contact>();
        for (Integer i = 0; i < 199; i++) {
            cons.add(
                new Contact(
                    LastName = 'TESTLAST' + String.valueOf(i),
                    FirstName = 'TESTFIRST' + String.valueOf(i),
                    Email = 'email' + String.valueOf(i) + '@mail.com'
                )
            );
        }
        results = Database.insert(cons);
    }

    static testMethod void testEnqueueBatchSObjectQL() {
        ID returned = WSU_SB.enqueueBatch(WSU_SB_Test_SObject_QL.class, null, null, null, false, false);
        WSU_SB.doCommit();
        System.assertEquals(WSU_Kyou.entries().size(), 1);
    }

    // Start section for SObject QueryLocator

    static testMethod void testEnqueueBatchNoArgs1() {
        if (WSU_Kyou.slotsAvailable() == 0) {
            throw new WSU_SB.SB_Exception('I need at least one open Batch Apex slot to run this test.');
        }
        Test.startTest();
        ID returned = WSU_SB.enqueueBatch(WSU_SB_Test_SObject_QL.class, null, null, null, true, false);
        Test.stopTest();

        Database.Batchable<sObject> impl = WSU_SB.latestImplementation;
        System.assert(impl instanceof WSU_SB_Test_SObject_QL);
        System.assertEquals(((WSU_SB_Test_SObject_QL)impl).getPassback(), null);
        List<Contact> cons = [select FirstName, LastName, Email from Contact];
        System.assertEquals(cons.size(), 200);
        Integer processed = 0;
        for (Contact con : cons) {
            if (con.Email == 'new@email.com') {
                processed++;
            }
        }
        System.assertEquals(processed, 200);
        List<WSU_Kyou_QueueEntry__c> entriesInDB = [select Id from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entriesInDB.size(), 0);
    }

    static testMethod void testEnqueueBatchNoArgs2() {
        if (WSU_Kyou.slotsAvailable() == 0) {
            throw new WSU_SB.SB_Exception('I need at least one open Batch Apex slot to run this test.');
        }
        Test.startTest();
        ID returned = WSU_SB.enqueueBatch(WSU_SB_Test_SObject_QL.class, null, null, null, true, false);
        Test.stopTest();

        List<Contact> cons = [select FirstName, LastName, Email from Contact];
        System.assertEquals(cons.size(), 200);
        Integer processed = 0;
        for (Contact con : cons) {
            if (con.Email == 'new@email.com') {
                processed++;
            }
        }
        System.assertEquals(processed, 200);
        List<WSU_Kyou_QueueEntry__c> entriesInDB = [select Id from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entriesInDB.size(), 0);
    }

    static testMethod void testEnqueueBatchNoArgsSObjectQLRecoverySetup() {
        if (WSU_Kyou.slotsAvailable() == 0) {
            throw new WSU_SB.SB_Exception('I need at least one open Batch Apex slot to run this test.');
        }
        Test.startTest();
        ID returned = WSU_SB.enqueueBatch(WSU_SB_Test_SObject_QL.class, null,
            new Map<String, Object>{
                'optionsData' => JSON.serialize(new Map<String, Object>{
                    'passback_value' => 'myownpassbackvalue',
                    'save_postloop_failure' => true // Inside WSU_SB_Test_SObject_QL, clears the Queries reservation
                })
            },
            new Map<String, Object>{
                'Queries' => 2  // This will make the loop stop at 199
            }, true, false
        );
        Test.stopTest();

        Database.Batchable<sObject> impl = WSU_SB.latestImplementation;
        System.assert(impl instanceof WSU_SB_Test_SObject_QL);
        System.assertEquals(((WSU_SB_Test_SObject_QL)impl).getPassback(), 'myownpassbackvalue');
        List<Contact> cons = [select FirstName, LastName, Email from Contact];
        System.assertEquals(cons.size(), 200);
        Integer processed = 0;
        for (Contact con : cons) {
            if (con.Email == 'new@email.com') {
                processed++;
            }
        }
        System.assertEquals(processed, 199);
        List<WSU_Kyou_QueueEntry__c> entriesInDB = [select Id from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entriesInDB.size(), 1);
    }

    static testMethod void testEnqueueBatchNoArgsSObjectQLRecoverySetup_1FailBeforePostLoop() {
        if (WSU_Kyou.slotsAvailable() == 0) {
            throw new WSU_SB.SB_Exception('I need at least one open Batch Apex slot to run this test.');
        }
        Boolean success = true;
        try {
            Test.startTest();
            ID returned = WSU_SB.enqueueBatch(WSU_SB_Test_SObject_QL.class, null, null, new Map<String, Object>{
                'Queries' => 1
            }, true, false);
            Test.stopTest();
        } catch (WSU_SB_Batchable.SB_BatchableException e) {
            success = false; // Fails because the check before postLoop requires a query be available, and it's not.
        }
        System.assert(!success);
    }

    static testMethod void testEnqueueBatchNoArgsSObjectQLRecoverySetup_1FailBeforePostLoop_2SaveBeforePostLoop() {
        if (WSU_Kyou.slotsAvailable() == 0) {
            throw new WSU_SB.SB_Exception('I need at least one open Batch Apex slot to run this test.');
        }
        Boolean success = true;
        Test.startTest();
        ID returned = WSU_SB.enqueueBatch(WSU_SB_Test_SObject_QL.class, null,
            new Map<String, Object>{
                'optionsData' => JSON.serialize(new Map<String, Object>{
                    'save_postloop_failure' => true // Inside WSU_SB_Test_SObject_QL, clears the Queries reservation
                })
            },
            new Map<String, Object>{
                'Queries' => 1
            }, true, false
        );
        Test.stopTest();

        List<Contact> cons = [select FirstName, LastName, Email from Contact];
        System.assertEquals(cons.size(), 200);
        Integer processed = 0;
        for (Contact con : cons) {
            if (con.Email == 'new@email.com') {
                processed++;
            }
        }
        System.assertEquals(processed, 200);
        List<WSU_Kyou_QueueEntry__c> entriesInDB = [select Id from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entriesInDB.size(), 0);
    }

    static testMethod void testEnqueueBatchNoArgsInfiniteRecoveryLoop() {
        if (WSU_Kyou.slotsAvailable() == 0) {
            throw new WSU_SB.SB_Exception('I need at least one open Batch Apex slot to run this test.');
        }
        Boolean success = true;
        try {
            Test.startTest();
            ID returned = WSU_SB.enqueueBatch(WSU_SB_Test_SObject_QL.class, null, null, new Map<String, Object>{
                'Queries' => 201,
                'one_loop' => true
            }, true, false);
            Test.stopTest();
        } catch (WSU_SB_Batchable.SB_BatchableException e) {
            success = false;
        }
        System.assert(!success);
    }

    static testMethod void testEnqueueBatchWithArgs() {
        if (WSU_Kyou.slotsAvailable() == 0) {
            throw new WSU_SB.SB_Exception('I need at least one open Batch Apex slot to run this test.');
        }
        Test.startTest();
        ID returned = WSU_SB.enqueueBatch(WSU_SB_Test_SObject_QL.class, null, new Map<String, Object>{
            'query' => 'select Id, LastName, FirstName, Email from Contact where Email like \'email1__@mail.com\''
        }, null, true, false);
        Test.stopTest();

        List<Contact> cons = [select FirstName, LastName, Email from Contact];
        System.assertEquals(cons.size(), 200);
        Integer processed = 0;
        for (Contact con : cons) {
            if (con.Email == 'new@email.com') {
                processed++;
            }
        }
        System.assertEquals(processed, 99);
        List<WSU_Kyou_QueueEntry__c> entriesInDB = [select Id from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entriesInDB.size(), 0);
    }

    static testMethod void testEnqueueBatchBadImplementation() {
        if (WSU_Kyou.slotsAvailable() == 0) {
            throw new WSU_SB.SB_Exception('I need at least one open Batch Apex slot to run this test.');
        }
        Boolean success = true;
        try {
            Test.startTest();
            ID returned = WSU_SB.enqueueBatch(WSU_SB_Test_Object_List.class, null, null, null, true, false);
            Test.stopTest();
        } catch (WSU_SB_Batchable.SB_BatchableException e) {
            success = false;
        }
        System.assert(!success);
    }

    static testMethod void testRecoverySObjectQL() {
        WSU_SB_Batchable_SObject_QL batchable = new WSU_SB_Batchable_SObject_QL(
            'WSU_SB_Test_SObject_QL', null, null
        );
        batchable.sobjsSkipped.addAll(
            (List<sObject>)[select Id from Contact]
        );
        batchable.queryFieldString = 'Id';
        batchable.querySObjectName = 'Contact';
        batchable.finish(null);
        List<WSU_Kyou_QueueEntry__c> entriesInDB = [select Id from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entriesInDB.size(), 1);

        Test.startTest();
        WSU_Kyou.run();
        Test.stopTest();

        List<Contact> cons = [select FirstName, LastName, Email from Contact];
        System.assertEquals(cons.size(), 200);
        Integer processed = 0;
        for (Contact con : cons) {
            if (con.Email == 'new@email.com') {
                processed++;
            }
        }
        System.assertEquals(processed, 200);
        entriesInDB = [select Id from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entriesInDB.size(), 0);
    }

    static testMethod void testRecoveryConstructor() {
        WSU_SB_Batchable_Recovery_SObject_QL batchable = new WSU_SB_Batchable_Recovery_SObject_QL(
            'WSU_SB_Test_SObject_QL', null, null
        );
    }

    static testMethod void testTestSObjectQLExecute() {
        Test.startTest();
        ID returned = WSU_Kyou.enqueueBatch(WSU_SB_Test_SObject_QL.class, null, null, null, true, false);
        Test.stopTest();

        List<Contact> cons = [select FirstName, LastName, Email from Contact];
        System.assertEquals(cons.size(), 200);
        Integer processed = 0;
        for (Contact con : cons) {
            if (con.Email == 'new@email.com') {
                processed++;
            }
        }
        System.assertEquals(processed, 200);
        List<WSU_Kyou_QueueEntry__c> entriesInDB = [select Id from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entriesInDB.size(), 0);
    }

    // End section for SObject QueryLocator

    // Start section for Object List

    static testMethod void testEnqueueBatchObjectListNoArgs1() {
        if (WSU_Kyou.slotsAvailable() == 0) {
            throw new WSU_SB.SB_Exception('I need at least one open Batch Apex slot to run this test.');
        }
        Test.startTest();
        ID returned = WSU_SB.enqueueBatch(WSU_SB_Test_Object_List.class, null, null, null, true, false, true);
        Test.stopTest();

        Database.Batchable<sObject> impl = WSU_SB.latestImplementation;
        System.assert(impl instanceof WSU_SB_Test_Object_List);

        System.assertEquals([select count() from Contact where Email = 'fake@fake.com'], 10); // I grab 10 in the test class

        List<WSU_Kyou_QueueEntry__c> entriesInDB = [select Id from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entriesInDB.size(), 0);
    }

    static testMethod void testRecoveryObjectList() {
        WSU_SB_Batchable_Object batchable = new WSU_SB_Batchable_Object(
            'WSU_SB_Test_Object_List', null, null
        );
        batchable.objsSkipped.addAll(
            (List<Object>)new List<Object>{
                (Object)new Map<String, Object>{
                    'one' => 1,
                    'two' => 2
                },
                3.14159,
                'fakerecovery@fake.com'
            }
        );
        batchable.finish(null);
        List<WSU_Kyou_QueueEntry__c> entriesInDB = [select Id from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entriesInDB.size(), 1);

        Test.startTest();
        WSU_Kyou.run();
        Test.stopTest();

        System.assertEquals([select count() from Contact where Email = 'fakerecovery@fake.com'], 10); // I grab 10 in the test class

        List<WSU_Kyou_QueueEntry__c> entriesInDB2 = [select Id from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entriesInDB2.size(), 0);
    }

    static testMethod void testEnqueueBatchBadImplementationObject() {
        if (WSU_Kyou.slotsAvailable() == 0) {
            throw new WSU_SB.SB_Exception('I need at least one open Batch Apex slot to run this test.');
        }
        Boolean success = true;
        try {
            Test.startTest();
            ID returned = WSU_SB.enqueueBatch(WSU_SB_Test_SObject_List.class, null, null, null, true, false, true);
            Test.stopTest();
        } catch (WSU_SB_Batchable.SB_BatchableException e) {
            success = false;
        }
        System.assert(!success);
    }

    static testMethod void testEnqueueBatchNoArgsInfiniteRecoveryLoopObjectList() {
        if (WSU_Kyou.slotsAvailable() == 0) {
            throw new WSU_SB.SB_Exception('I need at least one open Batch Apex slot to run this test.');
        }
        Boolean success = true;
        try {
            Test.startTest();
            ID returned = WSU_SB.enqueueBatch(WSU_SB_Test_Object_List.class, null, null, new Map<String, Object>{
                'Queries' => 201,
                'one_loop' => true
            }, true, false, true);
            Test.stopTest();
        } catch (WSU_SB_Batchable.SB_BatchableException e) {
            success = false;
            System.assertEquals(e.getMessage(), 'Infinite recovery loop detected - SafeBatch is unable to complete one Object before reaching Limit cutoff for ' + 'Queries' + ' .');
        }
        System.assert(!success);
    }

    static testMethod void testEnqueueBatchNoArgsObjectListRecoverySetupObjectList() {
        if (WSU_Kyou.slotsAvailable() == 0) {
            throw new WSU_SB.SB_Exception('I need at least one open Batch Apex slot to run this test.');
        }
        Test.startTest();
        ID returned = WSU_SB.enqueueBatch(WSU_SB_Test_Object_List.class, null,
            new Map<String, Object>{
                'optionsData' => JSON.serialize(new Map<String, Object>{
                    'passback_value' => 'myownpassbackvalue',
                    'save_postloop_failure' => true, // Inside WSU_SB_Test_SObject_List, clears the Queries reservation
                    'long' => true // Choose the long list of Strings as iterable
                })
            },
            new Map<String, Object>{
                'Queries' => 2  // This will make the loop stop after 198 Contacts, which is 199 queries (there's one in preLoop() too).
            }, true, false, true
        );
        Test.stopTest();

        Database.Batchable<Object> impl = WSU_SB.latestImplementationObject;
        System.assert(impl instanceof WSU_SB_Test_Object_List);
        System.assertEquals(((WSU_SB_Test_Object_List)impl).getPassback(), 'myownpassbackvalue');
        List<Contact> cons = [select FirstName, LastName, Email from Contact];
        System.assertEquals(cons.size(), 200);
        Integer processed = 0;
        for (Contact con : cons) {
            if (con.Email == 'fake@fake.com') {
                processed++;
            }
        }
        System.assertEquals(processed, 198);
        List<WSU_Kyou_QueueEntry__c> entriesInDB = [select Id from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entriesInDB.size(), 1);
    }

    static testMethod void testTestObjectListExecute() {
        Test.startTest();
        ID returned = WSU_Kyou.enqueueBatch(WSU_SB_Test_Object_List.class, null, null, null, true, false, false, true);
        Test.stopTest();

        System.assertEquals([select count() from Contact where Email = 'fake@fake.com'], 10); // I grab 10 in the test class

        List<WSU_Kyou_QueueEntry__c> entriesInDB = [select Id from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entriesInDB.size(), 0);
    }

    // Start section for SObject List

    static testMethod void testEnqueueBatchNoArgs1SObjectList() {
        if (WSU_Kyou.slotsAvailable() == 0) {
            throw new WSU_SB.SB_Exception('I need at least one open Batch Apex slot to run this test.');
        }
        Test.startTest();
        ID returned = WSU_SB.enqueueBatch(WSU_SB_Test_SObject_List.class, null, null, null, true, true);
        Test.stopTest();

        Database.Batchable<sObject> impl = WSU_SB.latestImplementation;
        System.assert(impl instanceof WSU_SB_Test_SObject_List);
        System.assertEquals(((WSU_SB_Test_SObject_List)impl).getPassback(), null);
        List<Contact> cons = [select FirstName, LastName, Email from Contact];
        System.assertEquals(cons.size(), 200);
        Integer processed = 0;
        for (Contact con : cons) {
            if (con.Email == 'new@email.com') {
                processed++;
            }
        }
        System.assertEquals(processed, 200);
        List<WSU_Kyou_QueueEntry__c> entriesInDB = [select Id from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entriesInDB.size(), 0);
    }

    static testMethod void testEnqueueBatchNoArgs2SObjectList() {
        if (WSU_Kyou.slotsAvailable() == 0) {
            throw new WSU_SB.SB_Exception('I need at least one open Batch Apex slot to run this test.');
        }
        Test.startTest();
        ID returned = WSU_SB.enqueueBatch(WSU_SB_Test_SObject_List.class, null, null, null, true, true);
        Test.stopTest();

        List<Contact> cons = [select FirstName, LastName, Email from Contact];
        System.assertEquals(cons.size(), 200);
        Integer processed = 0;
        for (Contact con : cons) {
            if (con.Email == 'new@email.com') {
                processed++;
            }
        }
        System.assertEquals(processed, 200);
        List<WSU_Kyou_QueueEntry__c> entriesInDB = [select Id from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entriesInDB.size(), 0);
    }

    static testMethod void testEnqueueBatchNoArgsSObjectQLRecoverySetupSObjectList() {
        if (WSU_Kyou.slotsAvailable() == 0) {
            throw new WSU_SB.SB_Exception('I need at least one open Batch Apex slot to run this test.');
        }
        Test.startTest();
        ID returned = WSU_SB.enqueueBatch(WSU_SB_Test_SObject_List.class, null,
            new Map<String, Object>{
                'optionsData' => JSON.serialize(new Map<String, Object>{
                    'passback_value' => 'myownpassbackvalue',
                    'save_postloop_failure' => true // Inside WSU_SB_Test_SObject_List, clears the Queries reservation
                })
            },
            new Map<String, Object>{
                'Queries' => 2  // This will make the loop stop at 199
            }, true, true
        );
        Test.stopTest();

        Database.Batchable<sObject> impl = WSU_SB.latestImplementation;
        System.assert(impl instanceof WSU_SB_Test_SObject_List);
        System.assertEquals(((WSU_SB_Test_SObject_List)impl).getPassback(), 'myownpassbackvalue');
        List<Contact> cons = [select FirstName, LastName, Email from Contact];
        System.assertEquals(cons.size(), 200);
        Integer processed = 0;
        for (Contact con : cons) {
            if (con.Email == 'new@email.com') {
                processed++;
            }
        }
        System.assertEquals(processed, 199);
        List<WSU_Kyou_QueueEntry__c> entriesInDB = [select Id from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entriesInDB.size(), 1);
    }

    static testMethod void testEnqueueBatchNoArgsSObjectQLRecoverySetup_1FailBeforePostLoopSObjectList() {
        if (WSU_Kyou.slotsAvailable() == 0) {
            throw new WSU_SB.SB_Exception('I need at least one open Batch Apex slot to run this test.');
        }
        Boolean success = true;
        try {
            Test.startTest();
            ID returned = WSU_SB.enqueueBatch(WSU_SB_Test_SObject_List.class, null, null, new Map<String, Object>{
                'Queries' => 1
            }, true, true);
            Test.stopTest();
        } catch (WSU_SB_Batchable.SB_BatchableException e) {
            success = false; // Fails because the check before postLoop requires a query be available, and it's not.
        }
        System.assert(!success);
    }

    static testMethod void testEnqueueBatchNoArgsSObjectQLRecoverySetup_2SaveBeforePostLoopSObjectList() {
        if (WSU_Kyou.slotsAvailable() == 0) {
            throw new WSU_SB.SB_Exception('I need at least one open Batch Apex slot to run this test.');
        }
        Boolean success = true;
        Test.startTest();
        ID returned = WSU_SB.enqueueBatch(WSU_SB_Test_SObject_List.class, null,
            new Map<String, Object>{
                'optionsData' => JSON.serialize(new Map<String, Object>{
                    'save_postloop_failure' => true // Inside WSU_SB_Test_SObject_List, clears the Queries reservation
                })
            },
            new Map<String, Object>{
                'Queries' => 1
            }, true, true
        );
        Test.stopTest();

        List<Contact> cons = [select FirstName, LastName, Email from Contact];
        System.assertEquals(cons.size(), 200);
        Integer processed = 0;
        for (Contact con : cons) {
            if (con.Email == 'new@email.com') {
                processed++;
            }
        }
        System.assertEquals(processed, 200);
        List<WSU_Kyou_QueueEntry__c> entriesInDB = [select Id from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entriesInDB.size(), 0);
    }

    static testMethod void testEnqueueBatchNoArgs4SObjectList() {
        if (WSU_Kyou.slotsAvailable() == 0) {
            throw new WSU_SB.SB_Exception('I need at least one open Batch Apex slot to run this test.');
        }
        Boolean success = true;
        try {
            Test.startTest();
            ID returned = WSU_SB.enqueueBatch(WSU_SB_Test_SObject_List.class, null, null, new Map<String, Object>{
                'Queries' => 201,
                'one_loop' => true
            }, true, true);
            Test.stopTest();
        } catch (WSU_SB_Batchable.SB_BatchableException e) {
            success = false;
        }
        System.assert(!success);
    }

    static testMethod void testEnqueueBatchWithArgsSObjectList() {
        if (WSU_Kyou.slotsAvailable() == 0) {
            throw new WSU_SB.SB_Exception('I need at least one open Batch Apex slot to run this test.');
        }
        Test.startTest();
        ID returned = WSU_SB.enqueueBatch(WSU_SB_Test_SObject_List.class, null, new Map<String, Object>{
            'query' => 'select Id, LastName, FirstName, Email from Contact where Email like \'email1__@mail.com\''
        }, null, true, true);
        Test.stopTest();

        List<Contact> cons = [select FirstName, LastName, Email from Contact];
        System.assertEquals(cons.size(), 200);
        Integer processed = 0;
        for (Contact con : cons) {
            if (con.Email == 'new@email.com') {
                processed++;
            }
        }
        System.assertEquals(processed, 99);
        List<WSU_Kyou_QueueEntry__c> entriesInDB = [select Id from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entriesInDB.size(), 0);
    }

    static testMethod void testRecoverySObjectList() {
        WSU_SB_Batchable_SObject_List batchable = new WSU_SB_Batchable_SObject_List(
            'WSU_SB_Test_SObject_List', null, null
        );
        batchable.sobjsSkipped.addAll(
            (List<sObject>)[select Id from Contact]
        );
        batchable.queryFieldString = 'Id';
        batchable.querySObjectName = 'Contact';
        batchable.finish(null);
        List<WSU_Kyou_QueueEntry__c> entriesInDB = [select Id from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entriesInDB.size(), 1);

        Test.startTest();
        WSU_Kyou.run();
        Test.stopTest();

        List<Contact> cons = [select FirstName, LastName, Email from Contact];
        System.assertEquals(cons.size(), 200);
        Integer processed = 0;
        for (Contact con : cons) {
            if (con.Email == 'new@email.com') {
                processed++;
            }
        }
        System.assertEquals(processed, 200);
        entriesInDB = [select Id from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entriesInDB.size(), 0);
    }

    static testMethod void testRecoveryConstructorSObjectList() {
        WSU_SB_Batchable_Recovery_SObject_List batchable = new WSU_SB_Batchable_Recovery_SObject_List(
            'WSU_SB_Test_SObject_List', null, null
        );
    }

    static testMethod void testTestSObjectListExecute() {
        Test.startTest();
        ID returned = WSU_Kyou.enqueueBatch(WSU_SB_Test_SObject_List.class, null, null, null, true, false, true);
        Test.stopTest();

        List<Contact> cons = [select FirstName, LastName, Email from Contact];
        System.assertEquals(cons.size(), 200);
        Integer processed = 0;
        for (Contact con : cons) {
            if (con.Email == 'new@email.com') {
                processed++;
            }
        }
        System.assertEquals(processed, 200);
        List<WSU_Kyou_QueueEntry__c> entriesInDB = [select Id from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entriesInDB.size(), 0);
    }

    static testMethod void testSObjectListTestSObjFieldMapToQueryFields() {
        Account acct = new Account(
            Name = 'TestAccount'
        );
        Database.SaveResult result = Database.Insert(acct);
        Contact con = new Contact(
            FirstName = 'TestFirst',
            LastName = 'TestLast',
            Account = acct
        );
        result = Database.Insert(con);

        String queryFields = WSU_SB_Batchable_SObject_List.sobjFieldMapToQueryFields(WSU_Util.getFieldNames(con));

        Set<String> fields = new Set<String>(queryFields.split(','));
        System.assert(fields.remove('FirstName'));
        System.assert(fields.remove('LastName'));
        System.assert(fields.remove('Id'));
        System.assert(fields.remove('Account.Id'));
        System.assert(fields.remove('Account.Name'));
        System.assert(fields.isEmpty());
    }

    // End section for SObject List

}
