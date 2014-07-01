#import <UIKit/UIKit.h>
#import <CaptainHook/CaptainHook.h>

#define PreferencesChangedNotification "com.autopear.ncdatecustomizer.changed"
#define PreferencesFilePath @"/var/mobile/Library/Preferences/com.autopear.ncdatecustomizer.plist"

@interface SBTodayTableHeaderView : UIView {
    UILabel *_dateLabel;
}
+ (UIFont *)defaultFont;
+ (UIColor *)defaultTextColor;
+ (id)defaultBackgroundColor;
- (void)layoutSubviews;
- (CGSize)sizeThatFits:(CGSize)size;
- (CGRect)dateLabelFrame; //iOS 7.0
- (CGRect)dateLabelFrameForBounds:(CGRect)bounds force:(BOOL)force; //iOS 7.1
- (void)updateContent; //iOS 7.0
- (id)dateHeaderAttributedString; //iOS 7.0
- (id)dateHeader; //iOS 7.0
- (id)dateHeaderAttributedStringOnSingleLine:(BOOL)line; //iOS 7.1
- (id)dateHeaderOnSingleLine:(BOOL)line; //iOS 7.1
- (void)dealloc;
- (SBTodayTableHeaderView *)initWithFrame:(CGRect)frame;
@end

@interface SBTodayViewController : UIViewController {
	NSMutableArray* _visibleSectionIDs;
}
- (id)firstSection; //iOS 7.0
- (void)widget:(id)widget didUpdatePreferredSize:(CGSize)size;
- (void)updateTableHeader; //iOS 7.0
- (void)forceUpdateTableHeader; //iOS 7.1
- (void)updateTableHeaderIfNecessary; //iOS 7.1
- (void)_updateTableHeader:(BOOL)header;
- (id)todayTableHeaderView;
- (id)infoForWidgetSection:(id)widgetSection;
- (void)viewWillLayoutSubviews;
@end

@interface SBNotificationCenterViewController : UIViewController {
    SBTodayViewController *_todayViewController;
}
@end

@interface SBNotificationCenterController : NSObject {
}
@property(readonly, nonatomic) SBNotificationCenterViewController *viewController;
+ (SBNotificationCenterController *)sharedInstance;
@end


@interface SpringBoard : UIApplication
-(void)relaunchSpringBoard;
@end

@interface NCAlertDelegate : NSObject <UIAlertViewDelegate>
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@end

@implementation NCAlertDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex)
        [(SpringBoard *)[objc_getClass("SpringBoard") sharedApplication] relaunchSpringBoard];
}
@end

static BOOL enabled = YES;
static BOOL visible = YES;
static BOOL singleLine = YES;
static CGFloat leftMargin = 47.0f;
static CGFloat red = 1.0f;
static CGFloat green = 1.0f;
static CGFloat blue = 1.0f;
static CGFloat alpha = 1.0f;

static SBTodayTableHeaderView *headerView = nil;
static UILabel *dateLabel = nil;
static SBTodayViewController *todayController = nil;
static NCAlertDelegate *alertDelegate = nil;
static NSString *alertTitle = nil, *alertMessage = nil, *alertCancel = nil, *alertRespring = nil;

static void LoadPreferences(BOOL init) {
	NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:PreferencesFilePath];

    if ([preferences objectForKey:@"enabled"])
        enabled = [[preferences objectForKey:@"enabled"] boolValue];
    else
        enabled = YES;

    BOOL visibilityChanged = NO;
    if (init) {
        if ([preferences objectForKey:@"visible"])
            visible = [[preferences objectForKey:@"visible"] boolValue];
        else
            visible = YES;
    } else {
        BOOL tmp = [preferences objectForKey:@"visible"] ? [[preferences objectForKey:@"visible"] boolValue] : YES;
        if (tmp != visible) {
            visible = tmp;
            visibilityChanged = YES;
        }
    }

    if ([preferences objectForKey:@"singleLine"])
        singleLine = [[preferences objectForKey:@"singleLine"] boolValue];
    else
        singleLine = YES;

    if ([preferences objectForKey:@"leftMargin"])
        leftMargin = [[preferences objectForKey:@"leftMargin"] floatValue];
    else
        leftMargin = 47.0f;

    if ([preferences objectForKey:@"red"])
        red = [[preferences objectForKey:@"red"] floatValue];
    else
        red = 1.0f;

    if ([preferences objectForKey:@"green"])
        green = [[preferences objectForKey:@"green"] floatValue];
    else
        red = 1.0f;

    if ([preferences objectForKey:@"blue"])
        blue = [[preferences objectForKey:@"blue"] floatValue];
    else
        red = 1.0f;

    if ([preferences objectForKey:@"alpha"])
        alpha = [[preferences objectForKey:@"alpha"] floatValue];
    else
        red = 1.0f;

    if (headerView && dateLabel) {
        if (enabled) {
            dateLabel.adjustsFontSizeToFitWidth = NO;
            dateLabel.font = [%c(SBTodayTableHeaderView) defaultFont];

            if ([headerView respondsToSelector:@selector(updateContent)])
                [headerView updateContent];

            if (singleLine) {
                dateLabel.numberOfLines = 1;
                dateLabel.adjustsFontSizeToFitWidth = YES;
            } else {
                dateLabel.numberOfLines = 2;
            }

            CGRect frame = dateLabel.frame;
            frame.origin.x = leftMargin;
            frame.size.width = headerView.frame.size.width - leftMargin;
            dateLabel.frame = frame;

        } else {
            dateLabel.adjustsFontSizeToFitWidth = NO;
            dateLabel.font = [%c(SBTodayTableHeaderView) defaultFont];
            dateLabel.numberOfLines = 2;

            if ([headerView respondsToSelector:@selector(updateContent)])
                [headerView updateContent];

            CGRect frame = dateLabel.frame;
            frame.origin.x = 47.0f;
            frame.size.width = headerView.frame.size.width - 47.0f;
            dateLabel.frame = frame;
        }

        dateLabel.textColor = [%c(SBTodayTableHeaderView) defaultTextColor];

        [headerView layoutSubviews];

        if (!todayController) {
            SBNotificationCenterViewController *viewController = [%c(SBNotificationCenterController) sharedInstance].viewController;
            todayController = CHIvar(viewController, _todayViewController, SBTodayViewController *);
        }
        if ([todayController respondsToSelector:@selector(updateContent)])
            [todayController updateTableHeader];
        if ([todayController respondsToSelector:@selector(forceUpdateTableHeader)])
            [todayController forceUpdateTableHeader];

        dateLabel.textAlignment = NSTextAlignmentRight;
    }

    if (visibilityChanged && enabled) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:alertDelegate cancelButtonTitle:alertCancel otherButtonTitles:alertRespring, nil];
        [alert show];
        [alert release];
    }
}

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    LoadPreferences(NO);
}

%hook SBTodayTableDateHeader

- (SBTodayTableDateHeader *)initWithDateString:(NSString *)dateString ordinalRange:(NSRange)range shouldSuperscriptOrdinal:(BOOL)ordinal {
    if (enabled && singleLine) {
        NSString *newDateString = [dateString stringByReplacingOccurrencesOfString:@"\n" withString:@" "];

        return %orig(newDateString, range, NO);
    }

    return %orig(dateString, range, ordinal);
}

%end

%hook SBTodayTableHeaderView

- (SBTodayTableHeaderView *)initWithFrame:(CGRect)frame {
    SBTodayTableHeaderView *view = %orig(frame);
    headerView = view;

    UILabel* _dateLabel = CHIvar(view, _dateLabel, UILabel *);
    dateLabel = _dateLabel;
    dateLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;


    alertDelegate = [[[NCAlertDelegate alloc] init] retain];

    NSBundle *localizedBundle = [[NSBundle alloc] initWithPath:@"/Library/PreferenceLoader/Preferences/NCDateCustomizer"];
    alertTitle = [NSLocalizedStringFromTableInBundle(@"NC Date Customizer", @"NCDateCustomizer", localizedBundle, @"NC Date Customizer") retain];
    alertMessage = [NSLocalizedStringFromTableInBundle(@"You must respring to change the visibility.", @"NCDateCustomizer", localizedBundle, @"You must respring to change the visibility.") retain];
    alertCancel = [NSLocalizedStringFromTableInBundle(@"Later", @"NCDateCustomizer", localizedBundle, @"Later") retain];
    alertRespring = [NSLocalizedStringFromTableInBundle(@"Respring", @"NCDateCustomizer", localizedBundle, @"Respring") retain];
    [localizedBundle release];

    LoadPreferences(YES);

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);

    if (enabled && !visible) {
        [view release];
        dateLabel = nil;
        headerView = nil;
        return nil;
    } else
        return view;
}

- (void)updateContent {
    if (!enabled || visible)
        %orig;
    else
        [dateLabel setText:@""];
}

- (CGRect)dateLabelFrame {
    CGRect frame = %orig;
    if (enabled) {
        frame.origin.x = leftMargin;
        frame.size.width = self.frame.size.width - leftMargin;
    }
    return frame;
}

- (CGRect)dateLabelFrameForBounds:(CGRect)bounds force:(BOOL)force {
    CGRect frame = %orig(bounds, force);
    if (enabled) {
        frame.origin.x = leftMargin;
        frame.size.width = self.frame.size.width - leftMargin;
    }
    return frame;
}

+ (id)defaultTextColor {
    if (enabled)
        return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
    else
        return %orig;
}

%end
