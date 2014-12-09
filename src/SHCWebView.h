//
//  SHCWebView.h
//  ESTSTextBook
//
//  Created by pawelc on 20/06/14.
//  Copyright (c) 2014 Medycyna Praktyczna. All rights reserved.
//

#import <WebKit/WebKit.h>


/**
 SHCWebView is WebView subclass implementing <NSTextFinderClient> protocol.
 
 Additionally it support highlighting of <NSRegularExpression> matches with given CSS style
 
 @warning All methods must be called from the main thread ! (DOM requirement)
 */
@interface SHCWebView : WebView <NSTextFinderClient>

/**
 NSTextFinder instance using this WebView
 */
@property (nonatomic, strong) NSTextFinder *textFinder;


/**
 CSS style used for highlight
 
 @discussion Highlighting process insert SPAN element for matched range of text. This property is the SPAN CSS style. SPAN element has a class `webViewHighlight`
 */
@property (nonatomic, copy) NSString *highlightCSS;


/**
 When set to YES content is parsed using kCFStringTransformStripCombiningMarks of CFStringTransform
 (useful for searches)
 
 Deafult is NO
 */
@property (nonatomic, assign) BOOL stripCombiningMarks;


/// @name Non TextFinderClient methods

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
 Highlight given DOMRange.
 Highlight style is get from <highlightCSS> property
 
 @param domRange DOMRange to highlight
 @param index	Index used as a postfix to the name of a SPAN element with class="webViewHighlight" (name="webViewMatch_<index>")
 */
- (void)highlightDOMRange:(DOMRange*)domRange withIndex:(NSInteger)index;

/**
 Removes all higlights added by <highlightTextMatchingRegularExpression:>
 */
- (void)removeHighlights;

/**
 Removes highlights only in given node and its children
 
 @param node DOMNode to start with
 */
- (void)removeHighlightsInNode:(DOMNode*)node;

/**
 Call this method if DOM document has changed and we need to refresh our DOM cache
 */
- (void)invalidateTextRanges;

@end
