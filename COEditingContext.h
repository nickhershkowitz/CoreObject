#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

@class COStore, CORevision, COObject, COCommitTrack;

/**
 * An object context is like a working copy in a revision control system.
 *
 * It queues changes and then attempts to commit them to the store.
 */
@interface COEditingContext : NSObject
{
	COStore *_store;

	int64_t _maxRevisionNumber;
	
	/**
	 * Note: never modify directly; call -markObjectDamaged/-markObjectUndamaged instead.
	 * Otherwise the cached value in COObject won't be updated.
	 */
	NSMutableDictionary *_damagedObjectUUIDs; // UUIDS of objects in this context which have uncommitted changes
	NSMutableDictionary *_instantiatedObjects; // UUID -> COObject mapping
	NSMutableDictionary *_rootObjectRevisions; // UUID of root object -> revision mapping
	NSMutableDictionary *_rootObjectCommitTracks; // UUID of root object -> commit track
	ETModelDescriptionRepository *_modelRepository;

	NSMutableSet *_insertedObjectUUIDs;
	NSMutableSet *_deletedObjectUUIDs;
}

/** @taskunit Accessing the current context */

/** 
 * Returns the context that should be used when none is provided.
 *
 * Factories that create persistent instances in EtoileUI will use this method. 
 * As an example, see -[ETLayoutItemFactory compoundDocument]. 
 */
+ (COEditingContext *)currentContext;
/** 
 * Sets the context that should be used when none is provided.
 *
 * See also +currentContext. 
 */
+ (void)setCurrentContext: (COEditingContext *)aCtxt;

/** @taskunit Creating a new context */

/**
 * Returns a new autoreleased context initialized with the store located at the 
 * given URL, and with no upper limit on the max revision number.
 *
 * See also -initWithStore:maxRevisionNumber: and -[COStore initWithURL:].
 */
+ (COEditingContext *)contextWithURL: (NSURL *)aURL;

/**
 * Initializes a context which persists its content in the given store.
 */
- (id)initWithStore: (COStore *)store;

/**
 * <init />
 * Initializes a context which persists its content in the given store, 
 * fixing the maximum revision number that can be loaded of an object.
 *
 * If the store is nil, the context content is not persisted.
 *
 * If maxRevisionNumber is zero, then there is no upper limit on the revision 
 * that can be loaded.
 */
- (id)initWithStore: (COStore *)store maxRevisionNumber: (int64_t)maxRevisionNumber;
/**
 * Initializes the context with no store. 
 * As a result, the context content is not persisted.
 */
- (id)init;

/** @taskunit Store and Metamodel Access */

/**
 * Returns the store for which the editing context acts a working copy.
 */
- (COStore *)store;
/**
 * Returns the model description repository, which holds the metamodel that 
 * describes all the persistent objects editable in the context.
 */
- (ETModelDescriptionRepository *)modelRepository;

/**
 * Returns the objects presently managed by the receiver in memory.
 *
 * Faults can be included among the returned objects.
 */
- (NSSet *) loadedObjects;

/**
 * Returns whether any object has been inserted, deleted or updated since the 
 * last commit.
 */
- (BOOL) hasChanges;
/**
 * Returns whether the object that corresponds to the UUID has been updated 
 * since the last commit.
 *
 * Won't return YES if the object has just been inserted or deleted.
 */
- (BOOL) objectHasChanges: (ETUUID*)uuid;
/**
 * Returns the UUIDs of the objects updated since the last commit.
 *
 * Doesn't include newly inserted or deleted objects.
 */
- (NSSet*) changedObjectUUIDs;

- (Class) classForEntityDescription: (ETEntityDescription*)desc;
/**
 * Creates a new instance of the given entity name (assigning the instance a new UUID)
 * and returns the object. This is the factory method for COObject.
 */
- (id) insertObjectWithEntityName: (NSString*)aFullName;
/**
 * Creates a new instance of the given entity name (assigning the instance a new UUID)
 * under the specified root object and returns the object. This is the factory method for COObject.
 */
- (id) insertObjectWithEntityName: (NSString*)aFullName rootObject: (COObject*)rootObject;
/**
 * Creates a new instance of the given class (assigning the instance a new UUID)
 * and returns the object.
 */
- (id) insertObjectWithClass: (Class)aClass;
/**
 * Copies an object from another context into this context.
 * The copy refers to the same underlying Core Object (same UUID)
 */
- (id) insertObject: (COObject*)sourceObject;
/**
 * Creates a copy of a Core Object (assigning it a new UUID), including copying
 * all strongly contained objects (composite properties)
 */
- (id) insertObjectCopy: (COObject*)sourceObject;

- (id) insertObject: (COObject*)sourceObject withRelationshipConsistency: (BOOL)consistency newUUID: (BOOL)newUUID; //Private

- (COObject*) objectWithUUID: (ETUUID*)uuid;
- (COObject*) objectWithUUID: (ETUUID*)uuid atRevision: (CORevision*)revision;

- (void) deleteObjectWithUUID: (ETUUID*)uuid;

// Committing changes

- (void) commit;
- (void) commitWithType: (NSString*)type
       shortDescription: (NSString*)shortDescription
        longDescription: (NSString*)longDescription;

// Private

- (void) commitWithMetadata: (NSDictionary*)metadata;

@end


@interface COEditingContext (PrivateToCOObject)

- (void) markObjectDamaged: (COObject*)obj forProperty: (NSString*)aProperty;
- (void) markObjectUndamaged: (COObject*)obj;
- (void) loadObject: (COObject*)obj;
- (void) loadObject: (COObject*)obj atRevision: (CORevision*)aRevision;
- (CORevision*)revisionForObject: (COObject*)object;
- (COCommitTrack*)commitTrackForObject: (COObject*)object;
- (COObject*) objectWithUUID: (ETUUID*)uuid entityName: (NSString*)name atRevision: (CORevision*)revision;
- (COObject*) objectWithUUID: (ETUUID*)uuid entityName: (NSString*)name;
@end



@interface COEditingContext (Rollback)

// Manipulation of the editing context itself - rather than the store

- (void) discardAllChanges;
- (void) discardAllChangesInObject: (COObject*)object;

/**
  * Reload the object at a new revision.
  */
- (void)reloadRootObjectTree: (COObject*)object
                  atRevision: (CORevision*)revision;

@end

