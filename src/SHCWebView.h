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



@end
