/*
    Copyright (C) 2014 Eric Wasylishen
 
    Date:  January 2014
    License:  MIT  (see COPYING)
 */

#import "EWGraphCell.h"

@implementation EWGraphCell

- (instancetype)init
{
    SUPERINIT;
    return self;
}

- (instancetype)initImageCell: (NSImage *)image
{
    return [self init];
}

- (instancetype)initTextCell: (NSString *)aString
{
    return [self init];
}

- (instancetype)initWithCoder: (NSCoder *)aDecoder
{
    return [self init];
}

- (void)drawWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
    cellFrame = NSInsetRect(cellFrame, -1, -1);

    NSUInteger row = [[self objectValue] unsignedIntegerValue];

    [graphRenderer drawRevisionAtIndex: row
                                inRect: cellFrame];
}

@end
