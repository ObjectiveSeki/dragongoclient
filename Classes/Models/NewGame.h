//
//  NewGame.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/28/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <Foundation/Foundation.h>

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

@interface NewGame : NSObject {
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
	NSString *minimumRating;
	NSString *maximumRating;
	int minRatedGames;
	int sameOpponent;
	NSString *comment;
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
@property(nonatomic, copy) NSString *minimumRating;
@property(nonatomic, copy) NSString *maximumRating;
@property(nonatomic, assign) int minRatedGames;
@property(nonatomic, assign) int sameOpponent;
@property(nonatomic, copy) NSString *comment;

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
- (NSString *)timePeriodValue:(TimePeriod)value;

@end
