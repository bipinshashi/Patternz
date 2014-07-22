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
#import "GADBannerView.h"

@interface PZViewController()

@property (nonatomic, strong) GADBannerView *googleBannerView;

@end

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
//        [self setupAds];
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

#pragma mark - googleAd

-(void)setupAds
{
    CGPoint origin = CGPointMake(0.0,
                                 self.view.frame.size.height -
                                 CGSizeFromGADAdSize(kGADAdSizeBanner).height);
    self.googleBannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner origin:origin];
    
    // Specify the ad unit ID.
    self.googleBannerView.adUnitID = @"ca-app-pub-1799013171296240/2742850011";
    
    self.googleBannerView.rootViewController = self;
    [self.view addSubview:self.googleBannerView];
    
    GADRequest *request = [GADRequest request];

    request.testDevices = [NSArray arrayWithObjects:
                           GAD_SIMULATOR_ID,
                           nil];
    [self.googleBannerView loadRequest:request];
}

@end
