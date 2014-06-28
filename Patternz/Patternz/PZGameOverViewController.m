//
//  PZGameOverViewController.m
//  Patternz
//
//  Created by Bipen Sasi on 6/20/14.
//  Copyright (c) 2014 Bipen Sasi. All rights reserved.
//

#import "PZGameOverViewController.h"
#import "PZViewController.h"

@interface PZGameOverViewController ()

@end

@implementation PZGameOverViewController

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
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)shareButtonClicked:(id)sender {
}

- (IBAction)tryAgainButtonClicked:(id)sender {
//    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//    PZViewController *homeVC = [sb instantiateViewControllerWithIdentifier:@"HomeViewController"];
//    homeVC.modalTransitionStyle = UIModalPresentationCustom;
//    homeVC.transitioningDelegate = homeVC;
//    [self presentViewController:homeVC animated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TryAgain" object:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
