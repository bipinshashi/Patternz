//
//  PZDot.h
//  Patternz
//
//  Created by Bipen Sasi on 6/8/14.
//  Copyright (c) 2014 Bipen Sasi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PZDot : NSObject

@property (nonatomic,assign) NSNumber *x;
@property (nonatomic,assign) NSNumber *y;
@property (nonatomic,assign) BOOL connected;
-(id)initWithxCoord:(int)x yCoord:(int)y;
@end
