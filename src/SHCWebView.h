//
//  SHCWebView.h
//  ESTSTextBook
//
//  Created by pawelc on 20/06/14.
//  Copyright (c) 2014 Metasprint. All rights reserved.
//

#import <WebKit/WebKit.h>

#ifndef IBInspectable
	#define IBInspectable
#endif



/**
 SHCWebView is WebView subclass implementing <NSTextFinderClient> protocol.
 
 Additionally it supports highlighting of <NSRegularExpression> matches with given CSS style
 
 @warning All methods must be called from the main thread ! (DOM requirement)
 */
@interface SHCWebView : WebView <NSTextFinderClient>

/**
 NSTextFinder instance using this WebView
 */
@property (nonatomic, weak) IBOutlet NSTextFinder *textFinder;

/**
 When set to YES content is parsed using kCFStringTransformStripCombiningMarks of CFStringTransform
 (useful for searches)
 
 Deafult is NO
 */
@property (nonatomic, assign) IBInspectable BOOL stripCombiningMarks;

/**
 Call this method if DOM document has changed and we need to refresh our DOM cache
 */
- (void)invalidateTextRanges;

//////////////////////////////////////////////////////////////////////////////////////
/// @name EXPERIMENTAL

/**
 CSS style used for highlight
 
 @discussion Highlighting process insert SPAN element for matched range of text. This property is the SPAN CSS style. SPAN element has a class `webViewHighlight`
 */
@property (nonatomic, copy) NSString *highlightCSS;


/**
 Highlight text content matching given regular expression.
 Highlight style is get from <highlightCSS> property
 
 @param regEx Regular expression to use
 
 @return Return number of matches or -1 when error occured
 
 @discussion This method highlight matched text using additional SPAN element with class="webViewHighlight"
 Every added SPAN has name attribute set with format: "webViewMatch_<match_number>" by example "webViewMatch_0" for first match
 */
- (NSInteger)highlightTextMatchingRegularExpression:(NSRegularExpression*)regEx;


/**
 Removes all higlights added by <highlightTextMatchingRegularExpression:>
 */
- (void)removeHighlights;



@end
