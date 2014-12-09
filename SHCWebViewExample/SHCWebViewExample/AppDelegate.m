//
//  AppDelegate.m
//  SHCWebViewExample
//
//  Created by pawelc on 01/12/14.
//  Copyright (c) 2014 Metasprint. All rights reserved.
//

#import "AppDelegate.h"
#import "SHCWindowController.h"

@interface AppDelegate ()

@property (strong) SHCWindowController *windowController;


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	// Insert code here to initialize your application

	self.windowController = [[SHCWindowController alloc] initWithWindowNibName:@"SHCWindowController"];
	[self.windowController showWindow:self];
	
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

@end
