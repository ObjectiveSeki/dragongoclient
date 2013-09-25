//
//  Invite.m
//  DGSPhone
//
//  Created by Matthew Knippen on 9/25/13.
//  Copyright (c) 2013 Justin Weiss. All rights reserved.
//

#import "Invite.h"
#import "NewGame.h"

@implementation Invite

//lazy loading
- (NewGame *)gameDetails {
    if (!_gameDetails) {
        _gameDetails = [[NewGame alloc] init];
    }

    return _gameDetails;
}


- (void)setWithDictionary:(NSDictionary *)dictionary {
    NSLog(@"Invite Details: %@", dictionary);
    [self.gameDetails setWithDictionary:dictionary[@"game_settings"]];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeInt:self.messageId forKey:@"messageId"];
    [encoder encodeObject:self.opponent forKey:@"opponent"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.messageId = [decoder decodeIntForKey:@"messageId"];
        self.opponent = [decoder decodeObjectForKey:@"opponent"];
    }
    return self;
}

@end
