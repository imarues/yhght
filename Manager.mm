#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <objc/runtime.h>
#include <string.h>
#include <stdint.h>

static NSString * const kMxKey   = @"tgmultimanager.mx";
static NSString * const kIQKey   = @"tgmultimanager.iqtele";
static NSString * const kLeadKey = @"tgmultimanager.lead";

static BOOL TGPref(NSString *key) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

static void TGSetPref(NSString *key, BOOL value) {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setBool:value forKey:key];
    [d synchronize];
}

static const struct mach_header_64 *TGFindImage(const char *baseName, intptr_t *outSlide) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *path = _dyld_get_image_name(i);
        if (!path) continue;
        const char *slash = strrchr(path, '/');
        const char *name = slash ? slash + 1 : path;
        if (strcmp(name, baseName) == 0) {
            const struct mach_header *h = _dyld_get_image_header(i);
            if (h && h->magic == MH_MAGIC_64) {
                if (outSlide) *outSlide = _dyld_get_image_vmaddr_slide(i);
                return (const struct mach_header_64 *)h;
            }
        }
    }
    return NULL;
}

static BOOL TGRunInitOffsets(const char *baseName) {
    static NSMutableSet<NSString *> *ran;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ ran = [NSMutableSet set]; });

    NSString *key = [NSString stringWithUTF8String:baseName];
    @synchronized (ran) {
        if ([ran containsObject:key]) return YES;
    }

    intptr_t slide = 0;
    const struct mach_header_64 *mh = TGFindImage(baseName, &slide);
    if (!mh) {
        NSLog(@"[TGMulti] %@ image not found", key);
        return NO;
    }

    const uint8_t *cursor = (const uint8_t *)mh + sizeof(struct mach_header_64);
    const struct section_64 *target = NULL;

    for (uint32_t i = 0; i < mh->ncmds; i++) {
        const struct load_command *lc = (const struct load_command *)cursor;
        if (lc->cmd == LC_SEGMENT_64) {
            const struct segment_command_64 *seg = (const struct segment_command_64 *)cursor;
            const struct section_64 *sec = (const struct section_64 *)(seg + 1);
            for (uint32_t j = 0; j < seg->nsects; j++) {
                if (strncmp(sec[j].sectname, "__init_offsets", 16) == 0) {
                    target = &sec[j];
                    break;
                }
            }
        }
        if (target) break;
        if (lc->cmdsize < sizeof(struct load_command)) break;
        cursor += lc->cmdsize;
    }

    if (!target || target->size == 0 || (target->size % sizeof(uint32_t)) != 0) {
        NSLog(@"[TGMulti] %@ has no usable __init_offsets", key);
        return NO;
    }

    const uint32_t *offsets = (const uint32_t *)(slide + (uintptr_t)target->addr);
    size_t count = (size_t)(target->size / sizeof(uint32_t));
    NSLog(@"[TGMulti] Running %zu initializers for %@", count, key);

    for (size_t i = 0; i < count; i++) {
        uintptr_t address = (uintptr_t)mh + (uintptr_t)offsets[i];
        void (*fn)(void) = (void (*)(void))address;
        @try {
            fn();
        } @catch (NSException *e) {
            NSLog(@"[TGMulti] %@ initializer %zu exception: %@", key, i, e);
        }
    }

    @synchronized (ran) { [ran addObject:key]; }
    return YES;
}

@interface TGMultiPanelController : UIViewController
@end

@implementation TGMultiPanelController {
    UISwitch *_mx;
    UISwitch *_iq;
    UISwitch *_lead;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"Telegram Multi Manager";

    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closePanel)];
    self.navigationItem.rightBarButtonItem = done;

    UILabel *subtitle = [UILabel new];
    subtitle.translatesAutoresizingMaskIntoConstraints = NO;
    subtitle.text = @"Choose the tweaks to load on the next Telegram launch.";
    subtitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    subtitle.textColor = [UIColor secondaryLabelColor];
    subtitle.numberOfLines = 0;

    UIStackView *stack = [[UIStackView alloc] init];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12.0;

    _mx = [self addRow:@"Mx" detail:@"Telegram tweak" key:kMxKey stack:stack];
    _iq = [self addRow:@"iQTele" detail:@"Telegram tweak · ElleKit/Substrate" key:kIQKey stack:stack];
    _lead = [self addRow:@"Lead" detail:@"Telegram tweak" key:kLeadKey stack:stack];

    UIButton *off = [UIButton buttonWithType:UIButtonTypeSystem];
    off.translatesAutoresizingMaskIntoConstraints = NO;
    [off setTitle:@"Disable All" forState:UIControlStateNormal];
    off.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    [off addTarget:self action:@selector(disableAll) forControlEvents:UIControlEventTouchUpInside];

    UILabel *footer = [UILabel new];
    footer.translatesAutoresizingMaskIntoConstraints = NO;
    footer.text = @"Changes are saved immediately. Fully close Telegram from the app switcher and reopen it to apply. Tweaks already loaded cannot be safely unloaded from the current process.";
    footer.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    footer.textColor = [UIColor secondaryLabelColor];
    footer.numberOfLines = 0;

    [self.view addSubview:subtitle];
    [self.view addSubview:stack];
    [self.view addSubview:off];
    [self.view addSubview:footer];

    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [subtitle.topAnchor constraintEqualToAnchor:g.topAnchor constant:24],
        [subtitle.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:20],
        [subtitle.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-20],

        [stack.topAnchor constraintEqualToAnchor:subtitle.bottomAnchor constant:22],
        [stack.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-16],

        [off.topAnchor constraintEqualToAnchor:stack.bottomAnchor constant:24],
        [off.centerXAnchor constraintEqualToAnchor:g.centerXAnchor],

        [footer.topAnchor constraintEqualToAnchor:off.bottomAnchor constant:22],
        [footer.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:20],
        [footer.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-20],
    ]];
}

- (UISwitch *)addRow:(NSString *)title detail:(NSString *)detail key:(NSString *)key stack:(UIStackView *)stack {
    UIView *card = [UIView new];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = [UIColor secondarySystemBackgroundColor];
    card.layer.cornerRadius = 14.0;

    UILabel *name = [UILabel new];
    name.translatesAutoresizingMaskIntoConstraints = NO;
    name.text = title;
    name.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];

    UILabel *desc = [UILabel new];
    desc.translatesAutoresizingMaskIntoConstraints = NO;
    desc.text = detail;
    desc.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    desc.textColor = [UIColor secondaryLabelColor];

    UISwitch *sw = [UISwitch new];
    sw.translatesAutoresizingMaskIntoConstraints = NO;
    sw.on = TGPref(key);
    sw.accessibilityIdentifier = key;
    [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];

    [card addSubview:name];
    [card addSubview:desc];
    [card addSubview:sw];
    [NSLayoutConstraint activateConstraints:@[
        [card.heightAnchor constraintGreaterThanOrEqualToConstant:72],
        [name.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [name.topAnchor constraintEqualToAnchor:card.topAnchor constant:13],
        [name.trailingAnchor constraintLessThanOrEqualToAnchor:sw.leadingAnchor constant:-12],
        [desc.leadingAnchor constraintEqualToAnchor:name.leadingAnchor],
        [desc.topAnchor constraintEqualToAnchor:name.bottomAnchor constant:3],
        [desc.trailingAnchor constraintLessThanOrEqualToAnchor:sw.leadingAnchor constant:-12],
        [sw.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [sw.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
    ]];
    [stack addArrangedSubview:card];
    return sw;
}

- (void)switchChanged:(UISwitch *)sender {
    NSString *key = sender.accessibilityIdentifier;
    if (key.length) TGSetPref(key, sender.isOn);
}

- (void)disableAll {
    _mx.on = NO; _iq.on = NO; _lead.on = NO;
    TGSetPref(kMxKey, NO);
    TGSetPref(kIQKey, NO);
    TGSetPref(kLeadKey, NO);
}

- (void)closePanel {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end

static UIWindow *TGKeyWindow(void) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) continue;
        UIWindowScene *ws = (UIWindowScene *)scene;
        if (ws.activationState != UISceneActivationStateForegroundActive) continue;
        for (UIWindow *w in ws.windows) if (w.isKeyWindow) return w;
        for (UIWindow *w in ws.windows) if (!w.hidden && w.alpha > 0.0) return w;
    }
    return nil;
}

static UIViewController *TGTopController(UIViewController *vc) {
    if (!vc) return nil;
    if (vc.presentedViewController) return TGTopController(vc.presentedViewController);
    if ([vc isKindOfClass:UINavigationController.class]) return TGTopController(((UINavigationController *)vc).visibleViewController);
    if ([vc isKindOfClass:UITabBarController.class]) return TGTopController(((UITabBarController *)vc).selectedViewController);
    return vc;
}

@interface TGGestureTarget : NSObject
@end
@implementation TGGestureTarget
- (void)open:(UILongPressGestureRecognizer *)g {
    if (g.state != UIGestureRecognizerStateBegan) return;
    UIWindow *w = TGKeyWindow();
    UIViewController *top = TGTopController(w.rootViewController);
    if (!top || [top isKindOfClass:TGMultiPanelController.class]) return;

    TGMultiPanelController *panel = [TGMultiPanelController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:panel];
    nav.modalPresentationStyle = UIModalPresentationPageSheet;
    if (@available(iOS 15.0, *)) {
        UISheetPresentationController *sheet = nav.sheetPresentationController;
        sheet.detents = @[[UISheetPresentationControllerDetent mediumDetent], [UISheetPresentationControllerDetent largeDetent]];
        sheet.prefersGrabberVisible = YES;
    }
    [top presentViewController:nav animated:YES completion:nil];
}
@end

static TGGestureTarget *gTarget;
static const void *kTGGestureMarker = &kTGGestureMarker;

static void TGAttachGesture(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *w = TGKeyWindow();
        if (!w || objc_getAssociatedObject(w, kTGGestureMarker)) return;
        if (!gTarget) gTarget = [TGGestureTarget new];
        UILongPressGestureRecognizer *g = [[UILongPressGestureRecognizer alloc] initWithTarget:gTarget action:@selector(open:)];
        g.numberOfTouchesRequired = 3;
        g.minimumPressDuration = 0.05;
        g.cancelsTouchesInView = NO;
        g.delaysTouchesBegan = NO;
        g.delaysTouchesEnded = NO;
        [w addGestureRecognizer:g];
        objc_setAssociatedObject(w, kTGGestureMarker, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    });
}

static void TGApplySelectedTweaks(void) {
    if (TGPref(kMxKey))   TGRunInitOffsets("Mx.dylib");
    if (TGPref(kIQKey))   TGRunInitOffsets("iQTele.dylib");
    if (TGPref(kLeadKey)) TGRunInitOffsets("Lead.dylib");
}

__attribute__((constructor)) static void TGMultiManagerInit(void) {
    @autoreleasepool {
        TGApplySelectedTweaks();
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(__unused NSNotification *note) {
                TGAttachGesture();
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ TGAttachGesture(); });
            }];
            TGAttachGesture();
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ TGAttachGesture(); });
        });
    }
}
