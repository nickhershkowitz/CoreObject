/*
	Copyright (C) 2013 Eric Wasylishen

	Date:  December 2013
	License:  MIT  (see COPYING)
 */

#import <UnitKit/UnitKit.h>
#import <Foundation/Foundation.h>
#import "TestCommon.h"

@interface TestUnorderedRelationship : NSObject <UKTest>
@end

@implementation TestUnorderedRelationship

/**
 * Test that an object graph of UnorderedGroupNoOpposite can be reloaded in another
 * context. Test that one OutlineItem can be in two UnorderedGroupNoOpposite's.
 */
- (void) testUnorderedGroupNoOpposite
{
	COObjectGraphContext *ctx = [COObjectGraphContext new];
	UnorderedGroupNoOpposite *group1 = [ctx insertObjectWithEntityName: @"UnorderedGroupNoOpposite"];
	UnorderedGroupNoOpposite *group2 = [ctx insertObjectWithEntityName: @"UnorderedGroupNoOpposite"];
	OutlineItem *item1 = [ctx insertObjectWithEntityName: @"OutlineItem"];
	OutlineItem *item2 = [ctx insertObjectWithEntityName: @"OutlineItem"];
	
	group1.contents = S(item1, item2);
	group2.contents = S(item1);
	
	COObjectGraphContext *ctx2 = [COObjectGraphContext new];
	[ctx2 setItemGraph: ctx];
	
	UnorderedGroupNoOpposite *group1ctx2 = [ctx2 loadedObjectForUUID: [group1 UUID]];
	UnorderedGroupNoOpposite *group2ctx2 = [ctx2 loadedObjectForUUID: [group2 UUID]];
	OutlineItem *item1ctx2 = [ctx2 loadedObjectForUUID: [item1 UUID]];
	OutlineItem *item2ctx2 = [ctx2 loadedObjectForUUID: [item2 UUID]];
	
	UKObjectsEqual(S(item1ctx2, item2ctx2), [group1ctx2 contents]);
	UKObjectsEqual(S(item1ctx2), [group2ctx2 contents]);
}

- (void) testUnorderedGroupNoOppositeOuterReference
{
	COObjectGraphContext *ctx1 = [COObjectGraphContext new];
	COObjectGraphContext *ctx2 = [COObjectGraphContext new];
	
	UnorderedGroupNoOpposite *group1 = [ctx1 insertObjectWithEntityName: @"UnorderedGroupNoOpposite"];
	OutlineItem *item1 = [ctx2 insertObjectWithEntityName: @"OutlineItem"];
	
	group1.contents = S(item1);
	
	// Check that the relationship cache knows the inverse relationship, even though it is
	// not used in the metamodel (non-public API)
	UKObjectsEqual(S(group1), [item1 referringObjects]);

	[ctx1 discardAllChanges];
	
	UKTrue([[item1 referringObjects] isEmpty]);
}

- (void) testRetainCycleMemoryLeakWithUserSuppliedSet
{
	const NSUInteger deallocsBefore = [UnorderedGroupNoOpposite countOfDeallocCalls];
	
	@autoreleasepool
	{
		COObjectGraphContext *ctx = [COObjectGraphContext new];
		UnorderedGroupNoOpposite *group1 = [ctx insertObjectWithEntityName: @"UnorderedGroupNoOpposite"];
		UnorderedGroupNoOpposite *group2 = [ctx insertObjectWithEntityName: @"UnorderedGroupNoOpposite"];
		group1.contents = S(group2);
		group2.contents = S(group1);
	}

	const NSUInteger deallocs = [UnorderedGroupNoOpposite countOfDeallocCalls] - deallocsBefore;
	UKIntsEqual(2, deallocs);
}

- (void) testRetainCycleMemoryLeakWithFrameworkSuppliedSet
{
	COObjectGraphContext *ctx = [COObjectGraphContext new];
	UnorderedGroupNoOpposite *group1 = [ctx insertObjectWithEntityName: @"UnorderedGroupNoOpposite"];
	UnorderedGroupNoOpposite *group2 = [ctx insertObjectWithEntityName: @"UnorderedGroupNoOpposite"];
	group1.contents = S(group2);
	group2.contents = S(group1);

	const NSUInteger deallocsBefore = [UnorderedGroupNoOpposite countOfDeallocCalls];
	
	@autoreleasepool
	{
 		COObjectGraphContext *ctx2 = [COObjectGraphContext new];
		[ctx2 setItemGraph: ctx];
	}
	
	const NSUInteger deallocs = [UnorderedGroupNoOpposite countOfDeallocCalls] - deallocsBefore;
	UKIntsEqual(2, deallocs);
}

- (void) testIllegalDirectModificationOfCollection
{
	COObjectGraphContext *ctx = [COObjectGraphContext new];
	UnorderedGroupNoOpposite *group1 = [ctx insertObjectWithEntityName: @"UnorderedGroupNoOpposite"];
	OutlineItem *item1 = [ctx insertObjectWithEntityName: @"OutlineItem"];
	OutlineItem *item2 = [ctx insertObjectWithEntityName: @"OutlineItem"];
	
	group1.contents = S(item1, item2);
	
	UKRaisesException([(NSMutableSet *)group1.contents removeObject: item1]);
}

- (void)testNullDisallowedInCollection
{
	COObjectGraphContext *ctx = [COObjectGraphContext new];
	UnorderedGroupNoOpposite *group1 = [ctx insertObjectWithEntityName: @"UnorderedGroupNoOpposite"];
	
	UKRaisesException([group1 setContents: S([NSNull null])]);
}

@end


/**
 * For some general code comments that apply to all tests, see
 * -testTargetPersistentRootUndeletion.
 *
 * For Relationship Source Deletion Tests, we test the referring objects that 
 * exist implicitly in the relationship cache, but are not exposed since the 
 * relationship is unidirectional.
 */
@interface TestCrossPersistentRootUnorderedRelationship : EditingContextTestCase <UKTest>
{
	UnorderedGroupNoOpposite *group1;
	OutlineItem *item1;
	OutlineItem *item2;
	OutlineItem *otherItem1;
	UnorderedGroupNoOpposite *otherGroup1;
	
	// Convenience - persistent root UUIDs
	ETUUID *group1uuid;
	ETUUID *item1uuid;
	ETUUID *item2uuid;
}

@end

@implementation TestCrossPersistentRootUnorderedRelationship

- (id)init
{
	SUPERINIT;
	
	ctx.unloadingBehavior = COEditingContextUnloadingBehaviorNever;

	group1 = [ctx insertNewPersistentRootWithEntityName: @"UnorderedGroupNoOpposite"].rootObject;
	item1 = [ctx insertNewPersistentRootWithEntityName: @"OutlineItem"].rootObject;
	item1.label = @"current";
	item2 = [ctx insertNewPersistentRootWithEntityName: @"OutlineItem"].rootObject;
	group1.label = @"current";
	group1.contents = S(item1, item2);
	[ctx commit];

	otherItem1 = [item1.persistentRoot.currentBranch makeBranchWithLabel: @"other"].rootObject;
	otherItem1.label = @"other";
	otherGroup1 = [group1.persistentRoot.currentBranch makeBranchWithLabel: @"other"].rootObject;
	otherGroup1.label = @"other";
	[ctx commit];

	group1uuid = group1.persistentRoot.UUID;
	item1uuid = item1.persistentRoot.UUID;
	item2uuid = item2.persistentRoot.UUID;
	
	return self;
}

#define CHECK_BLOCK_ARGS COEditingContext *testCtx, UnorderedGroupNoOpposite *testGroup1, OutlineItem *testItem1, OutlineItem *testItem2, OutlineItem *testOtherItem1, UnorderedGroupNoOpposite *testOtherGroup1, UnorderedGroupNoOpposite *testCurrentGroup1, OutlineItem *testCurrentItem1, OutlineItem *testCurrentItem2, BOOL isNewContext

- (void)checkPersistentRootsWithExistingAndNewContextInBlock: (void (^)(CHECK_BLOCK_ARGS))block
{
	[self checkPersistentRootWithExistingAndNewContext: group1.persistentRoot
											   inBlock:
	 ^(COEditingContext *testCtx, COPersistentRoot *testPersistentRoot, COBranch *testBranch, BOOL isNewContext)
	{
		UnorderedGroupNoOpposite *testGroup1 = testPersistentRoot.rootObject;
		OutlineItem *testItem1 =
			[testCtx persistentRootForUUID: item1.persistentRoot.UUID].rootObject;
		OutlineItem *testItem2 =
			[testCtx persistentRootForUUID: item2.persistentRoot.UUID].rootObject;
		OutlineItem *testOtherItem1 =
			[testItem1.persistentRoot branchForUUID: otherItem1.branch.UUID].rootObject;
		UnorderedGroupNoOpposite *testOtherGroup1 =
			[testGroup1.persistentRoot branchForUUID: otherGroup1.branch.UUID].rootObject;

		UnorderedGroupNoOpposite *testCurrentGroup1 = testPersistentRoot.currentBranch.rootObject;
		OutlineItem *testCurrentItem1 =
			[testCtx persistentRootForUUID: item1.persistentRoot.UUID].currentBranch.rootObject;
		OutlineItem *testCurrentItem2 =
			[testCtx persistentRootForUUID: item2.persistentRoot.UUID].currentBranch.rootObject;
		OutlineItem *testCurrentOtherItem1 =
			[testCtx persistentRootForUUID: otherItem1.persistentRoot.UUID].currentBranch.rootObject;
		UnorderedGroupNoOpposite *testCurrentOtherGroup1 =
			[testCtx persistentRootForUUID: otherGroup1.persistentRoot.UUID].currentBranch.rootObject;

		UKObjectsSame(testCurrentGroup1, testCurrentOtherGroup1);
		UKObjectsSame(testCurrentItem1, testCurrentOtherItem1);
		
		block(testCtx, testGroup1, testItem1, testItem2, testOtherItem1, testOtherGroup1, testCurrentGroup1, testCurrentItem1, testCurrentItem2, isNewContext);
	}];
}

- (void)testRelationships
{
	UnorderedGroupNoOpposite *currentGroup1 = group1.persistentRoot.currentBranch.rootObject;

	UKObjectsEqual(S(item1, item2), group1.contents);
	// Check that the relationship cache knows the inverse relationship,
	// even though it is not used in the metamodel (non-public API)
	UKObjectsEqual(S(group1, currentGroup1, otherGroup1), [item1 referringObjects]);
	UKObjectsEqual(S(group1, currentGroup1, otherGroup1), [item2 referringObjects]);
}

- (void)testRelationshipsFromAndToCurrentBranches
{
	UnorderedGroupNoOpposite *currentGroup1 = group1.persistentRoot.currentBranch.rootObject;
	OutlineItem *currentItem1 = item1.persistentRoot.currentBranch.rootObject;
	OutlineItem *currentItem2 = item2.persistentRoot.currentBranch.rootObject;
	
	UKObjectsEqual(S(item1, item2), currentGroup1.contents);
	// Check that the relationship cache knows the inverse relationship,
	// even though it is not used in the metamodel (non-public API)
	UKTrue([currentItem1 referringObjects].isEmpty);
	UKTrue([currentItem2 referringObjects].isEmpty);
}

#pragma mark - Relationship Target Deletion Tests

- (void)testTargetPersistentRootDeletion
{
	item1.persistentRoot.deleted = YES;
	[ctx commit];

	[self checkPersistentRootsWithExistingAndNewContextInBlock: ^(CHECK_BLOCK_ARGS)
	{
		UKObjectsEqual(S(testItem2), testGroup1.contents);
		UKTrue([testItem1 referringObjects].isEmpty);

		UKObjectsEqual(S(testItem2), testCurrentGroup1.contents);
		UKTrue([testCurrentItem1 referringObjects].isEmpty);
	}];
}

- (void)testTargetPersistentRootUndeletion
{
	item1.persistentRoot.deleted = YES;
	[ctx commit];
	
	item1.persistentRoot.deleted = NO;
	[ctx commit];

	[self checkPersistentRootsWithExistingAndNewContextInBlock: ^(CHECK_BLOCK_ARGS)
	{
		UKObjectsEqual(S(testItem1, testItem2), testGroup1.contents);
		// Check that the relationship cache knows the inverse relationship,
		// even though it is not used in the metamodel (non-public API)
		UKObjectsEqual(S(testGroup1, testCurrentGroup1, testOtherGroup1), [testItem1 referringObjects]);

		// Bidirectional cross persistent root relationships are limited to the
		// tracking branch, this means item1 in the non-tracking current branch
		// doesn't appear in testCurrentGroup1.contents and doesn't refer to it
		// with an inverse relationship (-referringObjectsForPropertyInTarget:
		// simulates it though).
		// Bidirectional cross persistent root relationships are supported
		// accross current branches, but materialized accross tracking branches
		// in memory (they are not visible accross the current branches in memory).
		UKObjectsEqual(S(testItem1, testItem2), testCurrentGroup1.contents);
		UKTrue([testCurrentItem1 referringObjects].isEmpty);
	}];
}

- (void)testTargetPersistentRootDeletionForReferenceToSpecificBranch
{
	group1.contents = S(otherItem1, item2);
	[ctx commit];

	item1.persistentRoot.deleted = YES;
	[ctx commit];

	[self checkPersistentRootsWithExistingAndNewContextInBlock: ^(CHECK_BLOCK_ARGS)
	{
		UKObjectsEqual(S(testItem2), testGroup1.contents);
		UKTrue([testItem1 referringObjects].isEmpty);
		
		UKObjectsEqual(S(testItem2), testCurrentGroup1.contents);
		UKTrue([testCurrentItem1 referringObjects].isEmpty);
	}];
}

- (void)testTargetPersistentRootUndeletionForReferenceToSpecificBranch
{
	group1.contents = S(otherItem1, item2);
	[ctx commit];

	item1.persistentRoot.deleted = YES;
	[ctx commit];
	
	item1.persistentRoot.deleted = NO;
	[ctx commit];
	
	[self checkPersistentRootsWithExistingAndNewContextInBlock: ^(CHECK_BLOCK_ARGS)
	{
		UKStringsEqual(@"other", testOtherItem1.label);
		UKStringsEqual(@"current", testItem1.label);
		UKObjectsEqual(S(testOtherItem1, testItem2), testGroup1.contents);
		UKObjectsEqual(S(testGroup1, testCurrentGroup1), [testOtherItem1 referringObjects]);
		
		UKObjectsEqual(S(testOtherItem1, testItem2), testCurrentGroup1.contents);
		UKTrue([testCurrentItem1 referringObjects].isEmpty);
	}];
}

/**
 * The current branch cannot be deleted, so we cannot write a test method
 * -testTargetBranchDeletion analog to -testTargetPersistentRootDeletion
 */
- (void)testTargetBranchDeletionForReferenceToSpecificBranch
{
	group1.contents = S(otherItem1, item2);
	[ctx commit];
	
	otherItem1.branch.deleted = YES;
	[ctx commit];

	[self checkPersistentRootsWithExistingAndNewContextInBlock: ^(CHECK_BLOCK_ARGS)
	{
		UKObjectsEqual(S(testItem2), testGroup1.contents);
		UKTrue([testOtherItem1 referringObjects].isEmpty);

		UKObjectsEqual(S(testItem2), testCurrentGroup1.contents);
		UKTrue([testCurrentItem1 referringObjects].isEmpty);
	}];
}

- (void)testTargetBranchUndeletionForReferenceToSpecificBranch
{
	group1.contents = S(otherItem1, item2);
	[ctx commit];
	
	otherItem1.branch.deleted = YES;
	[ctx commit];

	otherItem1.branch.deleted = NO;
	[ctx commit];

	[self checkPersistentRootsWithExistingAndNewContextInBlock: ^(CHECK_BLOCK_ARGS)
	{
		UKStringsEqual(@"other", testOtherItem1.label);
		UKStringsEqual(@"current", testItem1.label);
		UKObjectsEqual(S(testOtherItem1, testItem2), testGroup1.contents);
		UKObjectsEqual(S(testGroup1, testCurrentGroup1), [testOtherItem1 referringObjects]);

		UKObjectsEqual(S(testOtherItem1, testItem2), testCurrentGroup1.contents);
		UKTrue([testCurrentItem1 referringObjects].isEmpty);
	}];
}

#pragma mark - Relationship Source Deletion Tests

- (void)testSourcePersistentRootDeletion
{
	group1.persistentRoot.deleted = YES;
	[ctx commit];

	[self checkPersistentRootsWithExistingAndNewContextInBlock: ^(CHECK_BLOCK_ARGS)
	{
		UKObjectsEqual(S(testItem1, testItem2), testGroup1.contents);
		UKObjectsEqual(S(testGroup1, testCurrentGroup1, testOtherGroup1), [testItem1 referringObjects]);

		UKObjectsEqual(S(testItem1, testItem2), testCurrentGroup1.contents);
		UKTrue([testCurrentItem1 referringObjects].isEmpty);
	}];
}

- (void)testSourcePersistentRootUndeletion
{
	group1.persistentRoot.deleted = YES;
	[ctx commit];

	group1.persistentRoot.deleted = NO;
	[ctx commit];

	[self checkPersistentRootsWithExistingAndNewContextInBlock: ^(CHECK_BLOCK_ARGS)
	{
		UKObjectsEqual(S(testItem1, testItem2), testGroup1.contents);
		UKObjectsEqual(S(testGroup1, testCurrentGroup1, testOtherGroup1), [testItem1 referringObjects]);
		 
		UKObjectsEqual(S(testItem1, testItem2), testCurrentGroup1.contents);
		UKTrue([testCurrentItem1 referringObjects].isEmpty);
	}];
}

- (void)testSourcePersistentRootDeletionForReferenceToSpecificBranch
{
	otherGroup1.contents = S(item1, item2);
	[ctx commit];

	otherGroup1.persistentRoot.deleted = YES;
	[ctx commit];

	[self checkPersistentRootsWithExistingAndNewContextInBlock: ^(CHECK_BLOCK_ARGS)
	{
		UKObjectsEqual(S(testItem1, testItem2), testOtherGroup1.contents);
		UKObjectsEqual(S(testGroup1, testCurrentGroup1, testOtherGroup1), [testItem1 referringObjects]);
		
		UKObjectsEqual(S(testItem1, testItem2), testCurrentGroup1.contents);
		UKTrue([testCurrentItem1 referringObjects].isEmpty);
	}];
}

- (void)testSourcePersistentRootUndeletionForReferenceToSpecificBranch
{
	otherGroup1.contents = S(item1, item2);
	[ctx commit];

	otherGroup1.persistentRoot.deleted = YES;
	[ctx commit];
	
	otherGroup1.persistentRoot.deleted = NO;
	[ctx commit];
	
	[self checkPersistentRootsWithExistingAndNewContextInBlock: ^(CHECK_BLOCK_ARGS)
	{
		UKStringsEqual(@"other", testOtherGroup1.label);
		UKStringsEqual(@"current", testGroup1.label);
		UKObjectsEqual(S(testItem1, testItem2), testOtherGroup1.contents);
		UKObjectsEqual(S(testGroup1, testCurrentGroup1, testOtherGroup1), [testItem1 referringObjects]);
		
		UKObjectsEqual(S(testItem1, testItem2), testCurrentGroup1.contents);
		UKTrue([testCurrentItem1 referringObjects].isEmpty);
	}];
}

- (void)testSourceBranchDeletionForReferenceToSpecificBranch
{
	otherGroup1.contents = S(item1, item2);
	[ctx commit];
	
	otherGroup1.branch.deleted = YES;
	[ctx commit];
	
	[self checkPersistentRootsWithExistingAndNewContextInBlock: ^(CHECK_BLOCK_ARGS)
	{
		 UKObjectsEqual(S(testItem1, testItem2), testOtherGroup1.contents);
		 UKObjectsEqual(S(testGroup1, testCurrentGroup1, testOtherGroup1), [testItem1 referringObjects]);
		 
		 UKObjectsEqual(S(testItem1, testItem2), testCurrentGroup1.contents);
		 UKTrue([testCurrentItem1 referringObjects].isEmpty);
	}];
}

- (void)testSourceBranchUndeletionForReferenceToSpecificBranch
{
	otherGroup1.contents = S(item1, item2);
	[ctx commit];
	
	otherGroup1.branch.deleted = YES;
	[ctx commit];
	
	otherGroup1.branch.deleted = NO;
	[ctx commit];
	
	[self checkPersistentRootsWithExistingAndNewContextInBlock: ^(CHECK_BLOCK_ARGS)
	{
		UKStringsEqual(@"other", testOtherItem1.label);
		UKStringsEqual(@"current", testItem1.label);
		UKObjectsEqual(S(testItem1, testItem2), testGroup1.contents);
		UKObjectsEqual(S(testGroup1, testCurrentGroup1, testOtherGroup1), [testItem1 referringObjects]);

		UKObjectsEqual(S(testItem1, testItem2), testCurrentGroup1.contents);
		UKTrue([testCurrentItem1 referringObjects].isEmpty);
	}];
}

- (void) testTargetPersistentRootLazyLoading
{
	COEditingContext *ctx2 = [self newContext];
	
	// First, all persistent roots should be unloaded.
	UKNil([ctx2 loadedPersistentRootForUUID: group1uuid]);
	UKNil([ctx2 loadedPersistentRootForUUID: item1uuid]);
	UKNil([ctx2 loadedPersistentRootForUUID: item2uuid]);
	UKFalse([ctx2 hasChanges]);
	
	// Load group1
	UnorderedGroupNoOpposite *group1ctx2 = [ctx2 persistentRootForUUID: group1uuid].rootObject;
	UKObjectsEqual(@"current", group1ctx2.label);
	
	// Ensure both persistent roots are still unloaded
	UKNil([ctx2 loadedPersistentRootForUUID: item1uuid]);
	UKNil([ctx2 loadedPersistentRootForUUID: item2uuid]);
	UKFalse([ctx2 hasChanges]);
	
	// Access collection to trigger loading
	UKIntsEqual(2, group1ctx2.contents.count);
	OutlineItem *item1ctx2 = [[group1ctx2.contents objectsPassingTest:^(id obj, BOOL*stop){ return [[obj UUID] isEqual: item1.UUID]; }] anyObject];
	OutlineItem *item2ctx2 = [[group1ctx2.contents objectsPassingTest:^(id obj, BOOL*stop){ return [[obj UUID] isEqual: item2.UUID]; }] anyObject];
	UKObjectsEqual(item1.UUID, item1ctx2.UUID);
	UKObjectsEqual(item2.UUID, item2ctx2.UUID);
	UKNotNil([ctx2 loadedPersistentRootForUUID: item1uuid]);
	UKNotNil([ctx2 loadedPersistentRootForUUID: item2uuid]);
	UKFalse([ctx2 hasChanges]);
}

- (void)testTargetBranchLazyLoading
{
	COPath *otherItem1Path = [COPath pathWithPersistentRoot: item1uuid
													 branch: otherItem1.branch.UUID];
	COPath *item2Path = [COPath pathWithPersistentRoot: item2uuid];
	
	group1.contents = S(otherItem1, item2);
	[ctx commit];
	
	COEditingContext *ctx2 = [self newContext];
	
	// First, all persistent roots should be unloaded.
	UKNil([ctx2 loadedPersistentRootForUUID: group1uuid]);
	UKNil([ctx2 loadedPersistentRootForUUID: item1uuid]);
	UKFalse([ctx2 hasChanges]);
	
	// Load group1
	UnorderedGroupNoOpposite *group1ctx2 = [ctx2 persistentRootForUUID: group1uuid].rootObject;
	UKObjectsEqual(@"current", group1ctx2.label);
	
	// Check group1ctx2.contents without triggering loading
	UKNotNil(otherItem1.branch.UUID);
	UKObjectsEqual(S(otherItem1Path, item2Path), [[group1ctx2 serializableValueForStorageKey: @"contents"] allReferences]);
	
	UKObjectsEqual(A(group1ctx2), [[[ctx2 deadRelationshipCache] referringObjectsForPath: otherItem1Path] allObjects]);
	UKObjectsEqual(A(group1ctx2), [[[ctx2 deadRelationshipCache] referringObjectsForPath: item2Path] allObjects]);
	
	// Ensure item1 persistent root is still unloaded
	UKNil([ctx2 loadedPersistentRootForUUID: item1.persistentRoot.UUID]);
	UKFalse([ctx2 hasChanges]);
	
	// Load item1, but not the other branch yet
	OutlineItem *item1ctx2 = [ctx2 persistentRootForUUID: item1uuid].rootObject;
	UKObjectsEqual(item1.UUID, item1ctx2.UUID);
	UKNotNil([ctx2 loadedPersistentRootForUUID: item1uuid]);
	UKObjectsEqual(S(otherItem1Path, item2Path), [[group1ctx2 serializableValueForStorageKey: @"contents"] allReferences]);
	UKFalse([ctx2 hasChanges]);
	
	// Finally load the other branch.
	// This should trigger group1ctx2 to unfault its reference.
	OutlineItem *otherItem1ctx2 = [item1ctx2.persistentRoot branchForUUID: otherItem1.branch.UUID].rootObject;
	UKObjectsEqual(S(otherItem1ctx2), [group1ctx2 serializableValueForStorageKey: @"contents"]);
	UKObjectsEqual(S(otherItem1ctx2, item2Path), [[group1ctx2 serializableValueForStorageKey: @"contents"] allReferences]);
	UKFalse([ctx2 hasChanges]);
}

- (void) testSourcePersistentRootLazyLoading
{
	COEditingContext *ctx2 = [self newContext];
	
	// First, all persistent roots should be unloaded.
	UKNil([ctx2 loadedPersistentRootForUUID: group1uuid]);
	UKNil([ctx2 loadedPersistentRootForUUID: item1uuid]);
	UKNil([ctx2 loadedPersistentRootForUUID: item2uuid]);
	UKFalse([ctx2 hasChanges]);
	
	// Load item1
	OutlineItem *item1ctx2 = [ctx2 persistentRootForUUID: item1uuid].rootObject;
	
	// Because group1 is not currently loaded, we have no way of
	// knowing that it has a cross-reference to item1.
	// So item1ctx2.referringObjects is currently empty.
	// This is sort of a leak in the abstraction of lazy loading.
	UKObjectsEqual(S(), item1ctx2.referringObjects);
	
	// Load group1
	UnorderedGroupNoOpposite *group1ctx2 = [ctx2 persistentRootForUUID: group1uuid].rootObject;
	UKObjectsEqual(@"current", group1ctx2.label);
	
	// That should have updated the referringObjects
	UKObjectsEqual(S(group1ctx2), item1ctx2.referringObjects);
	
	UKFalse([ctx2 hasChanges]);
}

- (void) testSourcePersistentRootLazyLoadingReverseOrder
{
	COEditingContext *ctx2 = [self newContext];
	
	// First, all persistent roots should be unloaded.
	UKNil([ctx2 loadedPersistentRootForUUID: group1uuid]);
	UKNil([ctx2 loadedPersistentRootForUUID: item1uuid]);
	UKNil([ctx2 loadedPersistentRootForUUID: item2uuid]);
	UKFalse([ctx2 hasChanges]);
	
	// Load group1
	UnorderedGroupNoOpposite *group1ctx2 = [ctx2 persistentRootForUUID: group1uuid].rootObject;
	
	// Ensure the references are faulted
	UKObjectsEqual(S([COPath pathWithPersistentRoot: item1uuid],
					 [COPath pathWithPersistentRoot: item2uuid]), [[group1ctx2 serializableValueForStorageKey: @"contents"] allReferences]);
	
	// Load item1
	OutlineItem *item1ctx2 = [ctx2 persistentRootForUUID: item1uuid].rootObject;
	
	// Check that the reference in group1 was unfaulted by the loading of item1
	UKObjectsEqual(S(item1ctx2,
					 [COPath pathWithPersistentRoot: item2uuid]), [[group1ctx2 serializableValueForStorageKey: @"contents"] allReferences]);
	
	UKObjectsEqual(S(group1ctx2), item1ctx2.referringObjects);
	
	UKFalse([ctx2 hasChanges]);
}

@end
