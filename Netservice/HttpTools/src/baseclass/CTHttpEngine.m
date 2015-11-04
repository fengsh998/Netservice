//
//  CTHttpEngine.m
//  QianbaoIM
//
//  Created by fengsh on 18/4/15.
//  Copyright (c) 2015年 qianbao.com. All rights reserved.
//

#import "CTHttpEngine.h"
#import "CTHttpDefine.h"
#import "CTHttpRequestFactory.h"
#import "CTHttpUtils.h"

@implementation CTHttpEngineBase
- (void)sendRequest:(CTHttpRequest *)request
{
    //to do subclass.
}
- (void)cancelRequest:(CTHttpRequest *)request
{
    //to do subclass.
}
- (void)cancelAllRequest
{
    //to do subclass.
}
@end

/**
 *  用来产生具体的可使用的实体对象
 */
@implementation CTHttpRequestConstruction

+ (CTHttpRequest *)createAnValidRequest
{
    CTHttpRequestFactory *f = [[CTHttpRequestFactory alloc]initWithImplType:apiAFNewWorking];
    return [f createRequest];
}

+ (CTHttpUploadRequest *)createAnValidUploadRequest
{
    CTHttpRequestFactory *f = [[CTHttpRequestFactory alloc]initWithImplType:apiAFNewWorking];
    return [f createUploadRequest];
}

+ (CTHttpDownloadRequest *)createAnValidDownloadRequest
{
    CTHttpRequestFactory *f = [[CTHttpRequestFactory alloc]initWithImplType:apiAFNewWorking];
    return [f createDownloadRequest];
}

@end

@implementation CTHttpResponse

- (id)copyWithZone:(NSZone *)zone
{
    CTHttpResponse *response        = [[self class]allocWithZone:zone];
    response.contextRequestid       = _contextRequestid;
    response.statuscode             = _statuscode;
    response.allResponseHeaders     = _allResponseHeaders;
    response.responseObject         = _responseObject;
    return response;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ <%p> : {contextRequestid : %lu, statuscode : %ld \
            , allResponseHeaders : %@, responseObject : %p}",[self class],self,(unsigned long)_contextRequestid,
            (long)_statuscode,_allResponseHeaders,_responseObject];
}
@end


//***************************************虚类****************************************//
/**
 *              具体使用什么样的第三方依赖库，由具体的实现子类来处理。
 */
@interface CTHttpRequest()
{
    @private
        CTHttpRequestID                 _id;
        NSURL                           *_requestURL;
}
@end

@implementation CTHttpRequest

- (CTHttpRequestID)requestid
{
    return _id;
}

- (NSURL *)url
{
    return _requestURL;
}

- (id)init
{
    if (self = [super init]) {
        [self setDefaultValue];
    }
    return self;
}

- (instancetype)initWithURLString:(NSString *)url
{
    if (self = [super init]) {
        [self setDefaultValue];
        
        [self setRequestUrlString:url];
    }
    return self;
}

- (void)setDefaultValue
{
    _id = [[CTHttpUtils createUUID] hash];
    _timeout = 60;
    _useJsonFormat = NO;
}

- (void)setRequestUrlString:(NSString *)url
{
    _requestURL = [[NSURL alloc]initWithString:url];
}

- (BOOL)isSSL
{
    return [[_requestURL.scheme uppercaseString] hasPrefix:@"HTTPS"];
}

- (void)setFinish:(SuccessCompletion)finish withFailed:(FailedCompletion)failure
{
    _successCallBack = [finish copy];
    _failureCallBack = [failure copy];
}

- (void)go
{
    //to do subclass.
}

- (void)cancel
{
    //to do subclass.
}

- (void)supend
{
    //to do subclass.
}

- (void)resume
{
    //to do subclass.
}

- (long long int)sizeOfTranferedTotalBytes
{
    //to do subclass.
    return 0;
}

- (id)copyWithZone:(NSZone *)zone
{
    CTHttpRequest *request  = [[self class]allocWithZone:zone];
    request->_id            = _id;
    request->_requestURL    = [_requestURL copy];
    request.timeout         = _timeout;
    request.tag             = _tag;
    request.method          = _method;
    request.requestHeaders  = _requestHeaders;//因为是copy属性所以不需要再copy
    request.useCookies      = _useCookies;
    request.response        = _response;
    request.requestParams   = _requestParams;
    request.useJsonFormat   = _useJsonFormat;
    [request setFinish:self.successCallBack withFailed:self.failureCallBack];
    
    return request;
}
@end

@implementation CTHttpUploadRequest

- (void)setUploadProgress:(Progressing)progress
{
    //to do subclass.
}

- (void)setPostFormdataBlock:(PostFormData)formdata
{
    //to do subclass.
}
@end

@implementation CTHttpDownloadRequest

- (void)setDownloadProgress:(Progressing)progress
{
    //to do subclass.
}

@end


@implementation CTSecurityPolicy

- (id)init
{
    self = [super init];
    if (self) {
        self.sslPinningMode = CTSSLPinningModeNone;
        self.validatesCertificateChain = YES;
        self.allowInvalidCertificates = NO;
    }
    return self;
}

@end

