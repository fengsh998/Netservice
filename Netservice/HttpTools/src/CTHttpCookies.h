//
//  CTHttpCookies.h
//  QianbaoIM
//
//  Created by fengsh on 16/4/15.
//  Copyright (c) 2015年 fengsh. All rights reserved.
//
/**
 *  http cookie处理
 */

@protocol CTHttpCookiesProtocol <NSObject>

/**
 *  将请求URL响应回来的cookies保存起来。
 *
 *  @param responsHeaders 响应头域
 *  @param url            该响应是来自哪个url请求的。
 */
- (void)storeHttpResponseCookies:(NSDictionary *)responsHeaders forRequestURL:(NSURL *)url;

/**
 *  根据请求的URL从已有的cookie库中查找是否有该URL对应的cookies头域,nil则表示没有储存过。否则返回当前最新储存的
 *  cookies信息。
 *
 *  @param url 请求URL
 *
 *  @return 字典类型的cookies信息
 */
- (NSDictionary *)findHttpRequestCookiesForRequestURL:(NSURL *)url;

/**
 *  获取请求URL的cookies字符串value值
 *
 *  @param url 请求的url
 *
 *  @return cookie : value(string),返回nil,说明该请求的url没有存储过cookies
 */
- (NSString *)cookievalueForRequestURL:(NSURL*)url;

/**
 *  清除请求url所地应的cookies
 *
 *  @param url
 */
- (void)cleanCookiesOfRequestURL:(NSURL *)url;

/**
 *  谨慎使用，会把所有已储存的cookie都清除
 */
- (void)cleanAllCookies;


@end

typedef NS_ENUM(NSInteger, CTHttpCookieAccpetPolicy) {
    cookiePolicyAlways                 ,  //对应 NSHTTPCookieAcceptPolicyAlways, (default)
    cookiePolicyNever                  ,  //NSHTTPCookieAcceptPolicyNever,
    cookiePolicyDomain                    //NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain
};

@interface CTHttpCookies : NSObject<CTHttpCookiesProtocol>
///cookies保存策略
@property (nonatomic, assign) CTHttpCookieAccpetPolicy cookiesPolicy;

+ (instancetype)shareCookies;
@end
