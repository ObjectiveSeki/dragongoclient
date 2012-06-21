//
//  NewGame.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/28/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Game.h"

typedef enum _KomiType {
	kKomiTypeConventional,
	kKomiTypeProper
} KomiType;

typedef enum _RuleSet {
	kRuleSetJapanese,
	kRuleSetChinese
} RuleSet;

typedef enum _JigoMode {
	kJigoModeUnchanged,
	kJigoModeYes,
	kJigoModeNo
} JigoMode;

typedef enum _TimePeriod {
	kTimePeriodHours,
	kTimePeriodDays,
	kTimePeriodMonths
} TimePeriod;

typedef enum _ByoYomiType {
	kByoYomiTypeJapanese,
	kByoYomiTypeCanadian,
	kByoYomiTypeFischer
} ByoYomiType;

@interface NewGame : Game {
	int numberOfGames;
	RuleSet ruleSet;
	int boardSize;
	KomiType komiType;
	int adjustedHandicap;
	int minHandicap;
	int maxHandicap;
	BOOL stdHandicap;
	float adjustedKomi;
	JigoMode jigoMode;
	int timeValue;
	TimePeriod timeUnit;
	ByoYomiType byoYomiType;
	int japaneseTimeValue;
	TimePeriod japaneseTimeUnit;
	int japaneseTimePeriods;
	int canadianTimeValue;
	TimePeriod canadianTimeUnit;
	int canadianTimePeriods;
	int fischerTimeValue;
	TimePeriod fischerTimeUnit;
	BOOL weekendClock;
	BOOL rated;
    BOOL requireRatedOpponent;
	NSString *minimumRating;
	NSString *maximumRating;
	int minRatedGames;
	int sameOpponent;
	NSString *comment;
	
	// String values, for things we can't parse
	NSString *ratedString;
	NSString *stdHandicapString;
	NSString *weekendClockString;
	NSString *komiTypeName;
	BOOL myGame;
}

@property(nonatomic, assign) int numberOfGames;
@property(nonatomic, assign) RuleSet ruleSet;
@property(nonatomic, assign) int boardSize;
@property(nonatomic, assign) KomiType komiType;
@property(nonatomic, assign) int adjustedHandicap;
@property(nonatomic, assign) int minHandicap;
@property(nonatomic, assign) int maxHandicap;
@property(nonatomic, assign) BOOL stdHandicap;
@property(nonatomic, assign) float adjustedKomi;
@property(nonatomic, assign) JigoMode jigoMode;
@property(nonatomic, assign) int timeValue;
@property(nonatomic, assign) TimePeriod timeUnit;
@property(nonatomic, assign) ByoYomiType byoYomiType;
@property(nonatomic, assign) int japaneseTimeValue;
@property(nonatomic, assign) TimePeriod japaneseTimeUnit;
@property(nonatomic, assign) int japaneseTimePeriods;
@property(nonatomic, assign) int canadianTimeValue;
@property(nonatomic, assign) TimePeriod canadianTimeUnit;
@property(nonatomic, assign) int canadianTimePeriods;
@property(nonatomic, assign) int fischerTimeValue;
@property(nonatomic, assign) TimePeriod fischerTimeUnit;
@property(nonatomic, assign) BOOL weekendClock;
@property(nonatomic, assign) BOOL rated;
@property(nonatomic, assign) BOOL requireRatedOpponent;
@property(nonatomic, copy) NSString *minimumRating;
@property(nonatomic, copy) NSString *maximumRating;
@property(nonatomic, assign) int minRatedGames;
@property(nonatomic, assign) int sameOpponent;
@property(nonatomic, copy) NSString *comment;
@property(nonatomic, copy) NSString *ratedString;
@property(nonatomic, copy) NSString *stdHandicapString;
@property(nonatomic, copy) NSString *weekendClockString;
@property(nonatomic, copy) NSString *komiTypeName;
@property(nonatomic, assign) BOOL myGame;

- (NSString *)ruleSetValue;

// The komi type, in a form value that DGS understands
- (NSString *)komiTypeValue;

// The komi type, in human-readable form
- (NSString *)komiTypeString:(KomiType)komiType;
- (NSString *)komiTypeString;

- (NSString *)jigoModeValue;
- (NSString *)byoYomiTypeValue;
- (NSString *)byoYomiTypeString;
- (NSString *)byoYomiTypeString:(ByoYomiType)byoYomiType;
- (NSString *)boolValue:(BOOL)value;
- (NSString *)timePeriodString:(int)count withTimeUnit:(TimePeriod)unit;
- (NSString *)timePeriodValue:(TimePeriod)value;

// Parsing functions from the JSON data
- (NSString *)komiTypeNameFromValue:(NSString *)komiTypeValue;
- (NSString *)boolNameFromValue:(BOOL)value;

@end
