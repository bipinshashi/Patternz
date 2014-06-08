//
//  PZDot.m
//  Patternz
//
//  Created by Bipen Sasi on 6/8/14.
//  Copyright (c) 2014 Bipen Sasi. All rights reserved.
//

#import "PZDot.h"

@implementation PZDot

-(id)initWithxCoord:(int)x yCoord:(int)y
{
    if (self = [super init]) {
        self.x = [NSNumber numberWithInt:x];
        self.y = [NSNumber numberWithInt:y];
        self.connected = NO;
    }
    return self;
}

@end
