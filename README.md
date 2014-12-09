SHCWebView
============

[SHCWebView](https://github.com/shc-vj/SHCWebView) is [WebView](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/WebKit/Classes/WebView_Class/index.html) compatible with [NSTextFinderClient](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSTextFinderClient_Protocol/index.html) protocol. It's supporting  find functionality pretty mach like in the Safari browser. Best results can be accomplished when [NSTextFinder](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSTextFinder_Class/index.html) object is configured to use "*Incremental searching*" and "*Dim Content View*".

## Usage

Use like normal [WebView](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/WebKit/Classes/WebView_Class/index.html) (in Interface Builder remember to change class to [SHCWebView](https://github.com/shc-vj/SHCWebView)).
Configure `textFinder` property to your [NSTextFinder](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSTextFinder_Class/index.html) object - it's necessary to communicate between [WebView](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/WebKit/Classes/WebView_Class/index.html) and [NSTextFinder](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSTextFinder_Class/index.html) (by ex. when the [WebView](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/WebKit/Classes/WebView_Class/index.html) change its size).

### Setup

To achieve proper working with [NSTextFinder](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSTextFinder_Class/index.html) interface we need embed [WebView](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/WebKit/Classes/WebView_Class/index.html) into [NSScrollView](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSScrollView_Class/index.html) (because it already implement [NSTextFinderBarContainer](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSTextFinderBarContainer_Protocol/index.html) protocol).
It's possible to work only with [WebView](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/WebKit/Classes/WebView_Class/index.html) internal scroll object (`webView.mainFrame.frameView.documentView.enclosingScrollView`) but it has some drawbacks - when [NSTextFinder](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSTextFinder_Class/index.html) bar is showing at the top of [WebView](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/WebKit/Classes/WebView_Class/index.html) links coordinates inside [WebView](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/WebKit/Classes/WebView_Class/index.html) are not updated with new control size (shrunk down by the [NSTextFinder](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSTextFinder_Class/index.html) bar height) and 'clickable' links appear to browser with offset equal to [NSTextFinder](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSTextFinder_Class/index.html) bar height. I don't know remedy to this behavior. When [NSTextFinder](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSTextFinder_Class/index.html) bar is displayed at the bottom of the control all work as intended without any glitches.

So, common setup is to use [SHCWebView](https://github.com/shc-vj/SHCWebView) inside [NSScrollView](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSScrollView_Class/index.html). If you don't use *Auto Layout* remember to set [NSClipView](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSClipView_Class/index.html) (`NSScrollView.contentView`) property `autoresizeSubviews` to *NO*.

## Limitations

## Inner workings

## Customize some internals

