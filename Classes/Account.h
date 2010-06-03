//
//  Account.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/1/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Account : NSObject {
}

- (void)logout;

- (BOOL)login;

- (void)loginWithUsername:(NSString *)username password:(NSString *)password;


@end
