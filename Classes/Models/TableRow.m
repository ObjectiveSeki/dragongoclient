
#import "TableRow.h"


@implementation TableRow

- (id)init {
	if (self = [super init]) {
		self.identifier = NSStringFromClass([self class]);
		self.selectable = YES;
	}
	return self;
}


@end
