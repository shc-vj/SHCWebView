SHCWebView
============

[SHCWebView](https://github.com/shc-vj/SHCWebView) is [WebView](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/WebKit/Classes/WebView_Class/index.html) compatible with [NSTextFinderClient](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSTextFinderClient_Protocol/index.html) protocol. It supports find functionality pretty much like in the *Apple Safari* browser. Best results can be accomplished when [NSTextFinder](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSTextFinder_Class/index.html) object is configured to use "*Incremental searching*" and "*Dim Content View*".

## Features

[SHCWebView](https://github.com/shc-vj/SHCWebView) can properly handle a Unicode composite characters when the `stripCombiningMarks` property is set to `YES`, this property has also an another effect - offers a special mode of searching. When set to `YES` parsing text nodes from the DOM tree use a `kCFStringTransformStripCombiningMarks` transform of `CFStringTransform` foundation method to ease searching of non-ASCII characters by ex."
- content text is "zażółć" (polish language), `stripCombiningMarks` set to `YES`, to match content search string could be "zazolc" if `stripCombiningMarks` set to `NO` you should enter exact string to match "zażółć".

## Usage

Use like normal [WebView](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/WebKit/Classes/WebView_Class/index.html) (in Interface Builder remember to change class to [SHCWebView](https://github.com/shc-vj/SHCWebView)).
Configure `textFinder` property to your [NSTextFinder](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSTextFinder_Class/index.html) object - it's necessary to communicate between [WebView](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/WebKit/Classes/WebView_Class/index.html) and [NSTextFinder](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSTextFinder_Class/index.html) (by ex. when the [WebView](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/WebKit/Classes/WebView_Class/index.html) change its size).

### Setup

To achieve proper working with [NSTextFinder](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSTextFinder_Class/index.html) interface we need embed [WebView](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/WebKit/Classes/WebView_Class/index.html) into [NSScrollView](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSScrollView_Class/index.html) (because it already implement [NSTextFinderBarContainer](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSTextFinderBarContainer_Protocol/index.html) protocol).
It's possible to work only with [WebView](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/WebKit/Classes/WebView_Class/index.html) internal scroll object (`webView.mainFrame.frameView.documentView.enclosingScrollView`) but it has some drawbacks - when [NSTextFinder](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSTextFinder_Class/index.html) bar is showing at the top of [WebView](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/WebKit/Classes/WebView_Class/index.html) links coordinates inside [WebView](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/WebKit/Classes/WebView_Class/index.html) are not updated with new control size (shrunk down by the [NSTextFinder](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSTextFinder_Class/index.html) bar height) and 'clickable' links appear to browser with offset equal to [NSTextFinder](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSTextFinder_Class/index.html) bar height. I don't know remedy to this behavior. When [NSTextFinder](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSTextFinder_Class/index.html) bar is displayed at the bottom of the control, it works as intended without any glitches.

So, common setup is to use [SHCWebView](https://github.com/shc-vj/SHCWebView) inside [NSScrollView](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSScrollView_Class/index.html). If you don't use *Auto Layout* remember to set [NSClipView](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSClipView_Class/index.html) (`NSScrollView.contentView`) property `autoresizeSubviews` to *NO*.

## Limitations

[NSTextFinder](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSTextFinder_Class/index.html) is well suited for a non-layered text, but with WebView where today we have many layers (DIVs), some of them can be hidden or floated above other content or dynamic content updated with *JavaScript*, it shows its weakness.

[NSTextFinder](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSTextFinder_Class/index.html) assumes that found text is visible all the time and in situation when we have a floating header (like menu by ex.) the 'holes' in dimming view will be displayed over our header (not exactly what we want) - but the same problem you can observe in the *Apple Safari* browser.

## Inner workings

NSTextFinder uses client object implementing NSTextFinderClient protocol to achieve its functionality:

1. Asks client for a string representation of the content. (`string` method)
2. Using a regular expression on that string NSTextFinder makes a text ranges of a matched phrase.
3. For every matched text range it asks the client for a bounding rect of that range - to display 'holes' in dimming view  (`rectsForCharacterRange:` method)
4. Asks client to draw the current text range (`drawCharactersInRange:forContentView:`)
5. When navigating next/prev the search result, it asks client to scroll client view to visible rect of the search result. (`scrollRangeToVisible:` method) 

##### Step 1 
To make string representation of the content we have to walk DOM tree and extract all *text nodes* content, remembering DOM nodes and offset positions of the text content in that nodes (as an *NSArray* of `SHCWebViewTextRange` objects). If the `stripCombiningMarks` property is set to `YES` also a transform on the text content is performed.

##### Step 2
It's the [NSTextFinder](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSTextFinder_Class/index.html) role, we don't need to do anything.

##### Step 3
To get bounding rects of text range we use _Java Script_ by `WebView.evaluateWebScript` method.
* Firstly create the **DOMRange** object and configure it using remembered earlier data (from `SHCWebViewTextRange` objects)
* Next for this **DOMRange** execute Java Script to get array of _bounding boxes_ of that range.

##### Step 4
As we can get bounding rects of the text range, to display that range we simply use WebView documentView `drawRect:`



