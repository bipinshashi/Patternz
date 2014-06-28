//
//  FadeTransition.m
//  Patternz
//
//  Created by Bipen Sasi on 6/20/14.
//  Copyright (c) 2014 Bipen Sasi. All rights reserved.
//

#import "FadeTransition.h"

@implementation FadeTransition

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.5f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *toVC = [transitionContext
                              viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    toVC.view.alpha = 0;
    [[transitionContext containerView] addSubview:toVC.view];
    CGRect fullFrame = [transitionContext initialFrameForViewController:fromVC];
    toVC.view.frame = fullFrame;
    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                     animations:^{
                         toVC.view.alpha = 1.0;
                     } completion:^(BOOL finished) {
                         [transitionContext completeTransition:YES];
                     }];
}

@end
