//
//  PZViewController.m
//  Patternz
//
//  Created by Bipen Sasi on 6/7/14.
//  Copyright (c) 2014 Bipen Sasi. All rights reserved.
//

#import "PZViewController.h"
#import "PZMyScene.h"
#import "PZGameOverViewController.h"
#import "FadeTransition.h"

@implementation PZViewController


- (void)viewWillLayoutSubviews
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushGameOverScreen:) name:@"GameOver" object:nil];
    [super viewWillLayoutSubviews];
    // Configure the view.
    SKView * skView = (SKView *)self.view;
    if (!skView.scene) {

        skView.showsFPS = NO;
        skView.showsNodeCount = NO;
        
        // Create and configure the scene.
        SKScene * scene = [PZMyScene sceneWithSize:skView.bounds.size];
        scene.scaleMode = SKSceneScaleModeAspectFill;
        
        // Present the scene.
        [skView presentScene:scene];
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

-(void)pushGameOverScreen:(NSNotification *)notification
{
    NSDictionary *dict = [notification object];
    NSLog(@"game over");
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PZGameOverViewController *gameOverVC = [sb instantiateViewControllerWithIdentifier:@"GameOverController"];
    gameOverVC.currentScore = [[dict objectForKey:@"score"] integerValue];
    gameOverVC.modalTransitionStyle = UIModalPresentationCustom;
    gameOverVC.transitioningDelegate = self;
    [self presentViewController:gameOverVC animated:YES completion:nil];
}

#pragma mark - Transitioning Delegate methods

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    FadeTransition *transition = [[FadeTransition alloc] init];
    return transition;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    FadeTransition *transition = [[FadeTransition alloc] init];
    return transition;
}

@end
