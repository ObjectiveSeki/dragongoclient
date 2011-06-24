
#import "BooleanCell.h"


@implementation BooleanCell

@synthesize toggleSwitch;
@synthesize onChanged;

- (id)init {
    if ((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([self class])])) {
        UISwitch *theSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
		self.toggleSwitch = theSwitch;
		self.accessoryView = theSwitch;
		self.selectionStyle = UITableViewCellSelectionStyleNone;
        [theSwitch release];
    }
    return self;
}

- (void)dealloc {
	self.toggleSwitch = nil;
	self.onChanged = nil;
    [super dealloc];
}

@end
