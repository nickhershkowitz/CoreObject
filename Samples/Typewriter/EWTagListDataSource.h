/*
	Copyright (C) 2014 Eric Wasylishen
 
	Date:  February 2014
	License:  MIT  (see COPYING)
 */

#import <Foundation/Foundation.h>

@class EWTypewriterWindowController;

@interface EWTagListDataSource : NSObject <NSOutlineViewDataSource, NSOutlineViewDelegate>
{
	NSMutableSet *oldSelection;
}

@property (nonatomic, unsafe_unretained) EWTypewriterWindowController *owner;
@property (nonatomic, strong) NSOutlineView *outlineView;
- (void)reloadData;

@end