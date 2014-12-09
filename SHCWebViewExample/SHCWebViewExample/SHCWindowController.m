//
//  SHCWindowController.m
//  SHCWebViewExample
//
//  Created by pawelc on 09/12/14.
//  Copyright (c) 2014 Metasprint. All rights reserved.
//

#import "SHCWindowController.h"
#import "SHCWebView.h"

@interface SHCWindowController () <NSTextFieldDelegate>

@property (weak) IBOutlet SHCWebView   *webView;
@property (weak) IBOutlet NSTextFinder *textFinder;
@property (weak) IBOutlet NSTextField  *urlTextField;

@end

@implementation SHCWindowController

- (void)windowDidLoad {
	
	[super windowDidLoad];
	
	//////////////////////////////////////////////////////////////////////////////////////
	// These properties are set in NIB file, but to be verbose what we need to do:
	
	// - set container for NSTextFinder panel (NSScrollView hosting our SHCWebView)
	self.textFinder.findBarContainer = self.webView.enclosingScrollView;
	// - set client to work with the NSTextFinder object
	self.textFinder.client  = self.webView;
	// - and vice versa: inform our SHCVebView about which of the NSTextFinder instance to work with
	self.webView.textFinder = self.textFinder;
	// - configure NSTextFinder
	self.textFinder.incrementalSearchingEnabled = YES;
	self.textFinder.incrementalSearchingShouldDimContentView = YES;
	
	// side note: you can try what will happen if you use WebView internal scroll as NSTextFinder.findBarContainer
	// hint: try to reach any link when displaying FindBar ;-)
	// uncomment line below
	//	self.textFinder.findBarContainer = self.webView.mainFrame.frameView.documentView.enclosingScrollView;
	
	
	self.urlTextField.delegate = self;
	
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:self.urlTextField.stringValue]];
	[self.webView.mainFrame loadRequest:urlRequest];

}

#pragma mark - Actions

- (IBAction)performFindAction:(id)sender
{
	if( [sender isKindOfClass:[NSMenuItem class]] ) {
		NSMenuItem *menuItem = (NSMenuItem*)sender;
		
		if( menuItem.tag == NSTextFinderActionShowFindInterface) {
			// causes NSTextFinder asks its client about a string
			[self.textFinder performAction:NSTextFinderActionSetSearchString];
		}
		
		[self.textFinder performAction:menuItem.tag];
	}	
}

#pragma mark - NSTextFieldDelegate

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
	if( commandSelector == @selector(insertNewline:) ) {
		// handle ENTER
		
		NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:self.urlTextField.stringValue]];
		[self.webView.mainFrame loadRequest:urlRequest];
		
		// discard previous data structures
		[self.webView invalidateTextRanges];
		
		// inform NSTextFinder the text is going to change
		[self.textFinder noteClientStringWillChange];
		
		return YES;
	}
	
	return NO;
	
}




@end
