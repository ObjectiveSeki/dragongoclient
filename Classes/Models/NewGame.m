//
//  NewGame.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/28/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//fischer

#import "NewGame.h"


@implementation NewGame
@synthesize numberOfGames;
@synthesize ruleSet;
@synthesize boardSize;
@synthesize komiType;
@synthesize manualKomiType;
@synthesize adjustedHandicap;
@synthesize minHandicap;
@synthesize maxHandicap;
@synthesize stdHandicap;
@synthesize adjustedKomi;
@synthesize jigoMode;
@synthesize timeValue;
@synthesize timeUnit;
@synthesize byoYomiType;
@synthesize japaneseTimeValue;
@synthesize japaneseTimeUnit;
@synthesize japaneseTimePeriods;
@synthesize canadianTimeValue;
@synthesize canadianTimeUnit;
@synthesize canadianTimePeriods;
@synthesize fischerTimeValue;
@synthesize fischerTimeUnit;
@synthesize weekendClock;
@synthesize	rated;
@synthesize requireRatedOpponent;
@synthesize	minimumRating;
@synthesize maximumRating;
@synthesize minRatedGames;
@synthesize sameOpponent;
@synthesize comment;

@synthesize ratedString;
@synthesize stdHandicapString;
@synthesize weekendClockString;
@synthesize komiTypeName;
@synthesize myGame;

- (id)init {
	if (self = [super init]) {
		numberOfGames = 1;
		boardSize = 19;
		maxHandicap = 21;
		stdHandicap = YES;
        komi = 6.5;
        handicap = 0;
		timeValue = 30;
		timeUnit = kTimePeriodDays;
        byoYomiType = kByoYomiTypeFischer;
		japaneseTimeValue = 1;
		japaneseTimeUnit = kTimePeriodDays;
		japaneseTimePeriods = 10;
		canadianTimeValue = 15;
		canadianTimeUnit = kTimePeriodDays;
		canadianTimePeriods = 15;
		fischerTimeValue = 1;
		fischerTimeUnit = kTimePeriodDays;
		weekendClock = YES;
		rated = NO;
        requireRatedOpponent = NO;
		minimumRating = @"30 kyu";
		maximumRating = @"9 dan";
		myGame = true;
	}
	return self;
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

- (void)dealloc {
    self.comment = nil;
	self.minimumRating = nil;
	self.maximumRating = nil;
	
	self.ratedString = nil;
	self.stdHandicapString = nil;
	self.weekendClockString = nil;
	self.komiTypeName = nil;
    [super dealloc];
}

@end
