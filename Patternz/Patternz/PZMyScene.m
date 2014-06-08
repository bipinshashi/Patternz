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

static float xOffset = 70.0;
static float yOffset = 200.0;
static float boardWidth = 80.0;
static float dotWidth = 40;
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
    dot.strokeColor = dot.fillColor = [UIColor colorWithRed:0.0/255.0
                                                      green:128.0/255.0
                                                       blue:255.0/255.0
                                                      alpha:1.0];
    dot.position = CGPointMake((point.x*boardWidth)+ xOffset,(point.y*boardWidth) + yOffset);
    return dot;

}

-(void) createPattern
{
    CAShapeLayer *lineLayer = [CAShapeLayer layer];
    lineLayer.name = @"line";
    lineLayer.strokeColor = [UIColor colorWithRed:0.0/255.0
                                            green:128.0/255.0
                                             blue:255.0/255.0 alpha:0.7].CGColor;
    lineLayer.fillColor = nil;
    lineLayer.lineWidth = 4.0;
    
    lineLayer.path = [self getPath];
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    pathAnimation.duration = 1.0;
    pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    pathAnimation.toValue = [NSNumber numberWithFloat:1.0f];
    [lineLayer addAnimation:pathAnimation forKey:@"strokeEndAnimation"];
    [self.view.layer addSublayer:lineLayer];
    CGPathRelease(lineLayer.path);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//        [lineLayer removeFromSuperlayer];
    });

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
    x = xOffset + (boardWidth * coords.x);
    y = yOffset + (boardWidth * coords.y);
    return CGPointMake(x,y);
}

-(NSArray*)createRandomPatternPointsArray
{
    NSLog(@"----");
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (int i=0; i < 5; i++) {
        while (true) {
            int x = arc4random() % gridSize;
            int y = arc4random() % gridSize;
            PZDot *dot = [[self.grid objectAtIndex:x] objectAtIndex:y];
            if (!dot.connected) {
                CGPoint point = [self getCenterPointOfDotWithCoords:CGPointMake([dot.x integerValue],[dot.y integerValue])];
                [array addObject:[NSValue valueWithCGPoint:point]];
                NSLog(@"point: %@,%@",dot.x,dot.y);
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
    NSLog(@"%f, %f",node.position.x, node.position.y);
    [self createRippleEffectOnNode:node];
}

-(void)createRippleEffectOnNode:(SKNode *)node
{
    if (node.name != nil) {
        SKShapeNode *dot = [self createNodeAtPosition:node.position];
        dot.position = node.position;
        [self addChild:dot];
        
        SKAction* scaleUpAction = [SKAction scaleTo:2.0 duration:0.5];
        SKAction* fadeOutAction = [SKAction fadeOutWithDuration:0.5];
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

@end
