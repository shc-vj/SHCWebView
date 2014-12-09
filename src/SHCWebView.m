//
//  SHCWebView.m
//  ESTSTextBook
//
//  Created by pawelc on 20/06/14.
//  Copyright (c) 2014 Metasprint. All rights reserved.
//

#import "SHCWebView.h"

/**
 Class for storing DOMDocument DOMText nodes
 */
@interface SHCWebViewTextRange : NSObject

@property (nonatomic, assign) NSRange  range;
@property (nonatomic, assign) BOOL     endsWithSearchBoundary;
@property (nonatomic, strong) DOMText  *domNode;
@property (nonatomic, assign) NSUInteger offsetInDomNode;

@end

@implementation SHCWebViewTextRange

- (NSString*)description
{
	return [NSString stringWithFormat:@"MPWebViewTextRange (range=%@)", NSStringFromRange(self.range)];
}

@end

// utility function
static BOOL NodeIsSpanElementWithTextContent(DOMNode* node) {
	
	if( node.nodeType == DOM_ELEMENT_NODE ) {
		
		DOMElement *element = (DOMElement*)node;
		
		if( [element.nodeName isEqualToString:@"FONT"] ) {
			return NodeIsSpanElementWithTextContent(element.firstChild);
		}
		
		if( [element.nodeName isEqualToString:@"SPAN"] ) {
			DOMNode *child = element.firstChild;
			if( child ) {
				if( child.nodeType == DOM_TEXT_NODE ) {
					return YES;
				} else {
					return NodeIsSpanElementWithTextContent(child);
				}
			} else {
				return NodeIsSpanElementWithTextContent(element.nextSibling);
			}
		}
	}

	return NO;
}


@interface SHCWebView () {
	id _scrollObserverObject;
	id _frameObserverObject;
}

/**
 NSArray of MPWebViewTextRange objects representing DOMText nodes
 */
@property (nonatomic, strong ) NSArray *webViewTextRanges;

/**
 Cached rects for text ranges.
 
 @discussion Rects are calculated in WebView document coordinates.
 */
@property (nonatomic, strong) NSMutableDictionary *rectsCacheForTextRanges;


/**
 Setup observer object for scrolling update (due to some bug with NSTextFinder client view scrolling response)
 */
- (void)setupScrollObserver;
- (void)setupFrameObserver;

- (NSString*)stringFromWebViewTextRanges:(NSArray*)textRanges;
- (void)configureDOMRange:(DOMRange*)domRange forTextRange:(NSRange)range;

// helpers
- (void)webViewTextRangesHelper:(DOMNode*)beginNode posPtr:(NSUInteger*)posPtr outWebViewTextRanges:(NSMutableArray*)textRanges;


// experimental section

/**
 Highlight given DOMRange.
 Highlight style is get from <highlightCSS> property
 
 @param domRange DOMRange to highlight
 @param index	Index used as a postfix to the name of a SPAN element with class="webViewHighlight" (name="webViewMatch_<index>")
 */
- (void)highlightDOMRange:(DOMRange*)domRange withIndex:(NSInteger)index;

/**
 Removes highlights only in given node and its children
 
 @param node DOMNode to start with
 */
- (void)removeHighlightsInNode:(DOMNode*)node;


@end


@implementation SHCWebView


- (instancetype)initWithFrame:(NSRect)frame frameName:(NSString *)frameName groupName:(NSString *)groupName
{
	self = [super initWithFrame:frame frameName:frameName groupName:groupName];
	if( self ) {
		[self setupFrameObserver];
		[self setupScrollObserver];
	}
	
	return self;
}

- (void)awakeFromNib
{
	[self setupFrameObserver];
	[self setupScrollObserver];
}

- (void)setupScrollObserver
{	
	NSScrollView *webScrollView =  self.mainFrame.frameView.documentView.enclosingScrollView;
	NSClipView *clipView = webScrollView.contentView;
	// check for sure that NSSCrollView has NSClipView
	if( [clipView isKindOfClass:[NSClipView class]] ) {
		
		[clipView setPostsBoundsChangedNotifications:YES];
		
		__typeof(self) __weak weakSelf = self;
		
		// add observer for bounds change (for scrolling)
		// observer will be informing text finder to update
		_scrollObserverObject = [[NSNotificationCenter defaultCenter] addObserverForName:NSViewBoundsDidChangeNotification object:clipView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
			
			__typeof(self) strongSelf = weakSelf;
			
			if( strongSelf ) {
				[strongSelf.textFinder setFindIndicatorNeedsUpdate:YES];
			}
		}];
	}
}

- (void)setupFrameObserver
{
	[self setPostsFrameChangedNotifications:YES];
	
	__typeof(self) __weak weakSelf = self;
	
	// add observer for bounds change (for scrolling)
	// observer will be informing text finder to update
	_frameObserverObject = [[NSNotificationCenter defaultCenter] addObserverForName:NSViewFrameDidChangeNotification object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		
		__typeof(self) strongSelf = weakSelf;
		
		if( strongSelf ) {
			strongSelf.rectsCacheForTextRanges = nil;
			[strongSelf.textFinder setFindIndicatorNeedsUpdate:YES];
		}
	}];
	
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:_frameObserverObject];
	[[NSNotificationCenter defaultCenter] removeObserver:_scrollObserverObject];
}

#pragma mark - WebView overrides

- (IBAction)makeTextLarger:(id)sender
{
	[super makeTextLarger:sender];
	
	self.rectsCacheForTextRanges = nil;
	[self.textFinder setFindIndicatorNeedsUpdate:YES];
}

- (IBAction)makeTextSmaller:(id)sender
{
	[super makeTextSmaller:sender];
	
	self.rectsCacheForTextRanges = nil;
	[self.textFinder setFindIndicatorNeedsUpdate:YES];
}

- (IBAction)makeTextStandardSize:(id)sender
{
	[super makeTextStandardSize:sender];
	
	self.rectsCacheForTextRanges = nil;
	[self.textFinder setFindIndicatorNeedsUpdate:YES];
}


#pragma mark - Properties (Experimental)

- (NSString*)highlightCSS
{
	if( nil == _highlightCSS ) {
		// default value
		return @"background-color: yellow; border: 1px; border-color: black; border-style: dashed;";
	}
	
	return _highlightCSS;
}

#pragma mark - Properties (Private)

- (NSArray*)webViewTextRanges
{
	if( nil == _webViewTextRanges ) {
		
		DOMDocument *document = self.mainFrame.DOMDocument;
		DOMNode *bodyNode = document.body;
		
		NSMutableArray *textRanges = [NSMutableArray array];
		NSUInteger posPtr = 0;
		
		[self webViewTextRangesHelper:bodyNode posPtr:&posPtr outWebViewTextRanges:textRanges];
		
		_webViewTextRanges = [textRanges copy];
	}
	
	return _webViewTextRanges;
}

- (NSMutableDictionary*)rectsCacheForTextRanges
{
	if( nil == _rectsCacheForTextRanges ) {
		_rectsCacheForTextRanges = [NSMutableDictionary dictionary];
	}
	
	return _rectsCacheForTextRanges;
}

#pragma mark - Instance methods

- (void)invalidateTextRanges
{
	self.rectsCacheForTextRanges = nil;
	self.webViewTextRanges       = nil;
	
	[self.textFinder setFindIndicatorNeedsUpdate:YES];
}

#pragma mark - Instance methods (Private Experimental)

- (void)highlightNode:(DOMNode*)node withIndex:(NSInteger)index
{
	DOMDocument *document = self.mainFrame.DOMDocument;
	
	while( node ) {
		
		__unused NSString *content = node.nodeValue;
		
		DOMNode *parentNode = node.parentNode;
		if( parentNode.nodeType == DOM_ELEMENT_NODE ) {
			DOMElement *element = (DOMElement*)parentNode;
			
			if( [[element getAttribute:@"class"] isEqualToString:@"webViewHighlight"] ) {
				node = node.nextSibling;
				continue;
			}
		}
		
		if( node.nodeType == DOM_TEXT_NODE && node.nodeValue.length > 0 ) {
			
			
			DOMElement *span = [document createElement:@"span"];
			[span setAttribute:@"class" value:@"webViewHighlight"];
			[span setAttribute:@"name" value:[NSString stringWithFormat:@"webViewMatch_%ld", (long)index]];
			span.style.cssText = self.highlightCSS;
			
			
			[node.parentNode replaceChild:span oldChild:node];
			
			[span appendChild:node];
			
		}
		
		if( node.firstChild ) {
			[self highlightNode:node.firstChild withIndex:index];
		}
		
		node = node.nextSibling;
	}
}

- (void)highlightDOMRange:(DOMRange*)domRange withIndex:(NSInteger)index
{
	DOMDocumentFragment *element = [domRange extractContents];
	[self removeHighlightsInNode:element];
	[self highlightNode:element withIndex:index];
	[domRange insertNode:element];
}

- (void)removeHighlightsInNode:(DOMNode*)node
{
	DOMDocument *document = self.mainFrame.DOMDocument;
	
	while( node ) {
		
		int type = node.nodeType;
		if( type == DOM_ELEMENT_NODE ) {
			
			DOMElement *element = (DOMElement*)node;
			
			if( [[element getAttribute:@"class"] isEqualToString:@"webViewHighlight"] ) {
				// retrieve old fragment node inside SPAN
				// (use DOMRange)
				DOMRange *spanRange = [document createRange];
				[spanRange selectNodeContents:element];
				
				// move fragment node in hierachy
				DOMDocumentFragment *oldFragment = [spanRange extractContents];
				DOMNode *nextNode                = element.nextSibling;
				[element.parentNode insertBefore:oldFragment refChild:nextNode];
				
				// remove SPAN
				[element.parentNode removeChild:element];
				
				node = nextNode.previousSibling;
				
			}
		}
		
		DOMNode *firstChild = node.firstChild;
		if( firstChild ) {
			[self removeHighlightsInNode:firstChild];
		}
		
		node = node.nextSibling;
	}
	
}


#pragma mark - Instance methods (Experimental)

- (NSInteger)highlightTextMatchingRegularExpression:(NSRegularExpression*)regEx
{
	NSString *stringValue = [self string];
	
	NSArray *matches = [regEx matchesInString:stringValue options:0 range:NSMakeRange(0, stringValue.length)];
	
	if( matches.count < 1 ) {
		return -1;
	}
	
	[self.textFinder noteClientStringWillChange];
	
	DOMDocument *document = self.mainFrame.DOMDocument;
	
	// configure ranges
	NSMutableArray *domRanges = [NSMutableArray array];

	for( NSTextCheckingResult *result in matches ) {

		DOMRange *domRange = [document createRange];
		[self configureDOMRange:domRange forTextRange:result.range];

		[domRanges addObject:domRange];
	}
			
	// modify DOM ranges
	unsigned int counter = 0;
	for( DOMRange *domRange in domRanges ) {
		[self highlightDOMRange:domRange withIndex:counter++];
	}
	
	// we have modified DOM tree
	// invalidate our textRanges
	[self invalidateTextRanges];
	
	return counter;
}


- (void)removeHighlights
{
    DOMDocument *document = self.mainFrame.DOMDocument;
    DOMNode *bodyNode     = document.body;
		
	[self.textFinder noteClientStringWillChange];

	[self removeHighlightsInNode:bodyNode];
	
	// we have modified DOM tree
	// invalidate our textRanges
	[self invalidateTextRanges];

}




#pragma mark - NSTextFinder utils

- (void)webViewTextRangesHelper:(DOMNode*)beginNode posPtr:(NSUInteger*)posPtr outWebViewTextRanges:(NSMutableArray*)textRanges
{
	DOMNode *node = beginNode;
	
	while( node ) {
		
		int type = node.nodeType;
		if( type == DOM_TEXT_NODE ) {
			
			DOMText *textNode = (DOMText*)node;
			
			SHCWebViewTextRange *webViewTextRange = nil;

			if( !self.stripCombiningMarks ) {
                webViewTextRange = [[SHCWebViewTextRange alloc] init];
                webViewTextRange.range = NSMakeRange( *posPtr, textNode.length);
                webViewTextRange.domNode = textNode;
                webViewTextRange.offsetInDomNode = 0;
				
				// increment position
				*posPtr += textNode.length;
				
				[textRanges addObject:webViewTextRange];

			} else {
				// find composed characters
				NSString *text = textNode.data;
				NSInteger splitPos = 0;
				for( NSInteger i=0; i<textNode.length; i++ ) {
					
					NSRange range = [text rangeOfComposedCharacterSequenceAtIndex:i];
					if( range.length > 1 ) {
						//composed character found
						
						// first append previous chunk of text before composed character
						if( splitPos < range.location ) {
							webViewTextRange = [[SHCWebViewTextRange alloc] init];
							webViewTextRange.range = NSMakeRange( *posPtr, range.location - splitPos);
							webViewTextRange.domNode = textNode;
							webViewTextRange.offsetInDomNode = splitPos;
							webViewTextRange.endsWithSearchBoundary = NO;
							
							// increment position
							*posPtr += webViewTextRange.range.length;

							[textRanges addObject:webViewTextRange];
						}
						
						// add composed character range
						// in final text it will be one character in string
						webViewTextRange = [[SHCWebViewTextRange alloc] init];
						webViewTextRange.range = NSMakeRange( *posPtr, 1);
						webViewTextRange.domNode = textNode;
						webViewTextRange.offsetInDomNode = range.location;
						webViewTextRange.endsWithSearchBoundary = NO;
						
						// increment position
						*posPtr += webViewTextRange.range.length;

						[textRanges addObject:webViewTextRange];
						
						i += range.length-1;
						splitPos = NSMaxRange(range);
					}
				}
				
				if( splitPos < textNode.length ) {
					// append rest of string
					webViewTextRange = [[SHCWebViewTextRange alloc] init];
					webViewTextRange.range = NSMakeRange( *posPtr, textNode.length-splitPos);
					webViewTextRange.domNode = textNode;
					webViewTextRange.offsetInDomNode = splitPos;
					
					// increment position
					*posPtr += webViewTextRange.range.length;
					
					[textRanges addObject:webViewTextRange];
				}
					
			}
				 
			BOOL searchBoundaryFound = NO;
			
			if( webViewTextRange ) {
				
				// check child element
				DOMNode *child = node.firstChild;
				if( child ) {
					if( child.nodeType != DOM_TEXT_NODE ) {
						// check for span
						if( !NodeIsSpanElementWithTextContent(child) ) {
							searchBoundaryFound = YES;
						}
					}
				} else {
					// check nextElement
					DOMNode *next = node.nextSibling;
					if( next ) {
						if( next.nodeType != DOM_TEXT_NODE ) {
							// check for span
							if( !NodeIsSpanElementWithTextContent(next) ) {
								searchBoundaryFound = YES;
							}
						}
					} else {
						// check parent next element
						DOMNode *parentNext = node.parentNode.nextSibling;
						if( nil == parentNext || parentNext.nodeType != DOM_TEXT_NODE ) {
							// check for span
							if( !NodeIsSpanElementWithTextContent(parentNext) ) {
								searchBoundaryFound = YES;
							}
						}
					}
				}
			}
			
			if( searchBoundaryFound ) {
				webViewTextRange.endsWithSearchBoundary = YES;
				
				(*posPtr)++;	// room for boundary character
				
				// extend range for boundary character
				NSRange extendedRange = webViewTextRange.range;
				extendedRange.length++;
				webViewTextRange.range = extendedRange;
			}
			
		}
		
		// check child nodes
		DOMNode *firstChild = node.firstChild;
		if( firstChild ) {
			[self webViewTextRangesHelper:firstChild posPtr:posPtr outWebViewTextRanges:textRanges];
		}
		
		// child nodes checked, time to siblings
		node = node.nextSibling;
	}
}


- (NSString*)stringFromWebViewTextRanges:(NSArray*)textRanges
{
	NSMutableString *string = [NSMutableString string];
		
	for( SHCWebViewTextRange *webViewTextRange in textRanges ) {
		
		NSRange substringRange = NSMakeRange(webViewTextRange.offsetInDomNode, webViewTextRange.endsWithSearchBoundary ? webViewTextRange.range.length-1 : webViewTextRange.range.length);
		NSString *textContent = [webViewTextRange.domNode.data substringWithRange:substringRange];
		NSMutableString *mutableContent = [NSMutableString stringWithString:textContent];
	
		if( self.stripCombiningMarks ) {
			// remove diacritics from text content
			CFStringTransform((__bridge CFMutableStringRef)mutableContent, NULL, kCFStringTransformStripCombiningMarks, NO);
		}
		
		// TODO: converting some specific charactes into more common form
		
		// replace &nbsp into normal 'space'
		NSString *nbsp = @"\u00A0";
		[mutableContent replaceOccurrencesOfString:nbsp	withString:@" " options:0 range:NSMakeRange(0, mutableContent.length)];
		
		[string appendString:mutableContent];
		
		if( webViewTextRange.endsWithSearchBoundary ) {
			[string appendString:@"\n"];
		}
	}
	
	return [string copy];
}

- (void)configureDOMRange:(DOMRange*)domRange forTextRange:(NSRange)range
{
	SHCWebViewTextRange *beginRange = nil;
	SHCWebViewTextRange *endRange = nil;
	
	NSArray *textRanges = [self webViewTextRanges];
	NSNumber *searchingObject = @(range.location);
	
	// binary search for beginning of range
	// a bit non standard use for this method, normally it supports the same objects type
	NSUInteger foundBeginTextRangeIndex = [textRanges indexOfObject:searchingObject inSortedRange:NSMakeRange(0, textRanges.count) options:NSBinarySearchingFirstEqual usingComparator:^NSComparisonResult(id obj1, id obj2) {
		
		NSNumber *searchingObj = nil;
		SHCWebViewTextRange *webViewTextRange = nil;
		
		// indexOfObject:inSortedRange:options:usingComparator do not stick with comparator arguments sequence, so wee need to determine which argument is 'searchingObject'
		if( obj1 == searchingObject ) {
			searchingObj = (NSNumber*)obj1;
			webViewTextRange = (SHCWebViewTextRange*)obj2;
		} else {
			searchingObj = (NSNumber*)obj2;
			webViewTextRange = (SHCWebViewTextRange*)obj1;
		}
		
		NSUInteger searchingValue = searchingObj.unsignedIntegerValue;
		
		if( NSLocationInRange(searchingValue, webViewTextRange.range) ) {
			return NSOrderedSame;
		} else
		if( searchingValue < webViewTextRange.range.location ) {
			if( searchingObj == obj1 ) {
				return NSOrderedAscending;
			} else {
				return NSOrderedDescending;
			}
		} else {
			if( searchingObj == obj1 ) {
				return NSOrderedDescending;
			} else {
				return NSOrderedAscending;
			}
		}
	}];
	
	if( foundBeginTextRangeIndex == NSNotFound ) {
		NSLog( @"Not found range %@", NSStringFromRange(range));
		return;
	}
	
	beginRange = [textRanges objectAtIndex:foundBeginTextRangeIndex];
	
	// linear search for ending
	for( NSUInteger i = foundBeginTextRangeIndex; i<textRanges.count; i++) {
		
		SHCWebViewTextRange *webViewTextRange = [textRanges objectAtIndex:i];
		
		// chceck for ending
		if( NSLocationInRange( NSMaxRange(range)-1, webViewTextRange.range ) ) {
			endRange = webViewTextRange;
			break;
		}
	}
	
	if( beginRange && endRange ) {
		
		int offset = (int)MIN(range.location - beginRange.range.location + beginRange.offsetInDomNode, beginRange.domNode.data.length-1);
		[domRange setStart:beginRange.domNode offset:offset];
		
		// end offset should be placed after last char
		offset = (int)MIN(NSMaxRange(range) - endRange.range.location + endRange.offsetInDomNode, endRange.domNode.data.length);
		
		// check end for composed character
		NSRange composedRange = [endRange.domNode.data rangeOfComposedCharacterSequenceAtIndex:offset-1];
		offset += composedRange.length-1;
		
		[domRange setEnd:endRange.domNode offset:offset];
				
	}
}


#pragma mark - NSTextFinderClient

- (NSString *)string {
	
	// invalidate previous DOM text data
	[self invalidateTextRanges];
	
	NSArray *textRanges = [self webViewTextRanges];
	NSString *string = [self stringFromWebViewTextRanges:textRanges];
	
	return string;
}

- (NSRange)firstSelectedRange
{
	return NSMakeRange(0, 0);
}


- (void)scrollRangeToVisible:(NSRange)range
{
	NSArray *rects = [self rectsForCharacterRange:range];
	NSRect firstRect = [[rects firstObject] rectValue];
	
	NSScrollView *webScrollView =  self.mainFrame.frameView.documentView.enclosingScrollView;
	NSClipView *clipView = webScrollView.contentView;
	
	// check for sure that NSSCrollView has NSClipView
	if( [clipView isKindOfClass:[NSClipView class]] ) {
		firstRect = [clipView convertRect:firstRect fromView:clipView.documentView];
		[clipView scrollRectToVisible:firstRect];
	}
}

- (NSView *)contentViewAtIndex:(NSUInteger)index effectiveCharacterRange:(NSRangePointer)outRange
{
	if( outRange ) {
		// set infinite range
		*outRange = NSMakeRange(0, NSUIntegerMax);
	}
	
	return self.mainFrame.frameView.documentView;
}

- (NSArray*)visibleCharacterRanges
{
	
	NSArray *incrementalMatches = self.textFinder.incrementalMatchRanges;

	// present visible ranges only for search phrase length > 1
	// (performance reasons)
	NSRange range = [[incrementalMatches firstObject] rangeValue];
	if( range.length < 2 ) {
		return nil;
	}

	SHCWebViewTextRange *beginRange = [self.webViewTextRanges firstObject];
	SHCWebViewTextRange *endRange = [self.webViewTextRanges lastObject];
	
	NSRange allRange = NSMakeRange(beginRange.range.location, NSMaxRange(endRange.range));
	return @[[NSValue valueWithRange:allRange]];
	
}

- (void)drawCharactersInRange:(NSRange)range forContentView:(NSView *)view
{
	NSArray *rects = [self rectsForCharacterRange:range];
	
	for( NSValue *rectValue in rects ) {
		NSRect rect = [rectValue rectValue];
		
		if( view.isDrawingFindIndicator ) {			
		}
		
		[view drawRect:rect];
	}
}

- (NSArray *)rectsForCharacterRange:(NSRange)range
{

	// check cache
	NSValue *rangeValue = [NSValue valueWithRange:range];
	NSArray *cachedRects = [self.rectsCacheForTextRanges objectForKey:rangeValue];
	if( cachedRects ) {
		return cachedRects;
	}
	
	// code path for first time referencing given range
	// it uses Javascript to compute ranges rects

	NSScrollView *webScrollView =  self.mainFrame.frameView.documentView.enclosingScrollView;
	NSClipView *clipView = webScrollView.contentView;
	
	// check for sure that NSSCrollView has NSClipView
	if( ![clipView isKindOfClass:[NSClipView class]] ) {
		return nil;
	}
	
	NSRect bounds = clipView.documentVisibleRect;
	
	WebScriptObject *scriptObject = [self windowScriptObject];
	// make new range object
	DOMRange *domRange = [scriptObject evaluateWebScript:@"mprange = document.createRange()"];
			
	// configure range with nodes
	[self configureDOMRange:domRange forTextRange:range];
		
	NSMutableArray *rects = [NSMutableArray array];
	
	// get range bounding rects
	WebScriptObject *rangeRects = [scriptObject evaluateWebScript:@"mprects = mprange.getClientRects()"];
	NSInteger rectsCount = [[scriptObject evaluateWebScript:@"mprects.length"] integerValue];
	
	for( NSInteger i=0; i<rectsCount; i++ ) {
		
		// get one rect
		[rangeRects evaluateWebScript:[NSString stringWithFormat:@"rect = mprects[%ld]", (long)i]];
		
		NSNumber *left = [scriptObject evaluateWebScript:@"rect.left"];
		NSNumber *top = [scriptObject evaluateWebScript:@"rect.top"];
		NSNumber *width = [scriptObject evaluateWebScript:@"rect.width"];
		NSNumber *height = [scriptObject evaluateWebScript:@"rect.height"];
	
		NSRect calcRect = NSMakeRect(left.floatValue, top.floatValue, width.floatValue, height.floatValue);
		
		// convert screen coordinates to WebView document
		calcRect = CGRectOffset(calcRect, bounds.origin.x, bounds.origin.y);
		
		NSValue *rectValue = [NSValue valueWithRect:calcRect];
		
		[rects addObject:rectValue];
	}
	
	// set cache
	[self.rectsCacheForTextRanges setObject:rects forKey:rangeValue];
	
	return rects;
}


@end
