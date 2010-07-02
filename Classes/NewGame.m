//
//  NewGame.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/28/10.
//  Copyright 2010 Avvo. All rights reserved.
//fischer

#import "NewGame.h"


@implementation NewGame
@synthesize numberOfGames;
@synthesize ruleSet;
@synthesize boardSize;
@synthesize komiType;
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
@synthesize	minimumRating;
@synthesize maximumRating;
@synthesize minRatedGames;
@synthesize sameOpponent;
@synthesize comment;

- (id)init {
	if ([super init]) {
		numberOfGames = 1;
		boardSize = 19;
		maxHandicap = 21;
		stdHandicap = YES;
		timeValue = 90;
		timeUnit = kTimePeriodDays;
		japaneseTimeValue = 1;
		japaneseTimeUnit = kTimePeriodDays;
		japaneseTimePeriods = 10;
		canadianTimeValue = 1;
		canadianTimeUnit = kTimePeriodDays;
		canadianTimePeriods = 15;
		fischerTimeValue = 1;
		fischerTimeUnit = kTimePeriodDays;
		weekendClock = YES;
		rated = YES;
		minimumRating = @"30 kyu";
		maximumRating = @"9 dan";
	}
	return self;
}

- (NSString *)ruleSetValue {
	NSString *ruleSetString;
	
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
	NSString *komiTypeString;
	
	switch(self.komiType) {
		case kKomiTypeConventional:
			komiTypeString = @"conv";
			break;
		case kKomiTypeProper:
			komiTypeString = @"proper";
			break;
	}
	return komiTypeString;
}

- (NSString *)komiTypeString:(KomiType)aKomiType {
	NSString *komiTypeString;
	
	switch(aKomiType) {
		case kKomiTypeConventional:
			komiTypeString = @"Conventional";
			break;
		case kKomiTypeProper:
			komiTypeString = @"Proper";
			break;
	}
	return komiTypeString;
}

- (NSString *)komiTypeString {
	return [self komiTypeString:self.komiType];
}

- (NSString *)jigoModeValue {
	NSString *jigoModeString;
	
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
	NSString *byoYomiString;
	
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
	NSString *byoYomiString;
	
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

- (NSString *)timePeriodValue:(TimePeriod)value {
	NSString *timePeriodString;
	
	switch(value) {
		case kTimePeriodHours:
			timePeriodString = @"hours";
			break;
		case kTimePeriodDays:
			timePeriodString = @"days";
			break;
		case kTimePeriodMonths:
			timePeriodString = @"months";
			break;			
	}
	return timePeriodString;
}


- (void)dealloc {
    self.comment = nil;
	self.minimumRating = nil;
	self.maximumRating = nil;
    [super dealloc];
}

@end
