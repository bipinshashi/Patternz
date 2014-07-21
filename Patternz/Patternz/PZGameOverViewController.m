//
//  PZGameOverViewController.m
//  Patternz
//
//  Created by Bipen Sasi on 6/20/14.
//  Copyright (c) 2014 Bipen Sasi. All rights reserved.
//

#import "PZGameOverViewController.h"
#import "PZViewController.h"
#import <Social/Social.h>
#import <Twitter/Twitter.h>
#import "Mixpanel.h"
#import "GADBannerView.h"
#import "GADInterstitial.h"


@interface PZGameOverViewController ()

@property (nonatomic, strong) GADBannerView *googleBannerView;
@property (nonatomic, strong) GADInterstitial *interstitial;

@end

@implementation PZGameOverViewController
{
    NSString *_shareText;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.currentScoreLabel.text = [NSString stringWithFormat:@"%d Patternz",self.currentScore];
    self.bestScoreLabel.text = [NSString stringWithFormat:@"%ld Patternz",(long)[[NSUserDefaults standardUserDefaults] integerForKey:@"BestScore"]];
    _shareText = [NSString stringWithFormat:@"Try to beat my score of %@ in #patternz. Download here: http://bit.ly/patternz",self.currentScoreLabel.text ];
    // Do any additional setup after loading the view.
    [self setupAds];
    [self setupInterstitialAds];
    [[Mixpanel sharedInstance] track:@"Game Over" properties:@{
                                                               @"score": self.currentScoreLabel.text
                                                               }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)facebookShareClicked:(id)sender {
    [[Mixpanel sharedInstance] track:@"Share Clicked" properties:@{
                                           @"type": @"facebook",
                                           }];
    SLComposeViewController *fbSheet = [SLComposeViewController
                                           composeViewControllerForServiceType:SLServiceTypeFacebook];
    [fbSheet setInitialText:_shareText];
    [self presentViewController:fbSheet animated:YES completion:nil];
    
}

- (IBAction)twitterShareClicked:(id)sender {
    [[Mixpanel sharedInstance] track:@"Share Clicked" properties:@{
                                                                   @"type": @"twitter",
                                                                   }];
    SLComposeViewController *tweetSheet = [SLComposeViewController
                                           composeViewControllerForServiceType:SLServiceTypeTwitter];
    [tweetSheet setInitialText:_shareText];
    [self presentViewController:tweetSheet animated:YES completion:nil];
    
}

- (IBAction)tryAgainButtonClicked:(id)sender {
    [[Mixpanel sharedInstance] track:@"Try Again Clicked"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TryAgain" object:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - googleAd

-(void)setupAds
{
    CGPoint origin = CGPointMake(0.0,
                                 self.view.frame.size.height -
                                 CGSizeFromGADAdSize(kGADAdSizeBanner).height);
    self.googleBannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner origin:origin];
    
    // Specify the ad unit ID.
    self.googleBannerView.adUnitID = @"ca-app-pub-1799013171296240/9707713610";
    
    self.googleBannerView.rootViewController = self;
    [self.view addSubview:self.googleBannerView];
    
    GADRequest *request = [GADRequest request];
    
    request.testDevices = [NSArray arrayWithObjects:
                           GAD_SIMULATOR_ID,
                           nil];
    [self.googleBannerView loadRequest:request];
}

-(void)setupInterstitialAds
{
    self.interstitial = [[GADInterstitial alloc] init];
    self.interstitial.adUnitID = @"ca-app-pub-1799013171296240/2184446816";
    GADRequest *request = [GADRequest request];
    
    request.testDevices = [NSArray arrayWithObjects:
                           GAD_SIMULATOR_ID,
                           nil];
    [self.interstitial loadRequest:request];
    [self.interstitial setDelegate:self];
}

-(void)interstitialDidReceiveAd:(GADInterstitial *)ad
{
    [self.interstitial presentFromRootViewController:self];
}

@end
