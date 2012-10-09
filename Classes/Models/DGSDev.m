//
//  DGSDev.m
//  DGSPhone
//
//  Created by Justin Weiss on 5/8/11.
//  Copyright 2011 Justin Weiss. All rights reserved.
//

#import "DGSDev.h"

#ifndef LOGIC_TEST_MODE
#import "ASIFormDataRequest.h"
#endif

@implementation DGSDev

// This returns the base path onto which all of the urls used 
// in this class refer. This is so that you can run your own
// DGS instance and play with it without ruining your own games.
//
// WARNING: the current CVS checkout of DGS differs significantly
// from the running version -- therefore, you may run into bugs when
// switching back to the real server.
- (NSURL *)URLWithPath:(NSString *)path {
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", @"http://localhost.local/~jweiss/DragonGoServer", path]];
}

#ifndef LOGIC_TEST_MODE

// The DGS development server has tons of new options for creating a game, 
// and renames some of the others.
- (void)addGame:(NewGame *)game onSuccess:(void (^)())onSuccess {
    NSURL *url = [self URLWithPath:@"/new_game.php"];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    
    [request setPostValue:[NSString stringWithFormat:@"%d", [game numberOfGames]] forKey:@"nrGames"];
    [request setPostValue:[game ruleSetValue] forKey:@"ruleset"];
    [request setPostValue:[NSString stringWithFormat:@"%d", [game boardSize]] forKey:@"size"];
    [request setPostValue:[game komiTypeValue] forKey:@"cat_htype"];
    [request setPostValue:[NSString stringWithFormat:@"%d", [game adjustedHandicap]] forKey:@"adj_handicap"];
    [request setPostValue:[NSString stringWithFormat:@"%d", [game minHandicap]] forKey:@"min_handicap"];
    [request setPostValue:[NSString stringWithFormat:@"%d", [game maxHandicap]] forKey:@"max_handicap"];
    [request setPostValue:[game boolValue:[game stdHandicap]] forKey:@"stdhandicap"];
    [request setPostValue:[NSString stringWithFormat:@"%f", [game adjustedKomi]] forKey:@"adj_komi"];
    [request setPostValue:[game jigoModeValue] forKey:@"jigo_mode"];
    [request setPostValue:[NSString stringWithFormat:@"%d", [game timeValue]] forKey:@"timevalue"];
    [request setPostValue:[game timePeriodValue:[game timeUnit]] forKey:@"timeunit"];
    [request setPostValue:[game byoYomiTypeValue] forKey:@"byoyomitype"];
    [request setPostValue:[NSString stringWithFormat:@"%d", [game japaneseTimeValue]] forKey:@"byotimevalue_jap"];
    [request setPostValue:[game timePeriodValue:[game japaneseTimeUnit]] forKey:@"timeunit_jap"];
    [request setPostValue:[NSString stringWithFormat:@"%d", [game japaneseTimePeriods]] forKey:@"byoperiods_jap"];
    [request setPostValue:[NSString stringWithFormat:@"%d", [game canadianTimeValue]] forKey:@"byotimevalue_can"];
    [request setPostValue:[game byoYomiTypeValue] forKey:@"byoyomitype"];
    [request setPostValue:[NSString stringWithFormat:@"%d", [game canadianTimePeriods]] forKey:@"byoperiods_can"];
    [request setPostValue:[NSString stringWithFormat:@"%d", [game fischerTimeValue]] forKey:@"byotimevalue_fis"];
    [request setPostValue:[game timePeriodValue:[game fischerTimeUnit]] forKey:@"timeunit_fis"];

    [request setPostValue:[game boolValue:[game weekendClock]] forKey:@"weekendclock"];
    [request setPostValue:[game boolValue:[game rated]] forKey:@"rated"];
    [request setPostValue:[game boolValue:[game requireRatedOpponent]] forKey:@"must_be_rated"];
    [request setPostValue:[game minimumRating] forKey:@"rating1"];
    [request setPostValue:[game maximumRating] forKey:@"rating2"];
    [request setPostValue:[NSString stringWithFormat:@"%d", [game sameOpponent]] forKey:@"same_opp"];       
    [request setPostValue:[game comment] forKey:@"comment"];
    [request setPostValue:@"Add Game" forKey:@"add_game"];


    [self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
		onSuccess();
	} onError:nil];
}

#endif

@end
