

#import <Foundation/Foundation.h>


@interface Account : NSObject {
	NSString *username;
	NSString *name;
	NSString *password;
	NSString *passwordConfirm;
	BOOL *acceptTerms;
}

@property(nonatomic, copy) NSString *username;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *password;
@property(nonatomic, copy) NSString *passwordConfirm;
@property(nonatomic, assign) BOOL *acceptTerms;

@end
