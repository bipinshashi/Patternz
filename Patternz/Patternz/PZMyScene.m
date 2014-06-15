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
@property (nonatomic,strong) SKLabelNode *timerLabel;
@property (nonatomic, strong) CAShapeLayer *lineLayer;

@end

static float xOffset = 80.0;
static float yOffset = 200.0;
static float rowWidth = 80.0;
static float dotWidth = 30;
static int gridSize = 3; //nxn , n=3
static int patternConnections = 6;

@implementation PZMyScene

{
    int timeCount;
}

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
        [self createTimer];
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
    dot.strokeColor  = dot.fillColor = [UIColor colorWithRed:0.0/255.0
                                                      green:128.0/255.0
                                                       blue:255.0/255.0
                                                      alpha:1.0];
    dot.position = CGPointMake((point.x*rowWidth)+ xOffset,(point.y*rowWidth) + yOffset);
    return dot;

}

-(void) createPattern
{
    self.lineLayer = [CAShapeLayer layer];
    self.lineLayer.name = @"line";
    self.lineLayer.strokeColor = [UIColor colorWithRed:0.0/255.0
                                            green:128.0/255.0
                                             blue:255.0/255.0 alpha:0.7].CGColor;
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
    NSMutableArray* points = [NSMutableArray array];
    CGPathApply(self.lineLayer.path, (__bridge void *)(points), extractPointsApplier);
    NSLog(@"%@",points);
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//        [self.lineLayer removeFromSuperlayer];
//        CGPathRelease(self.lineLayer.path);
//    });

}


static void extractPointsApplier(void* info, const CGPathElement* element)
{
    NSMutableArray* points = (__bridge NSMutableArray *)(info);
    
    if (element->points && element->type != kCGPathElementCloseSubpath) {
        CGPoint p = *(element->points);
        [points addObject:[NSValue valueWithCGPoint:p]];
    }
}

-(CGPathRef)getPath
{
    CGMutablePathRef pathToDraw = CGPathCreateMutable();
    NSArray *pointsArray = [self createRandomPatternPointsArray];

    for (int i=0; i<pointsArray.count; i++) {
        if (i == 0)
            CGPathMoveToPoint(pathToDraw, NULL,[[pointsArray objectAtIndex:i] CGPointValue].x, [[pointsArray objectAtIndex:i] CGPointValue].y );
        else{
            CGPathAddLineToPoint(pathToDraw, NULL, [[pointsArray objectAtIndex:i] CGPointValue].x, [[pointsArray objectAtIndex:i] CGPointValue].y);
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

-(NSArray*)createRandomPatternPointsArray
{
    NSLog(@"----");
    PZDot *currentDot, *previousDot;
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (int i=0; i <= patternConnections; i++) {
        while (true) {
            int x = arc4random() % gridSize;
            int y = arc4random() % gridSize;
            currentDot = [[self.grid objectAtIndex:x] objectAtIndex:y];
            if (!currentDot.connected && [self isDotLogicOkWithCurrentDot:currentDot previousDot:previousDot]) {
                CGPoint point = [self getCenterPointOfDotWithCoords:CGPointMake([currentDot.x integerValue],[currentDot.y integerValue])];
                [array addObject:[NSValue valueWithCGPoint:point]];
                NSLog(@"point: %@,%@",currentDot.x,currentDot.y);
                [currentDot setConnected:YES];
                previousDot = currentDot;
                break;
            }
        }
    }
    
    return  array;
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
    
    if ([self.lineLayer.presentationLayer hitTest:CGPointMake(80, 360)]){
        NSLog(@"HIT");
    }
    CALayer *layer = self.lineLayer.presentationLayer;
    NSLog(@"presentation layer position: %f,%f",layer.position.x,layer.position.y);
    
}

-(void)createRippleEffectOnNode:(SKNode *)node
{
    if (node.name != nil) {
        SKShapeNode *dot = [self createNodeAtPosition:node.position];
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
    if (self.lastPatternRefreshTimeInterval > 500 || self.isFirstRun) {
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
    if (timeSinceLast > 5) {
        timeSinceLast = 5.0 / 60.0;
        self.lastUpdateTimeInterval = currentTime;
    }
    
    [self updateWithTimeSinceLastUpdate:timeSinceLast];
}

#pragma mark - Timer

- (void)createTimer {
    // start timer
    NSTimer *gameTimer = [NSTimer timerWithTimeInterval:1.00 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:gameTimer forMode:NSDefaultRunLoopMode];
    timeCount = 5; // instance variable
    self.timerLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    self.timerLabel.fontSize = 14;
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
