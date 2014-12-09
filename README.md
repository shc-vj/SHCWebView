SHCWebView
============

**SHCWebView** is **WebView** compatible with **NSTextFinderClient** protocol. It's supporting  find functionality pretty mach like in the Safari browser. Best results can be accomplished when **NSTextFinder** object is configured to use "*Incremental searching*" and "*Dim Content View*".

## Usage

Use like normal **WebView** (in Interface Builder remember to change class to **SHCWebView**).
Configure `textFinder` property to your **NSTextFinder** object - it's necessary to communicate between **WebView** and **NSTextFinder** (by ex. when the **WebView** change its size).

### Setup

To achieve proper working with **NSTextFinder** interface we need embed **WebView** into **NSScrollView** (because it already implement **NSTextFinderBarContainer** protocol).
It's possible to work only with **WebView** internal scroll object (`webView.mainFrame.frameView.documentView.enclosingScrollView`) but it has some drawbacks - when **NSTextFinderBar** is showing at the top of **WebView** links coordinates inside WebView are not updated with new control size (shrunk down by the **NSTextFinder** bar height) and 'clickable' links appear to browser with offset equal to **NSTextFinder** bar height. I don't know remedy to this behavior. When **NSTextFinder** bar is displayed at the bottom of the control all work as intended without any glitches.

So, common setup is to use **SHCWebView** inside **NSScrollView**. If you use **NSScrollView** with **NSClipView** (common setup) remember to set **NSClipView** property `autoresizeSubviews` to *NO*.

## Limitations

## Inner workings

## Customize some internals

