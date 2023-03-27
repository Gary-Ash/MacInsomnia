/*****************************************************************************************
 * @filename  AppDelegate.m
 *
 *  This file contains the implementation of the Cocoa app delegate
 *
 * @author    Gary Ash <Gary.Ash@icloud.com>
 * @copyright Copyright © 2022 By Gee Dbl A. All rights reserved
 ****************************************************************************************/
#import <IOKit/pwr_mgt/IOPMLib.h>

#import "AppDelegate.h"

@interface AppDelegate ()

@property(weak) IBOutlet NSMenu*  statusMenu;
@property(strong)   NSStatusItem* statusItem;
@property(strong)   NSImage*      sleepStatusImage;
@property(strong)   NSImage*      noSleepStatusImage;

@end

NSString* kAllowSleep    = @"Allow computer to sleep";
NSString* kLoadOnStartup = @"Load on startup";

@implementation AppDelegate
	{
	IOPMAssertionID assertionID;
	}
-(void)applicationDidFinishLaunching:(NSNotification*)aNotification
	{
	_sleepStatusImage   = [NSImage imageNamed: @"SleepStatus"];
	_noSleepStatusImage = [NSImage imageNamed: @"NoSleepStatus"];

	NSStatusBar* statusBar = [NSStatusBar systemStatusBar];

	_statusItem      = [statusBar statusItemWithLength: NSVariableStatusItemLength];
	_statusItem.menu = _statusMenu;

	[self setupDefaults];
	[self setStatusIcon];

	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	BOOL loadOnStartup = [defaults boolForKey: kLoadOnStartup];
	[self loadUnloadAppAtStartup: loadOnStartup];

	BOOL allowSleep    = [defaults boolForKey: kAllowSleep];
	if (!allowSleep)
		[self blockSleep];
	}

-(void)applicationWillTerminate:(NSNotification*)aNotification
	{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	BOOL allowSleep = [defaults boolForKey: kAllowSleep];
	if (!allowSleep)
		IOPMAssertionRelease(assertionID);
	}

-(BOOL)validateMenuItem:(NSMenuItem*)menuItem
	{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

	if (menuItem.action == @selector(performAllowSleep:))
		{
		BOOL allowSleep = [defaults boolForKey: kAllowSleep];
		menuItem.state = (allowSleep) ? NSOnState : NSOffState;
		}
	if (menuItem.action == @selector(performLoadOnStartup:))
		{
		BOOL loadOnStartup = [defaults boolForKey: kLoadOnStartup];
		menuItem.state = (loadOnStartup) ? NSOnState : NSOffState;
		}

	return YES;
	}

-(IBAction)performAllowSleep:(NSMenuItem*)sender
	{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	BOOL allowSleep = [defaults boolForKey: kAllowSleep];

	allowSleep = !allowSleep;
	[defaults setValue: [NSNumber numberWithBool: allowSleep] forKey: kAllowSleep];
	if (allowSleep)
		{
		IOPMAssertionRelease(assertionID);
		}
	else
		{
		[self blockSleep];
		}

	[self setStatusIcon];
	}

-(IBAction)performLoadOnStartup:(NSMenuItem*)sender
	{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	BOOL loadOnStartup = [defaults boolForKey: kLoadOnStartup];

	loadOnStartup = !loadOnStartup;
	[defaults setValue: [NSNumber numberWithBool: loadOnStartup] forKey: kLoadOnStartup];

	[self loadUnloadAppAtStartup: loadOnStartup];
	}

-(void)setupDefaults
	{
	NSDictionary* myDefaults =
		@{
		    kLoadOnStartup: @YES,
		    kAllowSleep: @YES,
	};
	[[NSUserDefaults standardUserDefaults] registerDefaults: myDefaults];
	}

-(void)setStatusIcon
	{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	BOOL allowSleep = [defaults boolForKey: kAllowSleep];
	_statusItem.button.image = (allowSleep) ? _sleepStatusImage : _noSleepStatusImage;
	}

-(void)loadUnloadAppAtStartup:(BOOL)loadOnStartup
	{
	NSArray*  dir = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);

	NSString* startupPlist = [dir[0] stringByAppendingString: @"/LaunchAgents/ "];
	startupPlist = [startupPlist stringByAppendingString: [NSBundle mainBundle].bundleIdentifier];
	startupPlist = [startupPlist stringByAppendingString: @".plist"];

	if (loadOnStartup)
		{
		if (![[NSFileManager defaultManager] fileExistsAtPath: startupPlist])
			{
			NSMutableDictionary* dic  = [NSMutableDictionary dictionary];
			NSMutableArray*      args = [NSMutableArray array];

			NSString* appPath = [NSBundle mainBundle].bundlePath;
			[args addObject: @"/usr/bin/open"];
			[args addObject: @"--fresh"];

			[args addObject: @"--background"];
			[args addObject: appPath];

			[dic setObject: [NSBundle mainBundle].bundleIdentifier forKey: @"Label"];
			[dic setObject: args forKey: @"ProgramArguments"];
			[dic setObject: @YES forKey: @"RunAtLoad"];
			[dic writeToFile: startupPlist atomically: YES];
			}
		}
	else
		{
		NSError* error;
		NSURL*   url = [NSURL URLWithString: startupPlist];
		[[NSFileManager defaultManager] removeItemAtURL: url error: &error];
		}
	}

-(void)blockSleep
	{
	static CFStringRef reason = CFSTR("Do not waant to sleep");
	IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep, kIOPMAssertionLevelOn, reason, &assertionID);
	}

@end
