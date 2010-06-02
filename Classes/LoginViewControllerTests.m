//
//  LoginViewControllerTests.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/1/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "LoginViewControllerTests.h"

@implementation LoginViewControllerTests

- (void) testAppDelegate {
    
    id yourApplicationDelegate = [[UIApplication sharedApplication] delegate];
    STAssertNotNil(yourApplicationDelegate, @"UIApplication failed to find the AppDelegate");
    
}

@end
