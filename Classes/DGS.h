//
//  DGS.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoginProtocol.h"

@interface DGS : NSObject {
	id <LoginProtocol> delegate;
}

@property(nonatomic, assign) id <LoginProtocol> delegate;

#ifndef LOGIC_TEST_MODE

- (void)logout;
- (BOOL)loggedIn;
- (void)loginWithUsername:(NSString *)username password:(NSString *)password;

- (void)getCurrentGames;
#endif

- (NSString *)sgfCoordsWithRow:(int)row column:(int)col boardSize:(int)boardSize;

// Internal
- (NSArray *)gamesFromCSV:(NSString *)csvData;
- (NSArray *)gamesFromTable:(NSString *)htmlString;

@end
