//
//  PZMyScene.m
//  Patternz
//
//  Created by Bipen Sasi on 6/7/14.
//  Copyright (c) 2014 Bipen Sasi. All rights reserved.
//

#import "PZMyScene.h"
#import <QuartzCore/QuartzCore.h>
#import "PZDot.h"

@interface PZMyScene()
@property (nonatomic,strong) NSMutableArray *grid;
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;
@property (nonatomic) NSTimeInterval lastPatternRefreshTimeInterval;
@property (nonatomic, assign) bool isFirstRun;

@end

static float xOffset = 80.0;
static float yOffset = 200.0;
static float boardWidth = 70.0;
static float dotWidth = 30;
static int gridSize = 3; //nxn , n=3

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
        [self resetGrid];
        [self createBoard];
        self.isFirstRun = true;
    }
    return self;
}

-(void)resetGrid
{
    self.grid = [[NSMutableArray alloc] init];
    for (int i =0; i<gridSize; i++) {
        self.grid[i] = [[NSMutableArray alloc] init];
        for (int j=0; j<gridSize ; j++) {
            PZDot *dot = [[PZDot alloc] initWithxCoord:i yCoord:j];
            [self.grid[i] addObject:dot];
        }
    }
}


-(void) createBoard
{
    for (int i =0; i<gridSize; i++) {
        self.grid[i] = [[NSMutableArray alloc] init];
        for (int j=0; j<gridSize ; j++) {
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
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [lineLayer removeFromSuperlayer];
    });

}

-(CGPathRef)getPath
{
    CGMutablePathRef pathToDraw = CGPathCreateMutable();
    NSArray *pointsArray = [self createRandomPatternPointsArray];

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

-(NSArray*)createRandomPatternPointsArray
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (int i=0; i < 4; i++) {
        while (true) {
            int x = arc4random() % gridSize;
            int y = arc4random() % gridSize;
            PZDot *dot = [[self.grid objectAtIndex:x] objectAtIndex:y];
            if (!dot.connected) {
                CGPoint point = [self getCenterPointOfDotWithCoords:CGPointMake([dot.x integerValue],[dot.y integerValue])];
                [array addObject:[NSValue valueWithCGPoint:point]];
                [dot setConnected:YES];
                break;
            }
        }
    }
    
    return  array;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    NSLog(@"%f",node.position.x);
    
}

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLast {
    
    self.lastPatternRefreshTimeInterval += timeSinceLast;
    if (self.lastPatternRefreshTimeInterval > 5 || self.isFirstRun) {
        self.isFirstRun = false;
        self.lastPatternRefreshTimeInterval = 0;
        [self resetGrid];
        [self createPattern];
    }
}


-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
    self.lastUpdateTimeInterval = currentTime;
    if (timeSinceLast > 5) { // more than a second since last update
        timeSinceLast = 5.0 / 60.0;
        self.lastUpdateTimeInterval = currentTime;
    }
    
    [self updateWithTimeSinceLastUpdate:timeSinceLast];
}

@end
