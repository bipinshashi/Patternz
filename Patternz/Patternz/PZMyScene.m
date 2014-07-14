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
@property (nonatomic,strong) NSMutableArray *nodes;
@property (nonatomic,strong) NSMutableArray *nodeStrokeEndTriggers;
@property (nonatomic,strong) NSMutableArray *currentNodePoints;
@property (nonatomic,strong) NSMutableArray *userLineLayers;
@property (nonatomic,strong) NSMutableArray *userPathNodePoints;

@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;
@property (nonatomic) NSTimeInterval lastPatternRefreshTimeInterval;
@property (nonatomic,strong) SKLabelNode *timerLabel;
@property (nonatomic,strong) SKLabelNode *titleLabel;
@property (nonatomic,strong) SKLabelNode *statusLabel;
@property (nonatomic,strong) SKLabelNode *startLabel;
@property (nonatomic,strong) SKSpriteNode *startButtonNode;
@property (nonatomic, strong) CAShapeLayer *lineLayer;
@property (nonatomic, strong) CAShapeLayer *userLineLayer;
@property (nonatomic, assign) CGMutablePathRef userPathToDraw;
@property (nonatomic, assign) CGPoint userPathAnchorPoint;

@property (nonatomic, assign) int nodeStrokeEndTriggerIndex;
@end

static float xOffset = 60.0;
static float yOffset = 180.0;
static float rowWidth = 100.0;
static float dotWidth = 40;
static int gridSize = 3; //nxn , n=3
//static int patternConnections = 4;

//static const uint32_t dotCategory     =  0x1 << 0;
//static const uint32_t lineCategory    =  0x1 << 1;

@implementation PZMyScene

{
    int timeCount;
    int correctPatternCount;
    bool isUserDrawing;
    bool isStartScreenShowing;
    bool isFirstRun;
    int patternConnections;
    int patternDisplayTime;//in seconds
    NSString *_lastCollidedNodeName;
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        NSLog(@"Size: %@",NSStringFromCGSize(size));

        self.backgroundColor = [SKColor colorWithRed:99.0/255.0 green:212.0/255.0 blue:174.0/255.0 alpha:1.0];
        
        self.titleLabel = [SKLabelNode labelNodeWithFontNamed:@"HoeflerText-BlackItalic"];
        
        self.titleLabel.text = @"Patternz";
        self.titleLabel.fontSize = 24;
        self.titleLabel.fontColor = [UIColor blackColor];
        self.titleLabel.position = CGPointMake(CGRectGetMidX(self.frame),CGRectGetHeight(self.frame) - 50);
        [self addChild:self.titleLabel];
        
        patternConnections = 4;
        patternDisplayTime = 2;
        [self showStartScreen];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startGame) name:@"TryAgain" object:nil];
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
    self.nodes = [[NSMutableArray alloc] init];
    for (int i =0; i<gridSize; i++) {
        for (int j=0; j<gridSize ; j++) {
            SKNode *node = [self createNodeAtPosition:CGPointMake(i, j)];
            [self addChild:node];
            [self.nodes addObject:node];
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
    CGPathRelease(self.lineLayer.path);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, patternDisplayTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.lineLayer removeFromSuperlayer];
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
    y = yOffset + (rowWidth * coords.y);
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


-(void) createUserLineLayer
{
    CAShapeLayer *userLineLayer = [CAShapeLayer layer];
    userLineLayer.name = @"Userline";
    userLineLayer.strokeColor = [UIColor colorWithRed:189.0/255.0
                                                     green:67.0/255.0
                                                      blue:67.0/255.0
                                                     alpha:1.0].CGColor;
    userLineLayer.fillColor = nil;
    userLineLayer.lineWidth = 4.0;
    
    [self.view.layer addSublayer:userLineLayer];
    self.userLineLayer = userLineLayer;
    [self.userLineLayers addObject:self.userLineLayer];
}

-(BOOL)checkIfUserLineCollidedWithNodeAtPoint:(CGPoint)point
{
    for (int i =0; i < self.nodes.count; i++) {
        SKNode *node = self.nodes[i];
        if ([node containsPoint:point] && ![node.name isEqualToString:_lastCollidedNodeName]) {
            _lastCollidedNodeName = node.name;
            NSLog(@"node collided: %@",node.name);
            [self createRippleEffectOnNode:node];
            [self setUserAnchorPointFromNode:node];
            [self addNodeToUserNodePoints:node];
            return YES;
        }
    }
    return NO;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    
    SKNode *node = [self nodeAtPoint:location];
    if (isStartScreenShowing) {
        if ([node.name isEqualToString:@"startNode"]) {
            [self startGame];
        }
    }else{
        if (node.name != nil){
            isUserDrawing = true;
            NSLog(@"%f, %f",node.position.x, node.position.y);
            //        [self createRippleEffectOnNode:node];
            [self setUserAnchorPointFromNode:node];
            [self removeUserLineLayersFromSuperLayer];
            self.userLineLayers = [[NSMutableArray alloc] init];
            self.userPathNodePoints = [[NSMutableArray alloc] init];
            [self createUserLineLayer];
        }
    }
    
}


-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (isUserDrawing) {
        UITouch *touch = [touches anyObject];
        CGPoint location = [touch locationInNode:self];
        if ([self checkIfUserLineCollidedWithNodeAtPoint:location]) {
            [self createUserLineLayer];
        }
        [self completePathBetweenPointA:self.userPathAnchorPoint andPointB:location];
        [self.userLineLayer didChangeValueForKey:@"path"];
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (isUserDrawing) {
        CGPathRelease([self.userLineLayer path]);
        
        //remove extra line which did not form pattern
        if (self.userLineLayers.count >= self.userPathNodePoints.count) {
            [[self.userLineLayers lastObject] removeFromSuperlayer];
        }
        
        [self evaluatePattern];
        isUserDrawing = false;
    }
}

-(void)evaluatePattern
{
    if ([self.currentNodePoints isEqualToArray:self.userPathNodePoints]) {
        timeCount +=5;
        correctPatternCount +=1;
        [self updateStatusWithMessage:@"Correct!!"];
        self.titleLabel.text = [NSString stringWithFormat:@"%d Patternz",correctPatternCount];
        [self setDifficulty];
    }else{
        [self updateStatusWithMessage:@"Wrong!!"];
//        timeCount -= 5;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self removeUserLineLayersFromSuperLayer];
        [self.userLineLayers removeAllObjects];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self resetGrid];
            [self createPattern];
        });
    });
}

-(void)setDifficulty
{
    if (correctPatternCount == 2) {
        patternConnections = 4;
    }else if (correctPatternCount ==5){
        patternDisplayTime = 1;
    }else if (correctPatternCount ==7){
        patternConnections = 5;
    }
}

-(void)removeUserLineLayersFromSuperLayer
{
    for (int i=0; i < self.userLineLayers.count; i++) {
        [self.userLineLayers[i] removeFromSuperlayer];
    }
}

-(void)addNodeToUserNodePoints:(SKNode*)node
{
    CGPoint nodeCoordinates = [self getCoordinatesFromNode:node];
    CGPoint currentDotCenterPoint = [self getCenterPointOfDotWithCoords:nodeCoordinates];
    [self.userPathNodePoints addObject:[NSValue valueWithCGPoint:currentDotCenterPoint]];
}

-(CGPoint)getCoordinatesFromNode:(SKNode*)node
{
    NSArray *nodeNameSplitArray = [node.name componentsSeparatedByString:@","];
    CGPoint nodeCoordinates = CGPointMake([nodeNameSplitArray[0] floatValue], [nodeNameSplitArray[1] floatValue]);
    return nodeCoordinates;
}

-(void)setUserAnchorPointFromNode:(SKNode*)node
{
    CGPoint nodeCoordinates = [self getCoordinatesFromNode:node];
    CGPoint newAnchorPoint = [self getCenterPointOfDotWithCoords:nodeCoordinates];
    [self completePathBetweenPointA:self.userPathAnchorPoint andPointB:newAnchorPoint];
    self.userPathAnchorPoint = newAnchorPoint;
}

-(void)completePathBetweenPointA:(CGPoint)pointA andPointB:(CGPoint)pointB
{
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, self.view.bounds.size.height);
    self.userPathToDraw = CGPathCreateMutable();
    self.userLineLayer.path = self.userPathToDraw;
    CGPathMoveToPoint(self.userPathToDraw, &flipVertical,pointA.x, pointA.y);
    CGPathAddLineToPoint(self.userPathToDraw, &flipVertical,pointB.x, pointB.y);
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
//    NSTimer *gameTimer = [NSTimer timerWithTimeInterval:1.00 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
//    [[NSRunLoop currentRunLoop] addTimer:gameTimer forMode:NSDefaultRunLoopMode];
    timeCount = 10; // instance variable
    self.timerLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    self.timerLabel.fontSize = 14;
    self.timerLabel.fontColor = [UIColor blackColor];
    self.timerLabel.position = CGPointMake(CGRectGetMidX(self.frame),CGRectGetHeight(self.frame) - 100);
    self.timerLabel.alpha = 0;
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
            [timer invalidate];
            [self timerExpired];
//            [self addToTimer:10];
        }
    }
    self.timerLabel.text = [NSString stringWithFormat:@"%02d",timeCount % 60];
}

-(void)addToTimer:(int)value
{
    timeCount += value;
}

- (void) timerExpired {
    // display an alert or something when the timer expires.
    NSLog(@"timer expired");
    [self.lineLayer removeFromSuperlayer];
    [self removeUserLineLayersFromSuperLayer];
    self.nodeStrokeEndTriggerIndex = 0;
    self.lastPatternRefreshTimeInterval = 0;
    
    [self checkBestScore];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GameOver" object:
                                                @{@"score": [NSNumber numberWithInteger:correctPatternCount]}];
    
}

-(void)checkBestScore
{
    int bestScore = [[NSUserDefaults standardUserDefaults] integerForKey:@"BestScore"];
    if (!bestScore || correctPatternCount > bestScore) {
        [[NSUserDefaults standardUserDefaults] setInteger:correctPatternCount forKey:@"BestScore"];
    }
}

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLast {
    
    self.lastPatternRefreshTimeInterval += timeSinceLast;
    if ((self.lastPatternRefreshTimeInterval > 5 || isFirstRun) && isStartScreenShowing) {
        isFirstRun = false;
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
    [self animateRipple];
    [self updateWithTimeSinceLastUpdate:timeSinceLast];
}

-(void) startGame {
    self.titleLabel.text = @"Patternz";
    timeCount = 15;
    patternConnections = 3;
    patternDisplayTime = 2;
    isStartScreenShowing = false;
    NSTimer *gameTimer = [NSTimer timerWithTimeInterval:1.00 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:gameTimer forMode:NSDefaultRunLoopMode];
    
    //reset alpha values
    self.timerLabel.alpha = 1;
    self.startButtonNode.alpha = 0;
    self.startLabel.alpha = 0;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self updateStatusWithMessage:@"Starting Game"];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        correctPatternCount = 0;
        [self resetGrid];
        [self createPattern];
    });
}

-(void)createStatusLabel{
    self.statusLabel = [SKLabelNode labelNodeWithFontNamed:@"Verdana-Italic"];
    self.statusLabel.fontSize = 14;
    self.statusLabel.fontColor = [UIColor blackColor];
    self.statusLabel.position = CGPointMake(CGRectGetMidX(self.frame),CGRectGetHeight(self.frame) - 140);
    self.statusLabel.text = @"Repeat the Pattern";
    [self addChild:self.statusLabel];
}

-(void)createStartButton
{
    self.startButtonNode = [SKSpriteNode spriteNodeWithColor:[UIColor colorWithRed:190.0/255.0 green:59.0/255.0 blue:59.0/255.0 alpha:1]
                                                                 size:CGSizeMake(200, 50)];
    self.startButtonNode.position = CGPointMake(CGRectGetMidX(self.frame),70);
    self.startButtonNode.name = @"startNode";//how the node is identified later
    self.startButtonNode.zPosition = 1.0;
    [self addChild:self.startButtonNode];
    
    self.startLabel = [SKLabelNode labelNodeWithFontNamed:@"Verdana-Italic"];
    self.startLabel.fontSize = 16;
    self.startLabel.fontColor = [UIColor yellowColor];
    self.startLabel.position = CGPointMake(CGRectGetMidX(self.startButtonNode.frame),CGRectGetHeight(self.startButtonNode.frame) + 12);
    self.startLabel.text = @"START";
    self.startLabel.zPosition = 2.0;
    self.startLabel.name = @"startNode";
    [self addChild:self.startLabel];
}

-(void)updateStatusWithMessage:(NSString*)message
{
    if ([message isEqualToString:@"Correct!!"]) {
        self.statusLabel.fontColor = [UIColor blackColor];
    }else if([message isEqualToString:@"Wrong!!"]){
        self.statusLabel.fontColor = [UIColor redColor];
    }
    self.statusLabel.text = message;
    SKAction *fadeIn = [SKAction fadeInWithDuration:0.2];
    SKAction *fadeOut = [SKAction fadeOutWithDuration:0.2];
    SKAction * actionScaleUp = [SKAction scaleTo:1.5 duration:0.3];
    SKAction * actionScaleDown = [SKAction scaleTo:1.0 duration:0.3];
//    SKAction *groupFadeOutFadeIn = [SKAction sequence:@[fadeOut,fadeIn]];
    SKAction *groupFadeInScale =[SKAction group:@[fadeIn, actionScaleUp]];
    SKAction *groupFadeOutScale =[SKAction group:@[fadeOut, actionScaleDown]];
    [self.statusLabel runAction:[SKAction sequence:@[groupFadeInScale, groupFadeOutScale]]];
}

-(void)showStartScreen
{
    [self resetGrid];
    [self createBoard];
    [self createTimer];
    [self createStatusLabel];
    [self createStartButton];
    isFirstRun = true;
    isStartScreenShowing = true;
}

@end
