//
//  CTHttpCookies.m
//  QianbaoIM
//
//  Created by fengsh on 16/4/15.
//  Copyright (c) 2015年 fengsh. All rights reserved.
//

#import "CTHttpCookies.h"

@implementation CTHttpCookies

+ (instancetype)shareCookies
{
    static CTHttpCookies *cookieInstance = nil;
    static dispatch_once_t cookietoken = 0;
    
    dispatch_once(&cookietoken, ^{
        cookieInstance = [[CTHttpCookies alloc]init];
    });
    
    return cookieInstance;
}

- (void)setCookiesPolicy:(CTHttpCookieAccpetPolicy)cookiesPolicy
{
    _cookiesPolicy = cookiesPolicy;
    [[NSHTTPCookieStorage sharedHTTPCookieStorage]setCookieAcceptPolicy:(NSHTTPCookieAcceptPolicy)cookiesPolicy];
}

- (void)storeHttpResponseCookies:(NSDictionary *)responsHeaders forRequestURL:(NSURL *)url
{
    //有可能有两个cookie头的
    NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:responsHeaders forURL:url];
    
    for (NSHTTPCookie *item in cookies) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage]setCookie:item];
    }
}

- (NSDictionary *)findHttpRequestCookiesForRequestURL:(NSURL *)url
{
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage]cookiesForURL:url];
    if (cookies) {
        return [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
    }
    
    return nil;
}

- (NSString *)cookievalueForRequestURL:(NSURL*)url
{
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage]cookiesForURL:url];
    NSString *valuestring = nil;
    for (NSHTTPCookie *item in cookies)
    {
        if (!valuestring)
        {
            valuestring = [NSString stringWithFormat:@"%@=%@",item.name,item.value];
        }
        else
        {
            valuestring = [NSString stringWithFormat: @"%@; %@=%@",valuestring,item.name,item.value];
        }
    }
    return valuestring;
}

- (void)cleanCookiesOfRequestURL:(NSURL *)url
{
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage]cookiesForURL:url];
    for (NSHTTPCookie *item in cookies)
    {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage]deleteCookie:item];
    }
}

- (void)cleanAllCookies
{
    [[NSHTTPCookieStorage sharedHTTPCookieStorage]removeCookiesSinceDate:[NSDate date]];
}

@end
