/**
    Copyright (C) 2014 Quentin Mathe

    Date:  January 2014
    License:  MIT  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

/**
 * @group Schema Migration
 * @abstract Represents an entity or property move accross two packages
 * that can be attached to a schema migration.
 *
 * See -[COSchemaMigration entityMoves] and -[COSchemaMigration propertyMoves].
 */
@interface COModelElementMove : NSObject
{
@private
    NSString *_name;
    NSString *_ownerName;
    NSString *_packageName;
    int64_t _packageVersion;
}


/** @taskunit Name */


/**
 * The name of the entity or property to move.
 */
@property (nonatomic, readwrite, copy) NSString *name;
/**
 * The name of the entity that owns the property to move.
 *
 * For moving an entity, must be nil.
 *
 * For moving a property, must be set.
 */
@property (nonatomic, readwrite, copy) NSString *ownerName;


/** @taskunit Targeted Package and Version */


/**
 * The package where we want to move the entity or property.
 *
 * The package must correspond to a package name in the metamodel.
 *
 * See -[ETPackageDescription name] and -[COCommitDescriptor domain].
 */
@property (nonatomic, readwrite, copy) NSString *packageName;
/**
 * The package version that requires the moved entity or property.
 *
 * For the migration registered under this package/version pair, the entity or
 * property move must have been done.
 */
@property (nonatomic, readwrite, assign) int64_t packageVersion;

@end
