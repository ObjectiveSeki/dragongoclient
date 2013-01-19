//
//  DGS.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Game.h"
#import "NewGame.h"
#import "GameList.h"
#import "GameServerProtocol.h"
#import "ASIHTTPRequest.h"

typedef void (^ASIHTTPRequestBlock)(ASIHTTPRequest *request, NSString *responseString);

@interface DGS : NSObject <GameServerProtocol> 

@property(nonatomic, retain) UIAlertView *errorView;

// Starts an asynchronous request, calling onSuccess when the request finishes.
- (void)performRequest:(ASIHTTPRequest *)request onSuccess:(ASIHTTPRequestBlock)onSuccess onError:(ErrorBlock)onError;

- (NSString *)sgfCoordsWithRow:(int)row column:(int)col boardSize:(int)boardSize;

// Internal, but these have to be exposed so the logic tests can hit them
- (NSOrderedSet *)gamesFromCSV:(NSString *)csvData;
@end
