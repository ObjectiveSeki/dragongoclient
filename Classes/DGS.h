//
//  DGS.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DGS : NSObject {

}

#ifndef LOGIC_TEST_MODE

+ (void)logout;
+ (BOOL)loggedIn;
+ (void)loginWithUsername:(NSString *)username password:(NSString *)password;

+ (NSArray *)currentGames;
#endif

// Internal
+ (NSArray *)gamesFromCSV:(NSString *)csvData;
+ (NSArray *)gamesFromTable:(NSString *)htmlString;

@end
