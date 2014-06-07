//
//  PZMyScene.m
//  Patternz
//
//  Created by Bipen Sasi on 6/7/14.
//  Copyright (c) 2014 Bipen Sasi. All rights reserved.
//

#import "PZMyScene.h"
#import <QuartzCore/QuartzCore.h>

@interface PZMyScene ()

@property (nonatomic) SKShapeNode *line;

@end

static float xOffset = 80.0;
static float yOffset = 200.0;
static float boardWidth = 70.0;
static float dotWidth = 30;
@implementation PZMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        NSLog(@"Size: %@",NSStringFromCGSize(size));

        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        
        SKLabelNode *myLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        
        myLabel.text = @"Patternz!";
        myLabel.fontSize = 20;
        myLabel.position = CGPointMake(CGRectGetMidX(self.frame),CGRectGetHeight(self.frame) - 50);
        
        [self addChild:myLabel];
        [self createBoard];
    }
    return self;
}

-(void) createBoard
{

    for (int i =0; i<3; i++) {
        for (int j=0; j<3 ; j++) {
            SKShapeNode* dot = [SKShapeNode node];
            [dot setPath:CGPathCreateWithRoundedRect(CGRectMake(0, 0, dotWidth, dotWidth), dotWidth/2, dotWidth/2, nil)];
            dot.strokeColor = dot.fillColor = [UIColor colorWithRed:0.0/255.0
                                                              green:128.0/255.0
                                                               blue:255.0/255.0
                                                              alpha:1.0];
            dot.position = CGPointMake((i*boardWidth)+ xOffset,(j*boardWidth) + yOffset);
            [self addChild:dot];
        }
    }

}

-(void) createPattern
{
    CAShapeLayer *lineLayer = [CAShapeLayer layer];
    lineLayer.name = @"line";
    lineLayer.strokeColor = [UIColor colorWithRed:0.0/255.0
                                            green:128.0/255.0
                                             blue:255.0/255.0 alpha:1.0].CGColor;
    lineLayer.fillColor = nil;
    lineLayer.lineWidth = 8.0;
    
    lineLayer.path = [self getPath];
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    pathAnimation.duration = 1.0;
    pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    pathAnimation.toValue = [NSNumber numberWithFloat:1.0f];
    [lineLayer addAnimation:pathAnimation forKey:@"strokeEndAnimation"];
    [self.view.layer addSublayer:lineLayer];
    CGPathRelease(lineLayer.path);

}

-(CGPathRef)getPath
{
    CGMutablePathRef pathToDraw = CGPathCreateMutable();
    CGPoint start = [self getCenterPointOfDotWithCoords:CGPointMake(1,0)];
    CGPoint second = [self getCenterPointOfDotWithCoords:CGPointMake(1,1)];
    CGPoint third = [self getCenterPointOfDotWithCoords:CGPointMake(0,1)];
    CGPoint fourth = [self getCenterPointOfDotWithCoords:CGPointMake(0,2)];

    NSArray *pointsArray = @[[NSValue valueWithCGPoint:start],
                                    [NSValue valueWithCGPoint:second],[NSValue valueWithCGPoint:third],[NSValue valueWithCGPoint:fourth]];
    for (int i=0; i<pointsArray.count; i++) {
        if (i == 0) {
            CGPathMoveToPoint(pathToDraw, NULL,[[pointsArray objectAtIndex:i] CGPointValue].x, [[pointsArray objectAtIndex:i] CGPointValue].y );
        }else
            CGPathAddLineToPoint(pathToDraw, NULL, [[pointsArray objectAtIndex:i] CGPointValue].x, [[pointsArray objectAtIndex:i] CGPointValue].y);
    }
    return pathToDraw;
}

-(CGPoint)getCenterPointOfDotWithCoords:(CGPoint)coords
{
    CGFloat x,y;
    x = xOffset + (boardWidth * coords.x)+ dotWidth/2;
    y = yOffset + (boardWidth * coords.y)+ dotWidth/2;
    return CGPointMake(x,y);
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    NSLog(@"%f",node.position.x);
    
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    [self createPattern];

}

@end
