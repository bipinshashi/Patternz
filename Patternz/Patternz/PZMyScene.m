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
@property (nonatomic,strong) NSMutableArray *nodeStrokeEndTriggers;
@property (nonatomic,strong) NSMutableArray *currentNodePoints;

@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;
@property (nonatomic) NSTimeInterval lastPatternRefreshTimeInterval;
@property (nonatomic, assign) bool isFirstRun;
@property (nonatomic,strong) SKLabelNode *timerLabel;
@property (nonatomic, strong) CAShapeLayer *lineLayer;
@property (nonatomic, assign) int nodeStrokeEndTriggerIndex;
@end

static float xOffset = 80.0;
static float yOffset = 200.0;
static float rowWidth = 80.0;
static float dotWidth = 30;
static int gridSize = 3; //nxn , n=3
static int patternConnections = 4;

//static const uint32_t dotCategory     =  0x1 << 0;
//static const uint32_t lineCategory    =  0x1 << 1;

@implementation PZMyScene

{
    int timeCount;
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        NSLog(@"Size: %@",NSStringFromCGSize(size));

        self.backgroundColor = [SKColor colorWithRed:99.0/255.0 green:212.0/255.0 blue:174.0/255.0 alpha:1.0];
        
        SKLabelNode *myLabel = [SKLabelNode labelNodeWithFontNamed:@"Wawati"];
        
        myLabel.text = @"Patternz";
        myLabel.fontSize = 24;
        myLabel.fontColor = [UIColor blackColor];
        myLabel.position = CGPointMake(CGRectGetMidX(self.frame),CGRectGetHeight(self.frame) - 50);
        [self addChild:myLabel];
        [self resetGrid];
        [self createBoard];
        [self createTimer];
        self.isFirstRun = true;
        
        self.physicsWorld.contactDelegate = self;
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
            [self addChild:[self createNodeAtPosition:CGPointMake(i, j)]];
        }
    }

}

-(SKShapeNode *)createNodeAtPosition:(CGPoint)point
{
    SKShapeNode* dot = [SKShapeNode node];
    dot.name = [NSString stringWithFormat:@"%f,%f",point.x,point.y];
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddArc(path, NULL, 0, 0, dotWidth/2, 0.0, (2 * M_PI), YES);
    dot.path = path;
    //[dot setPath:CGPathCreateWithRoundedRect(CGRectMake(0, 0, dotWidth, dotWidth), dotWidth/2, dotWidth/2, nil)];
    dot.strokeColor  = dot.fillColor = [UIColor colorWithRed:189.0/255.0
                                                      green:67.0/255.0
                                                       blue:67.0/255.0
                                                      alpha:1.0];
    dot.position = CGPointMake((point.x*rowWidth)+ xOffset, (point.y *rowWidth) + yOffset);
    return dot;

}

-(void) createPattern
{
    self.lineLayer = [CAShapeLayer layer];
    self.lineLayer.name = @"line";
    self.lineLayer.strokeColor = [UIColor colorWithRed:189.0/255.0
                                                 green:67.0/255.0
                                                 blue:67.0/255.0
                                                 alpha:1.0].CGColor;
    self.lineLayer.fillColor = nil;
    self.lineLayer.lineWidth = 4.0;
    
    self.lineLayer.path = [self getPath];
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    pathAnimation.duration = 1.0;
    pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    pathAnimation.toValue = [NSNumber numberWithFloat:1.0f];
    pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [self.lineLayer addAnimation:pathAnimation forKey:@"strokeEndAnimation"];

    [self.view.layer addSublayer:self.lineLayer];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.lineLayer removeFromSuperlayer];
        CGPathRelease(self.lineLayer.path);
    });

}


-(CGPathRef)getPath
{
    CGMutablePathRef pathToDraw = CGPathCreateMutable();
    [self createRandomPatternPointsArray];
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, self.view.bounds.size.height);
    for (int i=0; i<self.currentNodePoints.count; i++) {
        if (i == 0)
            CGPathMoveToPoint(pathToDraw, &flipVertical,[[self.currentNodePoints objectAtIndex:i] CGPointValue].x, [[self.currentNodePoints objectAtIndex:i] CGPointValue].y );
        else{
            CGPathAddLineToPoint(pathToDraw, &flipVertical, [[self.currentNodePoints objectAtIndex:i] CGPointValue].x, [[self.currentNodePoints objectAtIndex:i] CGPointValue].y);
        }
    }
    return pathToDraw;
}

-(CGPoint)getCenterPointOfDotWithCoords:(CGPoint)coords
{
    CGFloat x,y;
    x = xOffset + (rowWidth * coords.x);
    y = yOffset + (rowWidth * coords.y) + dotWidth/4;
    return CGPointMake(x,y);
}

-(void)createRandomPatternPointsArray
{
    NSLog(@"----");
    PZDot *currentDot, *previousDot;
    self.currentNodePoints =[[NSMutableArray alloc] init];
    self.nodeStrokeEndTriggers = [[NSMutableArray alloc] init];
    for (int i=0; i <= patternConnections; i++) {
        while (true) {
            int x = arc4random() % gridSize;
            int y = arc4random() % gridSize;
            currentDot = [[self.grid objectAtIndex:x] objectAtIndex:y];
            if (!currentDot.connected && [self isDotLogicOkWithCurrentDot:currentDot previousDot:previousDot]) {
                CGPoint currentDotCenterPoint = [self getCenterPointOfDotWithCoords:CGPointMake([currentDot.x integerValue],[currentDot.y integerValue])];
                [self.currentNodePoints addObject:[NSValue valueWithCGPoint:currentDotCenterPoint]];
                NSLog(@"point: %@,%@",currentDot.x,currentDot.y);
                [currentDot setConnected:YES];
                if (previousDot != nil) {
                    CGPoint previousDotCenterPoint = [self getCenterPointOfDotWithCoords:CGPointMake([previousDot.x integerValue],[previousDot.y integerValue])];
                    [self.nodeStrokeEndTriggers addObject:[self distanceBetweenPointA:currentDotCenterPoint PointB:previousDotCenterPoint]];
                }
                previousDot = currentDot;
                break;
            }
        }
    }
    [self generateNodeStrokeEndTriggers];
}

-(NSNumber*)distanceBetweenPointA:(CGPoint)A PointB:(CGPoint)B
{
    CGFloat xDist = (B.x - A.x);
    CGFloat yDist = (B.y - A.y);
    CGFloat distance = sqrt((xDist * xDist) + (yDist * yDist));
    return [NSNumber numberWithFloat:distance];
}

-(void)generateNodeStrokeEndTriggers
{
    float totalDistance= 0.0;
    float sum = 0.0;
    for (int i=0; i<self.nodeStrokeEndTriggers.count; i++) {
        totalDistance += [self.nodeStrokeEndTriggers[i] floatValue];
    }
    [self.nodeStrokeEndTriggers insertObject:[NSNumber numberWithFloat:0] atIndex:0];
    for (int i=0; i<self.nodeStrokeEndTriggers.count; i++) {
        sum += ([self.nodeStrokeEndTriggers[i] floatValue]/totalDistance);
        self.nodeStrokeEndTriggers[i] = [NSNumber numberWithFloat:sum];
    }
    NSLog(@"current nodes: %@",self.currentNodePoints);
}

-(BOOL) isDotLogicOkWithCurrentDot:(PZDot *)currentDot previousDot:(PZDot *)previousDot
{
    //function to check if the dot is in the same line or diagonal, then it should be the adjacent dot
    if (currentDot.x == previousDot.x) {
        if ( abs([currentDot.y integerValue] - [previousDot.y integerValue]) > 1) {
            return NO;
        }
    }else if (currentDot.y == previousDot.y) {
        if ( abs([currentDot.x integerValue] - [previousDot.x integerValue]) > 1) {
            return NO;
        }
    }else if ((currentDot.x == currentDot.y && previousDot.x == previousDot.y) ||
              ([currentDot.x integerValue] + [currentDot.y integerValue] == (gridSize -1) && [previousDot.x integerValue] + [previousDot.y integerValue] == (gridSize -1))){
        if ( abs([currentDot.x integerValue] - [previousDot.x integerValue]) > 1) {
            return NO;
        }
    }
    return YES;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    NSLog(@"%f, %f",node.position.x, node.position.y);
    [self createRippleEffectOnNode:node];
}

-(void)createRippleEffectOnNode:(SKNode *)node
{
    if (node.name != nil) {
        SKShapeNode *dot = [self createNodeAtPosition:node.position];
        NSLog(@"node name: %@",node.name);
        dot.position = node.position;
        [self addChild:dot];
        SKAction* scaleUpAction = [SKAction scaleTo:2.0 duration:0.2];
        SKAction* fadeOutAction = [SKAction fadeOutWithDuration:0.2];
        SKAction* rippleAction = [SKAction group:@[scaleUpAction,fadeOutAction]];
        SKAction* removeNode = [SKAction runBlock:^{
            [dot removeFromParent];
        }];
        
        [dot runAction:[SKAction sequence:@[rippleAction, removeNode]]];
    }
}

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLast {
    
    self.lastPatternRefreshTimeInterval += timeSinceLast;
    if (self.lastPatternRefreshTimeInterval > 5 || self.isFirstRun) {
        self.isFirstRun = false;
        self.nodeStrokeEndTriggerIndex = 0;
        self.lastPatternRefreshTimeInterval = 0;
        [self resetGrid];
        [self createPattern];
    }

}


-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
    self.lastUpdateTimeInterval = currentTime;
    if (timeSinceLast > 5) {
        timeSinceLast = 5.0 / 60.0;
        self.lastUpdateTimeInterval = currentTime;
    }
//    NSLog(@"presentation layer strokeEnd: %f", [self.lineLayer.presentationLayer strokeEnd]);
    [self animateRipple];
    [self updateWithTimeSinceLastUpdate:timeSinceLast];
}

-(void)animateRipple {
    
    if (self.nodeStrokeEndTriggerIndex < self.nodeStrokeEndTriggers.count &&
        [self.nodeStrokeEndTriggers[self.nodeStrokeEndTriggerIndex] floatValue] <= [self.lineLayer.presentationLayer strokeEnd] ) {
        NSValue *pointValue = [self.currentNodePoints objectAtIndex:self.nodeStrokeEndTriggerIndex];
        SKNode *node = [self nodeAtPoint:pointValue.CGPointValue];
        NSLog(@"node position in ripple: %f, %f",node.position.x, node.position.y);
        self.nodeStrokeEndTriggerIndex += 1;
        [self createRippleEffectOnNode:node];
    }
}

#pragma mark - Timer

- (void)createTimer {
    // start timer
    NSTimer *gameTimer = [NSTimer timerWithTimeInterval:1.00 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:gameTimer forMode:NSDefaultRunLoopMode];
    timeCount = 5; // instance variable
    self.timerLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    self.timerLabel.fontSize = 14;
    self.timerLabel.fontColor = [UIColor blackColor];
    self.timerLabel.position = CGPointMake(CGRectGetMidX(self.frame),CGRectGetHeight(self.frame) - 100);
    [self addChild:self.timerLabel];
}

- (void)timerFired:(NSTimer *)timer {
    // update label
    if(timeCount == 0){
        [self timerExpired];
    } else {
        timeCount--;
        if(timeCount == 0) {
            // display correct dialog with button
//            [timer invalidate];
//            [self timerExpired];
            [self addToTimer:10];
        }
    }
    self.timerLabel.text = [NSString stringWithFormat:@"%d:%02d",timeCount/60, timeCount % 60];
}

-(void)addToTimer:(int)value
{
    timeCount += value;
}

- (void) timerExpired {
    // display an alert or something when the timer expires.
    NSLog(@"timer expired");
}

@end
