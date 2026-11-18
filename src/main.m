#import <Cocoa/Cocoa.h>
#import <PreferencePanes/PreferencePanes.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>

@interface KerioAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>
@property (strong, nonatomic) NSWindow *window;
@property (strong, nonatomic) NSPreferencePane *prefPane;
@property (strong, nonatomic) NSTextField *serviceStatusLabel;
@property (strong, nonatomic) NSButton *serviceActionButton;
@property (strong, nonatomic) NSTimer *statusTimer;
@property (assign, nonatomic) BOOL isServiceRunning;
@end

@implementation KerioAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [self setupMenus];
    [self setupWindow];
    [self startPeriodicCheck];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    [self.window makeKeyAndOrderFront:nil];
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [self.statusTimer invalidate];
    if (self.prefPane) {
        [self.prefPane willUnselect];
        [self.prefPane didUnselect];
    }
}

- (void)setupMenus {
    NSMenu *mainMenuBar = [[NSMenu alloc] init];
    [NSApp setMainMenu:mainMenuBar];

    // App Menu
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
    [mainMenuBar addItem:appMenuItem];
    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"Kerio Control"];
    [appMenu addItemWithTitle:@"درباره کریو کنترل (About Kerio Control)" action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Hide Kerio Control" action:@selector(hide:) keyEquivalent:@"h"];
    NSMenuItem *hideOthers = [[NSMenuItem alloc] initWithTitle:@"Hide Others" action:@selector(hideOtherApplications:) keyEquivalent:@"h"];
    [hideOthers setKeyEquivalentModifierMask:(NSEventModifierFlagOption | NSEventModifierFlagCommand)];
    [appMenu addItem:hideOthers];
    [appMenu addItemWithTitle:@"Show All" action:@selector(unhideAllApplications:) keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"خروج (Quit Kerio Control)" action:@selector(terminate:) keyEquivalent:@"q"];
    [appMenuItem setSubmenu:appMenu];

    // Edit Menu (Essential for Cut/Copy/Paste/Select All in text boxes)
    NSMenuItem *editMenuItem = [[NSMenuItem alloc] init];
    [mainMenuBar addItem:editMenuItem];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    [editMenu addItemWithTitle:@"Undo" action:@selector(undo:) keyEquivalent:@"z"];
    NSMenuItem *redo = [[NSMenuItem alloc] initWithTitle:@"Redo" action:@selector(redo:) keyEquivalent:@"Z"];
    [editMenu addItem:redo];
    [editMenu addItem:[NSMenuItem separatorItem]];
    [editMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];
    [editMenuItem setSubmenu:editMenu];

    // Service Menu
    NSMenuItem *serviceMenuItem = [[NSMenuItem alloc] init];
    [mainMenuBar addItem:serviceMenuItem];
    NSMenu *serviceMenu = [[NSMenu alloc] initWithTitle:@"سرویس (Service)"];
    [serviceMenu addItemWithTitle:@"راه‌اندازی مجدد سرویس (Restart Service)" action:@selector(restartServiceAction:) keyEquivalent:@"r"];
    [serviceMenu addItemWithTitle:@"اجرای ایجنت در نوار بالا (Launch Menu Bar Agent)" action:@selector(launchAgentAction:) keyEquivalent:@""];
    [serviceMenu addItem:[NSMenuItem separatorItem]];
    [serviceMenu addItemWithTitle:@"مشاهده لاگ‌ها (View Logs)" action:@selector(viewLogsAction:) keyEquivalent:@"l"];
    [serviceMenuItem setSubmenu:serviceMenu];
}

- (void)setupWindow {
    CGFloat paneWidth = 668.0;
    CGFloat paneHeight = 384.0;
    CGFloat bannerHeight = 44.0;
    CGFloat totalHeight = paneHeight + bannerHeight;

    NSRect frame = NSMakeRect(0, 0, paneWidth, totalHeight);
    NSWindowStyleMask style = NSWindowStyleMaskTitled |
                              NSWindowStyleMaskClosable |
                              NSWindowStyleMaskMiniaturizable;

    self.window = [[NSWindow alloc] initWithContentRect:frame
                                              styleMask:style
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    [self.window setTitle:@"Kerio Control VPN Client"];
    [self.window center];
    [self.window setDelegate:self];

    NSView *containerView = [[NSView alloc] initWithFrame:frame];
    [self.window setContentView:containerView];

    // Top Service Banner
    NSRect bannerRect = NSMakeRect(0, paneHeight, paneWidth, bannerHeight);
    NSBox *bannerBox = [[NSBox alloc] initWithFrame:bannerRect];
    [bannerBox setBoxType:NSBoxCustom];
    [bannerBox setBorderWidth:0.0];
    [bannerBox setFillColor:[NSColor colorWithCalibratedWhite:0.95 alpha:0.8]];
    [containerView addSubview:bannerBox];

    // Status Label
    self.serviceStatusLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(16, 12, 380, 22)];
    [self.serviceStatusLabel setEditable:NO];
    [self.serviceStatusLabel setSelectable:NO];
    [self.serviceStatusLabel setBezeled:NO];
    [self.serviceStatusLabel setDrawsBackground:NO];
    [self.serviceStatusLabel setFont:[NSFont boldSystemFontOfSize:12.5]];
    [self.serviceStatusLabel setStringValue:@"در حال بررسی سرویس کریو..."];
    [bannerBox addSubview:self.serviceStatusLabel];

    // Action Button
    self.serviceActionButton = [[NSButton alloc] initWithFrame:NSMakeRect(paneWidth - 250, 8, 236, 28)];
    [self.serviceActionButton setButtonType:NSButtonTypeMomentaryPushIn];
    [self.serviceActionButton setBezelStyle:NSBezelStyleRounded];
    [self.serviceActionButton setTitle:@"راه‌اندازی سرویس (Start Service)"];
    [self.serviceActionButton setTarget:self];
    [self.serviceActionButton setAction:@selector(serviceActionClicked:)];
    [bannerBox addSubview:self.serviceActionButton];

    // Thin separator line
    NSBox *sep = [[NSBox alloc] initWithFrame:NSMakeRect(0, paneHeight - 1, paneWidth, 1)];
    [sep setBoxType:NSBoxSeparator];
    [containerView addSubview:sep];

    // Load Kerio Preference Pane
    NSBundle *bundle = [NSBundle bundleWithPath:@"/Library/PreferencePanes/KVpnClient.prefPane"];
    if (!bundle) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"خطا در یافتن فایل کریو"];
        [alert setInformativeText:@"فایل /Library/PreferencePanes/KVpnClient.prefPane پیدا نشد. لطفاً مطمئن شوید کریو نصب است."];
        [alert runModal];
        return;
    }

    [bundle load];
    Class prefClass = [bundle principalClass];
    if (!prefClass) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"خطا در بارگذاری کلاس کریو"];
        [alert runModal];
        return;
    }

    self.prefPane = [[prefClass alloc] initWithBundle:bundle];
    [self.prefPane willSelect];
    [self.prefPane loadMainView];
    [self.prefPane didSelect];

    NSView *paneView = [self.prefPane mainView];
    [paneView setFrame:NSMakeRect(0, 0, paneWidth, paneHeight)];
    [containerView addSubview:paneView];

    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (BOOL)checkKerioServiceListening {
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) return NO;

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(43434);
    inet_pton(AF_INET, "127.0.0.1", &addr.sin_addr);

    struct timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = 300000; // 300ms
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, (const char*)&tv, sizeof(tv));
    setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, (const char*)&tv, sizeof(tv));

    int res = connect(sock, (struct sockaddr *)&addr, sizeof(addr));
    close(sock);
    return (res == 0);
}

- (void)updateServiceStatusUI {
    BOOL running = [self checkKerioServiceListening];
    self.isServiceRunning = running;

    if (running) {
        [self.serviceStatusLabel setTextColor:[NSColor colorWithCalibratedRed:0.1 green:0.6 blue:0.2 alpha:1.0]];
        [self.serviceStatusLabel setStringValue:@"🟢 سرویس کریو فعال و آماده اتصال است"];
        [self.serviceActionButton setTitle:@"راه‌اندازی مجدد (Restart)"];
    } else {
        [self.serviceStatusLabel setTextColor:[NSColor colorWithCalibratedRed:0.8 green:0.2 blue:0.1 alpha:1.0]];
        [self.serviceStatusLabel setStringValue:@"⚠️ سرویس پس‌زمینه کریو اجرا نیست"];
        [self.serviceActionButton setTitle:@"راه‌اندازی سرویس (Start Service)"];
    }
}

- (void)startPeriodicCheck {
    [self updateServiceStatusUI];
    self.statusTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                       target:self
                                                     selector:@selector(updateServiceStatusUI)
                                                     userInfo:nil
                                                      repeats:YES];
}

- (void)serviceActionClicked:(id)sender {
    if (self.isServiceRunning) {
        [self restartServiceAction:sender];
    } else {
        [self startServiceAction:sender];
    }
}

- (void)startServiceAction:(id)sender {
    [self.serviceStatusLabel setTextColor:[NSColor secondaryLabelColor]];
    [self.serviceStatusLabel setStringValue:@"در حال بارگذاری سرویس کریو..."];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *scriptText = @"do shell script \"launchctl load -w /Library/LaunchDaemons/com.kerio.kvpncsvc.plist\" with administrator privileges";
        NSDictionary *errorInfo = nil;
        NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:scriptText];
        [appleScript executeAndReturnError:&errorInfo];

        // Also ensure KVpnClientAgent is launched
        [[NSWorkspace sharedWorkspace] openApplicationAtURL:[NSURL fileURLWithPath:@"/Applications/KVpnClientAgent.app"]
                                              configuration:[NSWorkspaceOpenConfiguration configuration]
                                          completionHandler:nil];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self updateServiceStatusUI];
        });
    });
}

- (void)restartServiceAction:(id)sender {
    [self.serviceStatusLabel setTextColor:[NSColor secondaryLabelColor]];
    [self.serviceStatusLabel setStringValue:@"در حال راه‌اندازی مجدد..."];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *scriptText = @"do shell script \"launchctl unload /Library/LaunchDaemons/com.kerio.kvpncsvc.plist; sleep 1; launchctl load -w /Library/LaunchDaemons/com.kerio.kvpncsvc.plist\" with administrator privileges";
        NSDictionary *errorInfo = nil;
        NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:scriptText];
        [appleScript executeAndReturnError:&errorInfo];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self updateServiceStatusUI];
        });
    });
}

- (void)launchAgentAction:(id)sender {
    [[NSWorkspace sharedWorkspace] openApplicationAtURL:[NSURL fileURLWithPath:@"/Applications/KVpnClientAgent.app"]
                                          configuration:[NSWorkspaceOpenConfiguration configuration]
                                      completionHandler:^(NSRunningApplication *app, NSError *error) {
        if (error) {
            NSLog(@"Agent launch error: %@", error);
        }
    }];
}

- (void)viewLogsAction:(id)sender {
    NSString *logPath = @"/usr/local/kerio/vpnclient/logs";
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:logPath]];
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        KerioAppDelegate *delegate = [[KerioAppDelegate alloc] init];
        [app setDelegate:delegate];
        [app run];
    }
    return 0;
}
