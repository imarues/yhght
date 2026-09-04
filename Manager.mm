#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <objc/runtime.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>

static NSString * const kMxKey   = @"multitele.mx";
static NSString * const kIQKey   = @"multitele.iqtele";
static NSString * const kLeadKey = @"multitele.lead";
static NSString * const kLangKey = @"multitele.language";

static BOOL MTPref(NSString *key) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

static void MTSetPref(NSString *key, BOOL value) {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setBool:value forKey:key];
    [d synchronize];
}

static NSString *MTLanguage(void) {
    NSString *v = [[NSUserDefaults standardUserDefaults] stringForKey:kLangKey];
    return v.length ? v : @"ar";
}

static BOOL MTIsRTL(void) {
    NSString *l = MTLanguage();
    return [l isEqualToString:@"ar"] || [l isEqualToString:@"fa"];
}

static NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *MTStrings(void) {
    static NSDictionary *all;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        all = @{
            @"ar": @{
                @"done": @"تم",
                @"language": @"اللغة",
                @"subtitle": @"اختار التعديل المناسب لك ثم اضغط تم لاعادة تشغيل التطبيق وتفعيل ميزات التعديل.",
                @"mxDetail": @"بعد تفعيل هذا التعديل اذهب لاعدادات التيليكرام واضغط ضغطة مطوله على \"أسال سوالاً\"",
                @"iqDetail": @"بعد تفعيل هذا التعديل اذهب لاعدادات التيليكرام بجانب الملف الشخصي",
                @"leadDetail": @"بعد تفعيل هذا التعديل اذهب لاعدادات التيليكرام واضغط ضغطة مطوله على \"أسال سوالاً\"",
                @"kiraSection": @"تعديل كيرا بلس",
                @"kiraPlus": @"كيرا بلس",
                @"certificate": @"للتواصل وشراء الشهادة المدفوعه",
                @"chooseLanguage": @"اختر لغة اللوحة",
                @"languageChangedTitle": @"تم تغيير اللغة",
                @"languageChangedMessage": @"سيتم إغلاق Telegram الآن. افتح التطبيق مرة أخرى لتظهر اللوحة باللغة الجديدة.",
                @"ok": @"موافق",
                @"cancel": @"إلغاء"
            },
            @"en": @{
                @"done": @"Done", @"language": @"Language",
                @"subtitle": @"Choose the tweak that suits you, then tap Done to restart the app and activate the tweak features.",
                @"mxDetail": @"After enabling this tweak, go to Telegram Settings and long-press \"Ask a Question\".",
                @"iqDetail": @"After enabling this tweak, go to Telegram Settings; its option appears next to your profile.",
                @"leadDetail": @"After enabling this tweak, go to Telegram Settings and long-press \"Ask a Question\".",
                @"kiraSection": @"Kira Plus Tweaks", @"kiraPlus": @"Kira Plus",
                @"certificate": @"Contact & buy a paid certificate", @"chooseLanguage": @"Choose panel language", @"languageChangedTitle": @"Language changed", @"languageChangedMessage": @"Telegram will now close. Reopen it to use the panel in the new language.", @"ok": @"OK", @"cancel": @"Cancel"
            },
            @"fr": @{
                @"done": @"Terminé", @"language": @"Langue",
                @"subtitle": @"Choisissez le tweak qui vous convient, puis appuyez sur Terminé pour redémarrer l’application et activer ses fonctionnalités.",
                @"mxDetail": @"Après avoir activé ce tweak, allez dans les réglages de Telegram et maintenez \"Poser une question\".",
                @"iqDetail": @"Après avoir activé ce tweak, allez dans les réglages de Telegram ; son option apparaît à côté du profil.",
                @"leadDetail": @"Après avoir activé ce tweak, allez dans les réglages de Telegram et maintenez \"Poser une question\".",
                @"kiraSection": @"Tweaks Kira Plus", @"kiraPlus": @"Kira Plus",
                @"certificate": @"Contact et achat du certificat payant", @"chooseLanguage": @"Choisir la langue du panneau", @"languageChangedTitle": @"Langue modifiée", @"languageChangedMessage": @"Telegram va maintenant se fermer. Rouvrez-le pour utiliser la nouvelle langue.", @"ok": @"OK", @"cancel": @"Annuler"
            },
            @"es": @{
                @"done": @"Listo", @"language": @"Idioma",
                @"subtitle": @"Elige el tweak adecuado y pulsa Listo para reiniciar la aplicación y activar sus funciones.",
                @"mxDetail": @"Después de activar este tweak, ve a Ajustes de Telegram y mantén pulsado \"Hacer una pregunta\".",
                @"iqDetail": @"Después de activar este tweak, ve a Ajustes de Telegram; su opción aparece junto al perfil.",
                @"leadDetail": @"Después de activar este tweak, ve a Ajustes de Telegram y mantén pulsado \"Hacer una pregunta\".",
                @"kiraSection": @"Tweaks Kira Plus", @"kiraPlus": @"Kira Plus",
                @"certificate": @"Contacto y compra del certificado de pago", @"chooseLanguage": @"Elegir idioma del panel", @"languageChangedTitle": @"Idioma cambiado", @"languageChangedMessage": @"Telegram se cerrará ahora. Vuelve a abrirlo para usar el panel en el nuevo idioma.", @"ok": @"Aceptar", @"cancel": @"Cancelar"
            },
            @"zh": @{
                @"done": @"完成", @"language": @"语言",
                @"subtitle": @"选择适合你的插件，然后点按“完成”以重新启动应用并启用插件功能。",
                @"mxDetail": @"启用此插件后，进入 Telegram 设置，长按“提问”。",
                @"iqDetail": @"启用此插件后，进入 Telegram 设置；其选项会显示在个人资料旁边。",
                @"leadDetail": @"启用此插件后，进入 Telegram 设置，长按“提问”。",
                @"kiraSection": @"Kira Plus 插件", @"kiraPlus": @"Kira Plus",
                @"certificate": @"联系并购买付费证书", @"chooseLanguage": @"选择面板语言", @"languageChangedTitle": @"语言已更改", @"languageChangedMessage": @"Telegram 现在将关闭。重新打开后即可使用新语言。", @"ok": @"确定", @"cancel": @"取消"
            },
            @"tr": @{
                @"done": @"Bitti", @"language": @"Dil",
                @"subtitle": @"Size uygun tweak’i seçin, ardından uygulamayı yeniden başlatıp özellikleri etkinleştirmek için Bitti’ye dokunun.",
                @"mxDetail": @"Bu tweak’i etkinleştirdikten sonra Telegram Ayarları’na gidin ve \"Soru Sor\" seçeneğine uzun basın.",
                @"iqDetail": @"Bu tweak’i etkinleştirdikten sonra Telegram Ayarları’na gidin; seçenek profilinizin yanında görünür.",
                @"leadDetail": @"Bu tweak’i etkinleştirdikten sonra Telegram Ayarları’na gidin ve \"Soru Sor\" seçeneğine uzun basın.",
                @"kiraSection": @"Kira Plus Tweak’leri", @"kiraPlus": @"Kira Plus",
                @"certificate": @"İletişim ve ücretli sertifika satın alma", @"chooseLanguage": @"Panel dilini seçin", @"languageChangedTitle": @"Dil değiştirildi", @"languageChangedMessage": @"Telegram şimdi kapanacak. Yeni dili kullanmak için uygulamayı tekrar açın.", @"ok": @"Tamam", @"cancel": @"İptal"
            },
            @"fa": @{
                @"done": @"تمام", @"language": @"زبان",
                @"subtitle": @"تغییر مناسب را انتخاب کنید، سپس برای راه‌اندازی مجدد برنامه و فعال شدن امکانات روی «تمام» بزنید.",
                @"mxDetail": @"پس از فعال‌سازی این تغییر، به تنظیمات Telegram بروید و روی «پرسیدن سؤال» لمس طولانی کنید.",
                @"iqDetail": @"پس از فعال‌سازی این تغییر، به تنظیمات Telegram بروید؛ گزینه آن کنار پروفایل نمایش داده می‌شود.",
                @"leadDetail": @"پس از فعال‌سازی این تغییر، به تنظیمات Telegram بروید و روی «پرسیدن سؤال» لمس طولانی کنید.",
                @"kiraSection": @"تغییرات Kira Plus", @"kiraPlus": @"Kira Plus",
                @"certificate": @"ارتباط و خرید گواهی پولی", @"chooseLanguage": @"زبان پنل را انتخاب کنید", @"languageChangedTitle": @"زبان تغییر کرد", @"languageChangedMessage": @"Telegram اکنون بسته می‌شود. برای استفاده از زبان جدید دوباره برنامه را باز کنید.", @"ok": @"تأیید", @"cancel": @"لغو"
            },
            @"ru": @{
                @"done": @"Готово", @"language": @"Язык",
                @"subtitle": @"Выберите нужный твик и нажмите «Готово», чтобы перезапустить приложение и активировать его функции.",
                @"mxDetail": @"После включения твика откройте настройки Telegram и удерживайте «Задать вопрос».",
                @"iqDetail": @"После включения твика откройте настройки Telegram; его пункт появится рядом с профилем.",
                @"leadDetail": @"После включения твика откройте настройки Telegram и удерживайте «Задать вопрос».",
                @"kiraSection": @"Твики Kira Plus", @"kiraPlus": @"Kira Plus",
                @"certificate": @"Связь и покупка платного сертификата", @"chooseLanguage": @"Выберите язык панели", @"languageChangedTitle": @"Язык изменён", @"languageChangedMessage": @"Telegram сейчас закроется. Откройте приложение снова, чтобы использовать новый язык.", @"ok": @"OK", @"cancel": @"Отмена"
            },
            @"vi": @{
                @"done": @"Xong", @"language": @"Ngôn ngữ",
                @"subtitle": @"Chọn tweak phù hợp rồi nhấn Xong để khởi động lại ứng dụng và kích hoạt các tính năng của tweak.",
                @"mxDetail": @"Sau khi bật tweak này, vào Cài đặt Telegram và nhấn giữ \"Đặt câu hỏi\".",
                @"iqDetail": @"Sau khi bật tweak này, vào Cài đặt Telegram; tùy chọn của nó xuất hiện cạnh hồ sơ.",
                @"leadDetail": @"Sau khi bật tweak này, vào Cài đặt Telegram và nhấn giữ \"Đặt câu hỏi\".",
                @"kiraSection": @"Tweak Kira Plus", @"kiraPlus": @"Kira Plus",
                @"certificate": @"Liên hệ & mua chứng chỉ trả phí", @"chooseLanguage": @"Chọn ngôn ngữ bảng điều khiển", @"languageChangedTitle": @"Đã đổi ngôn ngữ", @"languageChangedMessage": @"Telegram sẽ đóng ngay bây giờ. Hãy mở lại ứng dụng để dùng ngôn ngữ mới.", @"ok": @"OK", @"cancel": @"Hủy"
            },
            @"id": @{
                @"done": @"Selesai", @"language": @"Bahasa",
                @"subtitle": @"Pilih tweak yang sesuai lalu ketuk Selesai untuk memulai ulang aplikasi dan mengaktifkan fiturnya.",
                @"mxDetail": @"Setelah mengaktifkan tweak ini, buka Pengaturan Telegram lalu tekan lama \"Ajukan Pertanyaan\".",
                @"iqDetail": @"Setelah mengaktifkan tweak ini, buka Pengaturan Telegram; opsinya muncul di samping profil.",
                @"leadDetail": @"Setelah mengaktifkan tweak ini, buka Pengaturan Telegram lalu tekan lama \"Ajukan Pertanyaan\".",
                @"kiraSection": @"Tweak Kira Plus", @"kiraPlus": @"Kira Plus",
                @"certificate": @"Kontak & beli sertifikat berbayar", @"chooseLanguage": @"Pilih bahasa panel", @"languageChangedTitle": @"Bahasa diubah", @"languageChangedMessage": @"Telegram akan ditutup sekarang. Buka kembali aplikasi untuk menggunakan bahasa baru.", @"ok": @"OK", @"cancel": @"Batal"
            }
        };
    });
    return all;
}

static NSString *MTL(NSString *key) {
    NSDictionary *lang = MTStrings()[MTLanguage()] ?: MTStrings()[@"ar"];
    return lang[key] ?: MTStrings()[@"en"][key] ?: key;
}

static void MTSaveLanguage(NSString *code) {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setObject:code forKey:kLangKey];
    [d synchronize];
}

static void MTExitForApply(void) {
    [[NSUserDefaults standardUserDefaults] synchronize];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        exit(0);
    });
}

static const struct mach_header_64 *MTFindImage(const char *baseName, intptr_t *outSlide) {
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

static BOOL MTRunInitOffsets(const char *baseName) {
    static NSMutableSet<NSString *> *ran;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ ran = [NSMutableSet set]; });

    NSString *key = [NSString stringWithUTF8String:baseName];
    @synchronized (ran) { if ([ran containsObject:key]) return YES; }

    intptr_t slide = 0;
    const struct mach_header_64 *mh = MTFindImage(baseName, &slide);
    if (!mh) { NSLog(@"[MultiTele] %@ image not found", key); return NO; }

    const uint8_t *cursor = (const uint8_t *)mh + sizeof(struct mach_header_64);
    const struct section_64 *target = NULL;
    for (uint32_t i = 0; i < mh->ncmds; i++) {
        const struct load_command *lc = (const struct load_command *)cursor;
        if (lc->cmd == LC_SEGMENT_64) {
            const struct segment_command_64 *seg = (const struct segment_command_64 *)cursor;
            const struct section_64 *sec = (const struct section_64 *)(seg + 1);
            for (uint32_t j = 0; j < seg->nsects; j++) {
                if (strncmp(sec[j].sectname, "__init_offsets", 16) == 0) { target = &sec[j]; break; }
            }
        }
        if (target) break;
        if (lc->cmdsize < sizeof(struct load_command)) break;
        cursor += lc->cmdsize;
    }

    if (!target || target->size == 0 || (target->size % sizeof(uint32_t)) != 0) {
        NSLog(@"[MultiTele] %@ has no usable __init_offsets", key); return NO;
    }

    const uint32_t *offsets = (const uint32_t *)(slide + (uintptr_t)target->addr);
    size_t count = (size_t)(target->size / sizeof(uint32_t));
    for (size_t i = 0; i < count; i++) {
        uintptr_t address = (uintptr_t)mh + (uintptr_t)offsets[i];
        void (*fn)(void) = (void (*)(void))address;
        @try { fn(); } @catch (NSException *e) { NSLog(@"[MultiTele] %@ initializer %zu exception: %@", key, i, e); }
    }
    @synchronized (ran) { [ran addObject:key]; }
    return YES;
}

static UIImageView *MTAsyncImage(NSString *urlString) {
    UIImageView *iv = [UIImageView new];
    iv.translatesAutoresizingMaskIntoConstraints = NO;
    iv.contentMode = UIViewContentModeScaleAspectFill;
    iv.clipsToBounds = YES;
    iv.layer.cornerRadius = 12.0;
    if (@available(iOS 13.0, *)) iv.image = [UIImage systemImageNamed:@"photo"];
    NSURL *url = [NSURL URLWithString:urlString];
    if (url) {
        [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            (void)response;
            if (!data.length || error) return;
            UIImage *img = [UIImage imageWithData:data];
            if (!img) return;
            dispatch_async(dispatch_get_main_queue(), ^{ iv.image = img; });
        }] resume];
    }
    return iv;
}

@interface MultiTelePanelController : UIViewController
@end

@implementation MultiTelePanelController {
    UISwitch *_mx;
    UISwitch *_iq;
    UISwitch *_lead;
    UIBarButtonItem *_languageButton;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"MultiTele";
    self.view.semanticContentAttribute = MTIsRTL() ? UISemanticContentAttributeForceRightToLeft : UISemanticContentAttributeForceLeftToRight;

    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:MTL(@"done") style:UIBarButtonItemStyleDone target:self action:@selector(doneAndRestart)];

    UIImage *globe = nil;
    if (@available(iOS 13.0, *)) globe = [UIImage systemImageNamed:@"globe"];
    _languageButton = globe ? [[UIBarButtonItem alloc] initWithImage:globe style:UIBarButtonItemStylePlain target:self action:@selector(showLanguages)] : [[UIBarButtonItem alloc] initWithTitle:MTL(@"language") style:UIBarButtonItemStylePlain target:self action:@selector(showLanguages)];
    self.navigationController.navigationBar.semanticContentAttribute = MTIsRTL() ? UISemanticContentAttributeForceRightToLeft : UISemanticContentAttributeForceLeftToRight;
    if (MTIsRTL()) {
        self.navigationItem.leftBarButtonItem = done;
        self.navigationItem.rightBarButtonItem = _languageButton;
    } else {
        self.navigationItem.rightBarButtonItem = done;
        self.navigationItem.leftBarButtonItem = _languageButton;
    }

    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.alwaysBounceVertical = YES;
    [self.view addSubview:scroll];

    UIStackView *content = [UIStackView new];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    content.axis = UILayoutConstraintAxisVertical;
    content.spacing = 14.0;
    content.layoutMargins = UIEdgeInsetsMake(20, 16, 28, 16);
    content.layoutMarginsRelativeArrangement = YES;
    [scroll addSubview:content];

    UILabel *subtitle = [UILabel new];
    subtitle.text = MTL(@"subtitle");
    subtitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    subtitle.textColor = [UIColor secondaryLabelColor];
    subtitle.numberOfLines = 0;
    subtitle.textAlignment = MTIsRTL() ? NSTextAlignmentRight : NSTextAlignmentLeft;
    [content addArrangedSubview:subtitle];
    [content setCustomSpacing:18 afterView:subtitle];

    _mx = [self addTweakCard:@"Mx" detail:MTL(@"mxDetail") key:kMxKey to:content];
    _iq = [self addTweakCard:@"iQTele" detail:MTL(@"iqDetail") key:kIQKey to:content];
    _lead = [self addTweakCard:@"Lead" detail:MTL(@"leadDetail") key:kLeadKey to:content];

    UILabel *section = [UILabel new];
    section.text = MTL(@"kiraSection");
    section.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    section.textAlignment = NSTextAlignmentCenter;
    section.textColor = [UIColor labelColor];
    [content setCustomSpacing:24 afterView:content.arrangedSubviews.lastObject];
    [content addArrangedSubview:section];
    [content setCustomSpacing:8 afterView:section];

    [content addArrangedSubview:[self linkCardWithTitle:MTL(@"kiraPlus") linkText:@"t.me/ikiraplus" openURL:@"https://t.me/ikiraplus" imageURL:@"https://raw.githubusercontent.com/ikiraplus/ipastore/main/images/IMG_2509.jpeg"]];
    [content addArrangedSubview:[self linkCardWithTitle:MTL(@"certificate") linkText:@"t.me/ikira18" openURL:@"https://t.me/ikira18" imageURL:@"https://raw.githubusercontent.com/ikiraplus/ipastore/main/images/IMG_2510.jpeg"]];
    [content addArrangedSubview:[self linkCardWithTitle:@"ipaStore" linkText:@"ipastore.pages.dev" openURL:@"https://ipastore.pages.dev" imageURL:@"https://raw.githubusercontent.com/ikiraplus/ipastore/main/images/IMG_2508.jpeg"]];

    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:g.topAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [content.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor],
        [content.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor],
        [content.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor],
        [content.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor]
    ]];
}

- (UISwitch *)addTweakCard:(NSString *)title detail:(NSString *)detail key:(NSString *)key to:(UIStackView *)stack {
    UIView *card = [UIView new];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = [UIColor secondarySystemBackgroundColor];
    card.layer.cornerRadius = 16.0;

    UILabel *name = [UILabel new];
    name.translatesAutoresizingMaskIntoConstraints = NO;
    name.text = title;
    name.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];

    UILabel *desc = [UILabel new];
    desc.translatesAutoresizingMaskIntoConstraints = NO;
    desc.text = detail;
    desc.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    desc.textColor = [UIColor secondaryLabelColor];
    desc.numberOfLines = 0;
    desc.textAlignment = MTIsRTL() ? NSTextAlignmentRight : NSTextAlignmentLeft;

    UISwitch *sw = [UISwitch new];
    sw.translatesAutoresizingMaskIntoConstraints = NO;
    sw.on = MTPref(key);
    sw.accessibilityIdentifier = key;
    [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];

    [card addSubview:name]; [card addSubview:desc]; [card addSubview:sw];
    [NSLayoutConstraint activateConstraints:@[
        [card.heightAnchor constraintGreaterThanOrEqualToConstant:104],
        [name.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18],
        [name.topAnchor constraintEqualToAnchor:card.topAnchor constant:15],
        [name.trailingAnchor constraintLessThanOrEqualToAnchor:sw.leadingAnchor constant:-12],
        [desc.leadingAnchor constraintEqualToAnchor:name.leadingAnchor],
        [desc.trailingAnchor constraintEqualToAnchor:name.trailingAnchor],
        [desc.topAnchor constraintEqualToAnchor:name.bottomAnchor constant:6],
        [desc.bottomAnchor constraintLessThanOrEqualToAnchor:card.bottomAnchor constant:-14],
        [sw.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18],
        [sw.centerYAnchor constraintEqualToAnchor:card.centerYAnchor]
    ]];
    [stack addArrangedSubview:card];
    return sw;
}

- (UIView *)linkCardWithTitle:(NSString *)title linkText:(NSString *)linkText openURL:(NSString *)openURL imageURL:(NSString *)imageURL {
    UIControl *card = [UIControl new];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = [UIColor secondarySystemBackgroundColor];
    card.layer.cornerRadius = 16.0;
    card.accessibilityIdentifier = openURL;
    [card addTarget:self action:@selector(openLink:) forControlEvents:UIControlEventTouchUpInside];

    UIImageView *iv = MTAsyncImage(imageURL);
    UILabel *titleLabel = [UILabel new];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = title;
    titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    titleLabel.numberOfLines = 2;
    titleLabel.textAlignment = MTIsRTL() ? NSTextAlignmentRight : NSTextAlignmentLeft;

    UIButton *link = [UIButton buttonWithType:UIButtonTypeSystem];
    link.translatesAutoresizingMaskIntoConstraints = NO;
    [link setTitle:linkText forState:UIControlStateNormal];
    link.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    [link setTitleColor:[UIColor tertiaryLabelColor] forState:UIControlStateNormal];
    link.contentHorizontalAlignment = MTIsRTL() ? UIControlContentHorizontalAlignmentRight : UIControlContentHorizontalAlignmentLeft;
    link.accessibilityIdentifier = openURL;
    [link addTarget:self action:@selector(openURLButton:) forControlEvents:UIControlEventTouchUpInside];

    [card addSubview:iv]; [card addSubview:titleLabel]; [card addSubview:link];
    [NSLayoutConstraint activateConstraints:@[
        [card.heightAnchor constraintGreaterThanOrEqualToConstant:76],
        [iv.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:12],
        [iv.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
        [iv.widthAnchor constraintEqualToConstant:52],
        [iv.heightAnchor constraintEqualToConstant:52],
        [titleLabel.leadingAnchor constraintEqualToAnchor:iv.trailingAnchor constant:12],
        [titleLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [titleLabel.topAnchor constraintEqualToAnchor:card.topAnchor constant:14],
        [link.leadingAnchor constraintEqualToAnchor:titleLabel.leadingAnchor],
        [link.trailingAnchor constraintEqualToAnchor:titleLabel.trailingAnchor],
        [link.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:4],
        [link.bottomAnchor constraintLessThanOrEqualToAnchor:card.bottomAnchor constant:-12]
    ]];
    return card;
}

- (void)switchChanged:(UISwitch *)sender {
    NSString *key = sender.accessibilityIdentifier;
    if (!key.length) return;

    // Mx and Lead are mutually exclusive because they overlap internally.
    // Turning one ON immediately turns the other OFF. iQTele is independent.
    if (sender.isOn && [key isEqualToString:kMxKey]) {
        _lead.on = NO;
        MTSetPref(kLeadKey, NO);
    } else if (sender.isOn && [key isEqualToString:kLeadKey]) {
        _mx.on = NO;
        MTSetPref(kMxKey, NO);
    }

    MTSetPref(key, sender.isOn);
}

- (void)doneAndRestart {
    // Defensive guard: never persist Mx + Lead as enabled together.
    if (_mx.isOn && _lead.isOn) {
        _lead.on = NO;
    }
    MTSetPref(kMxKey, _mx.isOn);
    MTSetPref(kIQKey, _iq.isOn);
    MTSetPref(kLeadKey, _lead.isOn);
    MTExitForApply();
}

- (void)openLink:(UIControl *)sender {
    NSURL *url = [NSURL URLWithString:sender.accessibilityIdentifier ?: @""];
    if (url) [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void)openURLButton:(UIButton *)sender {
    NSURL *url = [NSURL URLWithString:sender.accessibilityIdentifier ?: @""];
    if (url) [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void)showLanguages {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:MTL(@"chooseLanguage") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray<NSArray<NSString *> *> *langs = @[
        @[@"العربية", @"ar"], @[@"English", @"en"], @[@"Français", @"fr"], @[@"Español", @"es"], @[@"中文", @"zh"],
        @[@"Türkçe", @"tr"], @[@"فارسی", @"fa"], @[@"Русский", @"ru"], @[@"Tiếng Việt", @"vi"], @[@"Bahasa Indonesia", @"id"]
    ];
    NSString *current = MTLanguage();
    for (NSArray<NSString *> *pair in langs) {
        NSString *name = pair[0], *code = pair[1];
        NSString *label = [code isEqualToString:current] ? [NSString stringWithFormat:@"✓ %@", name] : name;
        [a addAction:[UIAlertAction actionWithTitle:label style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            if (![code isEqualToString:MTLanguage()]) {
                MTSaveLanguage(code);
                UIAlertController *confirm = [UIAlertController alertControllerWithTitle:MTL(@"languageChangedTitle") message:MTL(@"languageChangedMessage") preferredStyle:UIAlertControllerStyleAlert];
                [confirm addAction:[UIAlertAction actionWithTitle:MTL(@"ok") style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *okAction) {
                    MTExitForApply();
                }]];
                [self presentViewController:confirm animated:YES completion:nil];
            }
        }]];
    }
    [a addAction:[UIAlertAction actionWithTitle:MTL(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *pop = a.popoverPresentationController;
    if (pop) { pop.barButtonItem = _languageButton; }
    [self presentViewController:a animated:YES completion:nil];
}
@end

static UIWindow *MTKeyWindow(void) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) continue;
        UIWindowScene *ws = (UIWindowScene *)scene;
        if (ws.activationState != UISceneActivationStateForegroundActive) continue;
        for (UIWindow *w in ws.windows) if (w.isKeyWindow) return w;
        for (UIWindow *w in ws.windows) if (!w.hidden && w.alpha > 0.0) return w;
    }
    return nil;
}

static UIViewController *MTTopController(UIViewController *vc) {
    if (!vc) return nil;
    if (vc.presentedViewController) return MTTopController(vc.presentedViewController);
    if ([vc isKindOfClass:UINavigationController.class]) return MTTopController(((UINavigationController *)vc).visibleViewController);
    if ([vc isKindOfClass:UITabBarController.class]) return MTTopController(((UITabBarController *)vc).selectedViewController);
    return vc;
}

@interface MTGestureTarget : NSObject
@end
@implementation MTGestureTarget
- (void)open:(UILongPressGestureRecognizer *)g {
    if (g.state != UIGestureRecognizerStateBegan) return;
    UIWindow *w = MTKeyWindow();
    UIViewController *top = MTTopController(w.rootViewController);
    if (!top || [top isKindOfClass:MultiTelePanelController.class]) return;
    MultiTelePanelController *panel = [MultiTelePanelController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:panel];
    nav.modalPresentationStyle = UIModalPresentationPageSheet;
    if (@available(iOS 15.0, *)) {
        UISheetPresentationController *sheet = nav.sheetPresentationController;
        sheet.detents = @[[UISheetPresentationControllerDetent largeDetent]];
        sheet.prefersGrabberVisible = YES;
    }
    [top presentViewController:nav animated:YES completion:nil];
}
@end

static MTGestureTarget *gTarget;
static const void *kMTGestureMarker = &kMTGestureMarker;

static void MTAttachGesture(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *w = MTKeyWindow();
        if (!w || objc_getAssociatedObject(w, kMTGestureMarker)) return;
        if (!gTarget) gTarget = [MTGestureTarget new];
        UILongPressGestureRecognizer *g = [[UILongPressGestureRecognizer alloc] initWithTarget:gTarget action:@selector(open:)];
        g.numberOfTouchesRequired = 3;
        g.minimumPressDuration = 0.05;
        g.cancelsTouchesInView = NO;
        g.delaysTouchesBegan = NO;
        g.delaysTouchesEnded = NO;
        [w addGestureRecognizer:g];
        objc_setAssociatedObject(w, kMTGestureMarker, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    });
}

static void MTApplySelectedTweaks(void) {
    BOOL mx = MTPref(kMxKey);
    BOOL iq = MTPref(kIQKey);
    BOOL lead = MTPref(kLeadKey);

    // Migrate/sanitize old preferences that may have both conflicting tweaks ON.
    // Keep Mx and turn Lead OFF in that legacy state.
    if (mx && lead) {
        lead = NO;
        MTSetPref(kLeadKey, NO);
    }

    if (mx)   MTRunInitOffsets("Mx.dylib");
    if (iq)   MTRunInitOffsets("iQTele.dylib");
    if (lead) MTRunInitOffsets("Lead.dylib");
}

__attribute__((constructor)) static void MultiTeleInit(void) {
    @autoreleasepool {
        MTApplySelectedTweaks();
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(__unused NSNotification *note) {
                MTAttachGesture();
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ MTAttachGesture(); });
            }];
            MTAttachGesture();
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ MTAttachGesture(); });
        });
    }
}
