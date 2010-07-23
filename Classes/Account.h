//
//  Account.h
//  DGSPhone
//
//  Created by Justin Weiss on 7/22/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Account : NSObject {
	NSString *username;
	NSString *name;
	NSString *password;
	NSString *passwordConfirm;
	BOOL *acceptTerms;
}

@property(nonatomic, retain) NSString *username;
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSString *password;
@property(nonatomic, retain) NSString *passwordConfirm;
@property(nonatomic, assign) BOOL *acceptTerms;

@end
