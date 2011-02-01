
#import "TableRow.h"


@implementation TableRow

@synthesize cellClass;
@synthesize cellInit;
@synthesize cellSetup;
@synthesize cellTouched;
@synthesize identifier;
@synthesize selectable;

- (id)init {
	if ([super init]) {
		self.identifier = NSStringFromClass([self class]);
		self.selectable = YES;
	}
	return self;
}

- (void)dealloc {
	self.cellInit = nil;
	self.cellSetup = nil;
	self.cellTouched = nil;
	self.identifier = nil;
	[super dealloc];
}

@end
