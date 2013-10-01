//
//  Invite.h
//  DGSPhone
//
//  Created by Matthew Knippen on 9/25/13.
//  Copyright (c) 2013 Justin Weiss. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NewGame;

@interface Invite : NSObject <NSCoding>

@property(nonatomic) int messageId;
@property(nonatomic, copy) NSString * opponent; //handle, not full name or UID

//filled after getInviteDetails is called
@property(nonatomic, strong) NewGame *gameDetails;

- (void)setWithDictionary:(NSDictionary *)dictionary;

@end