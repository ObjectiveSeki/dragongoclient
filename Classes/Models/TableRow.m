
#import "TableRow.h"


@implementation TableRow

@synthesize cellClass;
@synthesize cellInit;
@synthesize cellSetup;
@synthesize cellTouched;
@synthesize identifier;
@synthesize selectable;

- (id)init {
	if (self = [super init]) {
		self.identifier = NSStringFromClass([self class]);
		self.selectable = YES;
	}
	return self;
}


@end
