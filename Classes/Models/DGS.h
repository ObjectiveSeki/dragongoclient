//
//  DGS.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoginProtocol.h"
#import "Game.h"
#import "NewGame.h"
#import "GameList.h"
#import "GameServerProtocol.h"

#ifndef LOGIC_TEST_MODE
#import "ASIHTTPRequest.h"

typedef void (^ASIHTTPRequestBlock)(ASIHTTPRequest *request, NSString *responseString);
#endif

@interface DGS : NSObject <GameServerProtocol> {
	id <LoginProtocol> __weak delegate;
#ifndef LOGIC_TEST_MODE
    UIAlertView *errorView;
#endif
}

@property(nonatomic, weak) id <LoginProtocol> delegate;


// Logic tests can't test anything that uses the native iPhone functionality.
// Therefore, we don't want to compile anything that hits the network
// if we're building the logic tests bundle. It should define LOGIC_TEST_MODE.
#ifndef LOGIC_TEST_MODE

@property(nonatomic, retain) UIAlertView *errorView;

// Starts an asynchronous request, calling onSuccess when the request finishes.
- (void)performRequest:(ASIHTTPRequest *)request onSuccess:(ASIHTTPRequestBlock)onSuccess;

#endif

- (NSString *)sgfCoordsWithRow:(int)row column:(int)col boardSize:(int)boardSize;

// Internal, but these have to be exposed so the logic tests can hit them
- (NSArray *)gamesFromCSV:(NSString *)csvData;
- (NSArray *)gamesFromWaitingRoomTable:(NSData *)htmlData;
- (NSString *)nextPagePath:(NSData *)htmlData;
@end
