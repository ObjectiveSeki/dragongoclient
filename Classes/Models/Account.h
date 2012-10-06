

#import <Foundation/Foundation.h>


@interface Account : NSObject {

}

@property(nonatomic, copy) NSString *username;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *password;
@property(nonatomic, copy) NSString *passwordConfirm;
@property(nonatomic, assign) BOOL *acceptTerms;

@end
