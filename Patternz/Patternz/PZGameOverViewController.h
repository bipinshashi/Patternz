//
//  PZGameOverViewController.h
//  Patternz
//
//  Created by Bipen Sasi on 6/20/14.
//  Copyright (c) 2014 Bipen Sasi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GADInterstitial.h"

@interface PZGameOverViewController : UIViewController <GADInterstitialDelegate>
@property (nonatomic, assign) int currentScore;
@property (strong, nonatomic) IBOutlet UILabel *currentScoreLabel;
@property (strong, nonatomic) IBOutlet UILabel *bestScoreLabel;

@end
