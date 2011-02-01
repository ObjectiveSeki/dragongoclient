
#import "BooleanCell.h"


@implementation BooleanCell

@synthesize toggleSwitch;
@synthesize onChanged;

- (id)init {
    if ((self = [super initWithStyle:UITableViewStylePlain reuseIdentifier:NSStringFromClass([self class])])) {
		self.toggleSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
		self.accessoryView = self.toggleSwitch;
		self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)dealloc {
	self.toggleSwitch = nil;
	self.onChanged = nil;
    [super dealloc];
}

@end
