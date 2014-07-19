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

@interface PZGameOverViewController ()

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


@end
