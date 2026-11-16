#import "DeveloperNoteViewController.h"
#import <SafariServices/SafariServices.h>

@implementation DeveloperNoteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"A note from the developer";
    self.view.backgroundColor = [UIColor colorNamed:@"AppBackground"];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];

    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scrollView];
    UIStackView *content = [[UIStackView alloc] init];
    content.axis = UILayoutConstraintAxisVertical;
    content.spacing = 22;
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:content];
    [NSLayoutConstraint activateConstraints:@[
        [scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [content.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor constant:28],
        [content.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor constant:-28],
        [content.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor constant:24],
        [content.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor constant:-24],
        [content.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor constant:-48]
    ]];

    [self addText:@"A new chapter for \nDragon Go Client" style:UIFontTextStyleTitle1 to:content];
    [self addText:@"Hello, and thank you for being here." style:UIFontTextStyleHeadline to:content];
    [self addText:@"Some of you have been playing here for years, including through a long stretch without updates. I’m Niclas, the app’s maintainer, and I’m bringing Dragon Go Client up to date." style:UIFontTextStyleBody to:content];
    [self addText:@"Push notifications are working again, and the app is getting some care for modern iOS." style:UIFontTextStyleBody to:content];
//    [self addText:@"This new chapter builds on Justin Weiss’s work and the open-source project he shared with the community. Thank you, Justin, and everyone who has kept playing and supporting the app." style:UIFontTextStyleBody to:content];
    [self addText:@"There’s more to come. I’m taking it one update at a time, and I’m glad you’re here." style:UIFontTextStyleBody to:content];

    [self addText:@"— Niclas" style:UIFontTextStyleBody to:content];

    // Keep the letter available offline. Only show the invitation when a real signup URL is configured.
    NSString *address = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"DGSCommunityURL"];
    NSURL *url = address.length ? [NSURL URLWithString:address] : nil;
    if ([url.scheme isEqualToString:@"https"] && url.host.length) {
        [self addText:@"Help shape what comes next!" style:UIFontTextStyleHeadline to:content];
        [self addText:@"Interested in trying new versions and sharing feedback? Visit the app’s website and use the contact link to let me know." style:UIFontTextStyleBody to:content];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        UIButtonConfiguration *configuration = [UIButtonConfiguration filledButtonConfiguration];
        configuration.title = @"Visit Dragon Go Client’s website";
        configuration.baseBackgroundColor = [UIColor systemOrangeColor];
        configuration.baseForegroundColor = [UIColor whiteColor];
        configuration.contentInsets = NSDirectionalEdgeInsetsMake(14, 16, 14, 16);
        button.configuration = configuration;
        button.titleLabel.numberOfLines = 0;
        [button addTarget:self action:@selector(openWebsite) forControlEvents:UIControlEventTouchUpInside];
        [content addArrangedSubview:button];
    }
}

- (void)addText:(NSString *)text style:(UIFontTextStyle)style to:(UIStackView *)stack {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont preferredFontForTextStyle:style];
    label.adjustsFontForContentSizeCategory = YES;
    label.textColor = [UIColor labelColor];
    label.numberOfLines = 0;
    if ([style isEqualToString:UIFontTextStyleTitle1] || [style isEqualToString:UIFontTextStyleHeadline]) {
        label.accessibilityTraits |= UIAccessibilityTraitHeader;
    }
    [stack addArrangedSubview:label];
}

- (void)openWebsite {
    NSURL *url = [NSURL URLWithString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"DGSCommunityURL"]];
    SFSafariViewController *browser = [[SFSafariViewController alloc] initWithURL:url];
    [self presentViewController:browser animated:YES completion:nil];
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
