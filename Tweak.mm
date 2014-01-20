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
- (CGRect)dateLabelFrame;
- (void)updateContent;
- (id)dateHeaderAttributedString;
- (id)dateHeader;
- (void)dealloc;
- (SBTodayTableHeaderView *)initWithFrame:(CGRect)frame;
@end

@interface SBTodayViewController {
}
- (void)updateTableHeader;
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

static BOOL enabled = YES;
static BOOL singleLine = YES;
static CGFloat leftMargin = 47.0f;
static CGFloat red = 1.0f;
static CGFloat green = 1.0f;
static CGFloat blue = 1.0f;
static CGFloat alpha = 1.0f;

static SBTodayTableHeaderView *headerView = nil;
static UILabel *dateLabel = nil;
static SBTodayViewController *todayController = nil;

static void LoadPreferences() {
	NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:PreferencesFilePath];

    if ([preferences objectForKey:@"enabled"])
        enabled = [[preferences objectForKey:@"enabled"] boolValue];
    else
        enabled = YES;
    
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
        [todayController updateTableHeader];
    }
}

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    LoadPreferences();
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

    LoadPreferences();
    
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);

    return view;
}

- (CGRect)dateLabelFrame {
    CGRect frame = %orig;
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
