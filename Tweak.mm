#import <UIKit/UIKit.h>
#import <CaptainHook/CaptainHook.h>

#define PreferencesName "com.autopear.ncdatecustomizer"
#define PreferencesChangedNotification "com.autopear.ncdatecustomizer.changed"
#define PreferencesFilePath @"/var/mobile/Library/Preferences/com.autopear.ncdatecustomizer.plist"

@interface SBTodayTableHeaderView : UIView {
    UILabel *_dateLabel;
    UILabel* _lunarDateLabel; // iOS 8
}
+ (UIFont *)defaultLunarDateFont; //iOS 8
+ (UIFont *)defaultDateFont; //iOS 8
+ (UIFont *)defaultDateFontForMode:(long long)mode; //iOS 9
+ (UIFont *)defaultFont; //iOS 7
+ (UIColor *)defaultTextColor; //iOS 7
+ (id)defaultBackgroundColor;
- (void)_layoutLunarDateLabel; //iOS 8
- (CGRect)_lunarDateLabelFrameForBounds:(CGRect)bounds; //iOS 8
- (void)_layoutDateLabel; //iOS 8
- (id)lunarDateHeaderString; //iOS 8
- (BOOL)showsLunarDate; //iOS 8
- (id)lunarCalendarIdentifier; //iOS 8
- (void)layoutSubviews;
- (CGSize)sizeThatFits:(CGSize)size;
- (CGRect)dateLabelFrame; //iOS 7.0
- (CGRect)dateLabelFrameForBounds:(CGRect)bounds force:(BOOL)force; //iOS 7.1 & 8
- (void)updateContent; //iOS 7.0
- (id)dateHeaderAttributedString; //iOS 7.0
- (id)dateHeader; //iOS 7.0
- (id)dateHeaderAttributedStringOnSingleLine:(BOOL)line; //iOS 7.1 & 8
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
- (void)forceUpdateTableHeader; //iOS 7.1 & 8
- (void)updateTableHeaderIfNecessary; //iOS 7.1 & 8
- (void)_updateTableHeader:(BOOL)header;
- (id)todayTableHeaderView;
- (id)infoForWidgetSection:(id)widgetSection;
- (void)viewWillLayoutSubviews;
@end

@interface SBNotificationCenterLayoutViewController : UIViewController {
    SBTodayViewController *_todayViewController; //iOS 9
}
@end

@interface SBNotificationCenterViewController : UIViewController {
    SBTodayViewController *_todayViewController;
    SBNotificationCenterLayoutViewController *_layoutViewController; //iOS 9
}
@end

@interface SBNotificationCenterController : NSObject
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
static BOOL lunarEnabled = YES; // iOS 8
static int textAlignment = 0;
static CGFloat leftMargin = 47.0f;
static CGFloat rightMargin = 0.0f;
static CGFloat red = 1.0f;
static CGFloat green = 1.0f;
static CGFloat blue = 1.0f;
static CGFloat alpha = 1.0f;

static SBTodayTableHeaderView *headerView = nil;
static UILabel *dateLabel = nil;
static UILabel *lunarLabel = nil;
static SBTodayViewController *todayController = nil;
static NCAlertDelegate *alertDelegate = nil;
static NSString *alertTitle = nil, *alertMessage = nil, *alertCancel = nil, *alertRespring = nil;

static BOOL readPreferenceBOOL(NSString *key, BOOL defaultValue) {
    return !CFPreferencesCopyAppValue((__bridge CFStringRef)key, CFSTR(PreferencesName)) ? defaultValue : [(id)CFBridgingRelease(CFPreferencesCopyAppValue((__bridge CFStringRef)key, CFSTR(PreferencesName))) boolValue];
}

static CGFloat readPreferenceFloat(NSString *key, CGFloat defaultValue) {
    return !CFPreferencesCopyAppValue((__bridge CFStringRef)key, CFSTR(PreferencesName)) ? defaultValue : [(id)CFBridgingRelease(CFPreferencesCopyAppValue((__bridge CFStringRef)key, CFSTR(PreferencesName))) floatValue];
}

static CGFloat readPreferenceInt(NSString *key, int defaultValue) {
    return !CFPreferencesCopyAppValue((__bridge CFStringRef)key, CFSTR(PreferencesName)) ? defaultValue : [(id)CFBridgingRelease(CFPreferencesCopyAppValue((__bridge CFStringRef)key, CFSTR(PreferencesName))) floatValue];
}

static void LoadPreferences(BOOL init) {
    BOOL visibilityChanged = NO;

    if (kCFCoreFoundationVersionNumber >= 1140.10) {
        CFPreferencesAppSynchronize(CFSTR(PreferencesName));

        enabled =  readPreferenceBOOL(@"enabled", YES);

        if (init)
            visible = readPreferenceBOOL(@"visible", YES);
        else {
            BOOL tmp = readPreferenceBOOL(@"visible", YES);
            if (tmp != visible) {
                visible = tmp;
                visibilityChanged = YES;
            }
        }

        singleLine = readPreferenceBOOL(@"singleLine", YES);

        lunarEnabled = readPreferenceBOOL(@"lunarEnabled", YES);

        textAlignment = readPreferenceInt(@"textAlignment", 0);

        leftMargin = readPreferenceFloat(@"leftMargin", 47.0f);

        rightMargin = readPreferenceFloat(@"rightMargin", 0.0f);

        red = readPreferenceFloat(@"red", 1.0f);

        green = readPreferenceFloat(@"green", 1.0f);

        blue = readPreferenceFloat(@"blue", 10.f);

        alpha = readPreferenceFloat(@"alpha", 10.f);
    } else {
        NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:PreferencesFilePath];

        if ([preferences objectForKey:@"enabled"])
            enabled = [[preferences objectForKey:@"enabled"] boolValue];
        else
            enabled = YES;

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

        if ([preferences objectForKey:@"textAlignment"])
            textAlignment = [[preferences objectForKey:@"textAlignment"] intValue];
        else
            textAlignment = 0;

        if ([preferences objectForKey:@"leftMargin"])
            leftMargin = [[preferences objectForKey:@"leftMargin"] floatValue];
        else
            leftMargin = 47.0f;

        if ([preferences objectForKey:@"rightMargin"])
            rightMargin = [[preferences objectForKey:@"rightMargin"] floatValue];
        else
            rightMargin = 0.0f;

        if ([preferences objectForKey:@"red"])
            red = [[preferences objectForKey:@"red"] floatValue];
        else
            red = 1.0f;

        if ([preferences objectForKey:@"green"])
            green = [[preferences objectForKey:@"green"] floatValue];
        else
            green = 1.0f;

        if ([preferences objectForKey:@"blue"])
            blue = [[preferences objectForKey:@"blue"] floatValue];
        else
            blue = 1.0f;

        if ([preferences objectForKey:@"alpha"])
            alpha = [[preferences objectForKey:@"alpha"] floatValue];
        else
            alpha = 1.0f;
    }

    if (headerView && dateLabel) {
        if (enabled) {
            dateLabel.adjustsFontSizeToFitWidth = NO;
            if ([%c(SBTodayTableHeaderView) respondsToSelector:@selector(defaultFont)])
                dateLabel.font = [%c(SBTodayTableHeaderView) defaultFont];
            else if ([%c(SBTodayTableHeaderView) respondsToSelector:@selector(defaultDateFont)])
                dateLabel.font = [%c(SBTodayTableHeaderView) defaultDateFont];
            else
                dateLabel.font = [%c(SBTodayTableHeaderView) defaultDateFontForMode:0];

            if ([headerView respondsToSelector:@selector(updateContent)])
                [headerView updateContent];

            if (singleLine) {
                dateLabel.numberOfLines = 1;
                dateLabel.adjustsFontSizeToFitWidth = YES;
            } else {
                dateLabel.numberOfLines = 2;
            }

            NSTextAlignment align;
            if (textAlignment == 1)
                align = NSTextAlignmentCenter;
            else if (textAlignment == 2)
                align = NSTextAlignmentRight;
            else
                align = NSTextAlignmentLeft;

            CGRect frame = dateLabel.frame;
            frame.origin.x = leftMargin;
            frame.size.width = headerView.frame.size.width - leftMargin - rightMargin;
            dateLabel.frame = frame;
            dateLabel.textAlignment = align;

            if (lunarLabel) {
                CGRect lunarFrame = lunarLabel.frame;
                lunarFrame.origin.x = leftMargin;
                lunarFrame.size.width = headerView.frame.size.width - leftMargin - rightMargin;
                lunarLabel.frame = lunarFrame;
                lunarLabel.textAlignment = align;
            }
        } else {
            dateLabel.adjustsFontSizeToFitWidth = NO;
            if ([%c(SBTodayTableHeaderView) respondsToSelector:@selector(defaultFont)])
                dateLabel.font = [%c(SBTodayTableHeaderView) defaultFont];
            else if ([%c(SBTodayTableHeaderView) respondsToSelector:@selector(defaultDateFont)])
                dateLabel.font = [%c(SBTodayTableHeaderView) defaultDateFont];
            else
                dateLabel.font = [%c(SBTodayTableHeaderView) defaultDateFontForMode:0];
            dateLabel.numberOfLines = 2;

            if ([headerView respondsToSelector:@selector(updateContent)])
                [headerView updateContent];

            CGRect frame = dateLabel.frame;
            frame.origin.x = 47.0f;
            frame.size.width = headerView.frame.size.width - 47.0f;
            dateLabel.frame = frame;

            if (lunarLabel) {
                CGRect lunarFrame = lunarLabel.frame;
                lunarFrame.origin.x = 47.0f;
                lunarFrame.size.width = headerView.frame.size.width - 47.0f;
                lunarLabel.frame = lunarFrame;
            }
        }

        dateLabel.textColor = [%c(SBTodayTableHeaderView) defaultTextColor];
        if (lunarLabel)
            lunarLabel.textColor = [%c(SBTodayTableHeaderView) defaultTextColor];

        [headerView layoutSubviews];

        if (!todayController) {
            SBNotificationCenterViewController *viewController = [%c(SBNotificationCenterController) sharedInstance].viewController;
            if (kCFCoreFoundationVersionNumber < 1240.10) //iOS 7 & 8
                todayController = CHIvar(viewController, _todayViewController, SBTodayViewController *);
            else { //iOS 9
                SBNotificationCenterLayoutViewController *nclvc = CHIvar(viewController, _layoutViewController, SBNotificationCenterLayoutViewController *);
                todayController = CHIvar(nclvc, _todayViewController, SBTodayViewController *);
            }
        }
        if ([todayController respondsToSelector:@selector(updateContent)])
            [todayController updateTableHeader];
        if ([todayController respondsToSelector:@selector(forceUpdateTableHeader)])
            [todayController forceUpdateTableHeader];
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

    if (kCFCoreFoundationVersionNumber >= 1140.10) {
        UILabel* _lunarDateLabel = CHIvar(view, _lunarDateLabel, UILabel *);
        lunarLabel = _lunarDateLabel;
    }

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
        frame.size.width = self.frame.size.width - leftMargin - rightMargin;
    }
    return frame;
}

- (CGRect)dateLabelFrameForBounds:(CGRect)bounds force:(BOOL)force {
    CGRect frame = %orig(bounds, force);
    if (enabled) {
        frame.origin.x = leftMargin;
        frame.size.width = self.frame.size.width - leftMargin - rightMargin;
    }
    return frame;
}

- (CGRect)_lunarDateLabelFrameForBounds:(CGRect)bounds {
    CGRect frame = %orig(bounds);
    if (enabled) {
        frame.origin.x = leftMargin;
        frame.size.width = self.frame.size.width - leftMargin - rightMargin;
    }
    return frame;
}

- (BOOL)showsLunarDate {
    BOOL ret = %orig;
    if (enabled)
        return lunarEnabled ? ret : NO;
    else
        return ret;
}

- (void)layoutSubviews {
    %orig;
    if (enabled) {
        NSTextAlignment align;
        if (textAlignment == 1)
            align = NSTextAlignmentCenter;
        else if (textAlignment == 2)
            align = NSTextAlignmentRight;
        else
            align = NSTextAlignmentLeft;
        if (dateLabel)
            dateLabel.textAlignment = align;
        if (lunarLabel)
            lunarLabel.textAlignment = align;
    }
}

+ (id)defaultTextColor {
    if (enabled)
        return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
    else
        return %orig;
}

%end
