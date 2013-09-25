//
//  NewGame.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/28/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//fischer

#import "NewGame.h"

@implementation NewGame

- (id)init {
	if (self = [super init]) {
		_numberOfGames = 1;
		_boardSize = 19;
		_maxHandicap = 21;
		_stdHandicap = YES;
		_timeValue = 30;
		_timeUnit = kTimePeriodDays;
        _byoYomiType = kByoYomiTypeFischer;
		_japaneseTimeValue = 1;
		_japaneseTimeUnit = kTimePeriodDays;
		_japaneseTimePeriods = 10;
		_canadianTimeValue = 15;
		_canadianTimeUnit = kTimePeriodDays;
		_canadianTimePeriods = 15;
		_fischerTimeValue = 1;
		_fischerTimeUnit = kTimePeriodDays;
		_weekendClock = YES;
		_rated = NO;
        _requireRatedOpponent = NO;
		_minimumRating = @"30 kyu";
		_maximumRating = @"9 dan";
		_myGame = true;
        _comment = @"";
	}
	return self;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [self isEqualToGame:other];
}

- (BOOL)isEqualToGame:(Game *)game {
    if (self == game) {
        return YES;
    }
    if (self.gameId == game.gameId) {
        return YES;
    }
    return NO;
}

- (NSString *)ruleSetValue {
	NSString *ruleSetString = @"";
	
	switch(self.ruleSet) {
		case kRuleSetJapanese:
			ruleSetString = @"JAPANESE";
			break;
		case kRuleSetChinese:
			ruleSetString = @"CHINESE";
			break;
	}
	return ruleSetString;
}

- (NSString *)komiTypeValue {
	NSString *komiTypeString = @"";
	
	switch(self.komiType) {
		case kKomiTypeConventional:
			komiTypeString = @"conv";
			break;
		case kKomiTypeProper:
			komiTypeString = @"proper";
			break;
        case kKomiTypeManual:
			komiTypeString = @"manual";
			break;
    }
	return komiTypeString;
}

- (NSString *)komiTypeString:(KomiType)aKomiType {
	NSString *komiTypeString = @"";
	
	switch(aKomiType) {
		case kKomiTypeConventional:
			komiTypeString = @"Conventional";
			break;
		case kKomiTypeProper:
			komiTypeString = @"Proper";
			break;
		case kKomiTypeManual:
			komiTypeString = @"Manual Handicap";
            break;
	}
	return komiTypeString;
}

- (NSString *)komiTypeString {
	return [self komiTypeString:self.komiType];
}

- (NSString *)manualKomiTypeValue {
	NSString *string = @"";
	
	switch(self.manualKomiType) {
		case kManualKomiTypeNigiri:
			string = @"nigiri";
			break;
		case kManualKomiTypeDouble:
			string = @"double";
			break;
   		case kManualKomiTypeBlack:
			string = @"black";
			break;
   		case kManualKomiTypeWhite:
			string = @"white";
            break;
	}
	return string;
}

- (NSString *)manualKomiTypeString:(ManualKomiType)aManualKomiType {
	NSString *string = @"";
	
	switch(aManualKomiType) {
		case kManualKomiTypeNigiri:
			string = @"Nigiri";
			break;
		case kManualKomiTypeDouble:
			string = @"Double";
			break;
   		case kManualKomiTypeBlack:
			string = @"Take Black";
			break;
   		case kManualKomiTypeWhite:
			string = @"Take White";
            break;
	}
	return string;
}

- (NSString *)manualKomiTypeString {
	return [self manualKomiTypeString:self.manualKomiType];
}

- (NSString *)jigoModeValue {
	NSString *jigoModeString = @"";
	
	switch(self.jigoMode) {
		case kJigoModeUnchanged:
			jigoModeString = @"KEEP_KOMI";
			break;
		case kByoYomiTypeCanadian:
			jigoModeString = @"ALLOW_JIGO";
			break;
		case kByoYomiTypeFischer:
			jigoModeString = @"NO_JIGO";
			break;			
	}
	return jigoModeString;
}

- (NSString *)byoYomiTypeValue {
	NSString *byoYomiString = @"";
	
	switch(self.byoYomiType) {
		case kByoYomiTypeJapanese:
			byoYomiString = @"JAP";
			break;
		case kByoYomiTypeCanadian:
			byoYomiString = @"CAN";
			break;
		case kByoYomiTypeFischer:
			byoYomiString = @"FIS";
			break;			
	}
	return byoYomiString;
}

- (NSString *)byoYomiTypeString:(ByoYomiType)aByoYomiType {
	NSString *byoYomiString = @"";
	
	switch(aByoYomiType) {
		case kByoYomiTypeJapanese:
			byoYomiString = @"Japanese";
			break;
		case kByoYomiTypeCanadian:
			byoYomiString = @"Canadian";
			break;
		case kByoYomiTypeFischer:
			byoYomiString = @"Fischer";
			break;			
	}
	return byoYomiString;
}

- (NSString *)byoYomiTypeString {
	return [self byoYomiTypeString:self.byoYomiType];
}


- (NSString *)boolValue:(BOOL) value {
	if (value) {
		return @"Y";
	}
	return @"N";
}

- (NSString *)singularTimePeriodValue:(TimePeriod)value {
	NSString *timePeriodString = @"";
	
	switch(value) {
		case kTimePeriodHours:
			timePeriodString = @"hour";
			break;
		case kTimePeriodDays:
			timePeriodString = @"day";
			break;
		case kTimePeriodMonths:
			timePeriodString = @"month";
			break;			
	}
	return timePeriodString;
}


- (NSString *)timePeriodValue:(TimePeriod)unit {
	return [[self singularTimePeriodValue:unit] stringByAppendingString:@"s"];
}


- (NSString *)timePeriodString:(int)count withTimeUnit:(TimePeriod)unit {
    if (count == 1) {
        return [NSString stringWithFormat:@"%d %@", count, [self singularTimePeriodValue:unit]];
    } else {
        return [NSString stringWithFormat:@"%d %@", count, [self timePeriodValue:unit]];
    }
}

- (NSString *)komiTypeNameFromValue:(NSString *)komiTypeValue {
    if ([komiTypeValue isEqualToString:@"conv"]) {
        return @"Conventional";
    } else if ([komiTypeValue isEqualToString:@"proper"]) {
        return @"Proper";
    } else if ([komiTypeValue isEqualToString:@"nigiri"]) {
        return @"Nigiri";
    } else if ([komiTypeValue isEqualToString:@"double"]) {
        return @"Double Game";
    } else if ([komiTypeValue isEqualToString:@"black"]) {
        return @"Take White";
    } else if ([komiTypeValue isEqualToString:@"white"]) {
        return @"Take Black";
    } 
    
    return komiTypeValue;
}

- (NSString *)boolNameFromValue:(BOOL)value {
    if (value) {
        return @"Yes";
    }
    return @"No";
}

- (void)setWithDictionary:(NSDictionary *)dictionary {
    if ([dictionary[@"ruleset"] isEqualToString:@"JAPANESE"]) {
        self.ruleSet = kRuleSetJapanese;
    } else {
        self.ruleSet = kRuleSetChinese;
    }

    self.boardSize = [dictionary[@"size"] intValue];
    self.adjustedHandicap = [dictionary[@"adjust_handicap"] intValue];
    self.minHandicap = [dictionary[@"min_handicap"] intValue];
    self.maxHandicap = [dictionary[@"max_handicap"] intValue];

    if ([dictionary[@"handicap_mode"] isEqualToString:@"STD"]) {
        self.stdHandicap = YES;
    } else {
        self.stdHandicap = NO;
    }

    self.adjustedKomi = [dictionary[@"adjust_komi"] floatValue];
    self.komi = [dictionary[@"komi"] floatValue];

    if ([dictionary[@"jigo_mode"] isEqualToString:@"KEEP_KOMI"]) {
        self.jigoMode = kJigoModeUnchanged;
    } else if ([dictionary[@"jigo_mode"] isEqualToString:@"ALLOW_JIGO"]) {
        self.jigoMode = kJigoModeYes;
    } else {
        self.jigoMode = kJigoModeNo;
    }

    if ([dictionary[@"time_mode"] isEqualToString:@"FIS"]) {
        self.byoYomiType = kByoYomiTypeFischer;
    } else if ([dictionary[@"time_mode"] isEqualToString:@"JAP"]) {
        self.byoYomiType = kByoYomiTypeJapanese;
    } else {
        self.byoYomiType = kByoYomiTypeCanadian;
    }

    self.weekendClock = [dictionary[@"time_weekend_clock"] boolValue];
    self.rated = [dictionary[@"rated"] boolValue];

    self.time = dictionary[@"time_limit"];
    self.handicap = [dictionary[@"handicap"] intValue];

    if ([dictionary[@"calc_color"] isEqualToString:@"white"]) {
        self.playerColorBlack = NO;
    } else {
        self.playerColorBlack = YES;
    }
}

@end
