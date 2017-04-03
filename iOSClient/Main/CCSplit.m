 //
//  CCSplit.m
//  Crypto Cloud Technology Nextcloud
//
//  Created by Marino Faggiana on 09/10/15.
//  Copyright (c) 2014 TWS. All rights reserved.
//
//  Author Marino Faggiana <m.faggiana@twsweb.it>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "CCSplit.h"
#import "AppDelegate.h"
#import "CCLogin.h"

@interface CCSplit ()
{
}
@end

@implementation CCSplit

#pragma --------------------------------------------------------------------------------------------
#pragma mark ===== Init =====
#pragma --------------------------------------------------------------------------------------------

-  (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])  {
        
        
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.delegate = self;
    
    [self inizialize];
}

// Apparirà
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self showIntro];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        if (self.view.frame.size.width == ([[UIScreen mainScreen] bounds].size.width*([[UIScreen mainScreen] bounds].size.width<[[UIScreen mainScreen] bounds].size.height))+([[UIScreen mainScreen] bounds].size.height*([[UIScreen mainScreen] bounds].size.width>[[UIScreen mainScreen] bounds].size.height))) {
            
            // Portrait
            
        } else {
            
            // Landscape
        }
    }];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark ===== inizialization =====
#pragma --------------------------------------------------------------------------------------------

- (void)inizialize
{
    //  setting version
    self.version = [CCUtility setVersionCryptoCloud];
    
    // init home
    [[NSNotificationCenter defaultCenter] postNotificationName:@"initializeMain" object:nil];
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark ===== Intro =====
#pragma --------------------------------------------------------------------------------------------

- (void)showIntro
{
    
#ifdef OPTION_DISABLE_INTRO
    [CCUtility setIntro:@"1.0"];
    [self newAccount];
#endif
    
    if ([CCUtility getIntro:@"1.0"] == NO) {
        
        _intro = [[CCIntro alloc] initWithDelegate:self delegateView:self.view];
        [_intro showIntroCryptoCloud:0.0];
        
    } else {
        
        [self newAccount];
    }
}

- (void)introWillFinish:(EAIntroView *)introView wasSkipped:(BOOL)wasSkipped
{
    [CCUtility setIntro:@"1.0"];
    [self newAccount];
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark ===== newAccount =====
#pragma --------------------------------------------------------------------------------------------

- (void)loginSuccess:(NSInteger)loginType
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"initializeMain" object:nil];
}

- (void)newAccount
{
    if (app.activeAccount.length == 0) {
    
        CCLogin *loginVC = [[UIStoryboard storyboardWithName:@"CCLogin" bundle:nil] instantiateViewControllerWithIdentifier:@"CCLoginNextcloud"];
        loginVC.delegate = self;
        loginVC.loginType = loginAddForced;
        
        [self presentViewController:loginVC animated:YES completion:nil];
    }
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark ===== Split View Controller =====
#pragma --------------------------------------------------------------------------------------------

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController
{
    return YES;
}

- (UIViewController *)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController
{
    if ([primaryViewController isKindOfClass:[UINavigationController class]]) {
        for (UIViewController *controller in [(UINavigationController *)primaryViewController viewControllers]) {
            if ([controller isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)controller visibleViewController] isKindOfClass:[CCDetail class]]) {
                return controller;
            }
        }
    }
    
    // No detail view present
    UINavigationController *secondaryNC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"CCDetailNC"];
    
    // Color
    [CCAspect aspectNavigationControllerBar:secondaryNC.navigationBar encrypted:NO online:YES hidden:NO];
    
    // Ensure back button is enabled
    UIViewController *detailViewController = [secondaryNC visibleViewController];
    
    detailViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
    detailViewController.navigationItem.leftItemsSupplementBackButton = YES;
    
    return secondaryNC;
}

- (UIViewController *)primaryViewControllerForExpandingSplitViewController:(UISplitViewController *)splitViewController
{
    UITabBarController *tbMaster = splitViewController.viewControllers[0];
    UINavigationController *ncMaster = [tbMaster selectedViewController];
    
    //UIViewController *main = [ncMaster.viewControllers firstObject];
    UIViewController *detail = [ncMaster.viewControllers lastObject];
    
    if ([detail isKindOfClass:[CCDetail class]]) {
        
        [ncMaster popViewControllerAnimated:NO];
        
    }
    
    return nil;
}

// sender = CCMain
// vc = UINavigationController detail
- (void)showDetailViewController:(UIViewController *)vc sender:(id)sender
{
    UINavigationController *ncDetail = (UINavigationController *)vc;
    
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        
        if ([self.viewControllers[0] isKindOfClass:[UITabBarController class]]) {
            
            UINavigationController *ncMaster = [self.viewControllers[0] selectedViewController];
            
            [ncMaster pushViewController:ncDetail.topViewController animated:YES];
            
            return;
        }
    }
    
    [super showDetailViewController:vc sender:sender];
    
    // display icon "\"
    ncDetail.topViewController.navigationItem.leftBarButtonItem = self.displayModeButtonItem;
    self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
}

// OK
- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode
{
    UIViewController *viewController = [svc.viewControllers lastObject];
    
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        
        UINavigationController *navigationController = (UINavigationController *)viewController;
        
        UIViewController *detail = [navigationController.viewControllers firstObject];
        
        if ([detail isKindOfClass:[CCDetail class]]) {
            
            [(CCDetail *)detail performSelector:@selector(changeToDisplayMode) withObject:nil afterDelay:0.05];
        }
    }
}

@end
