//
//  CTHttpManager.m
//  QianbaoIM
//
//  Created by fengsh on 24/6/15.
//  Copyright (c) 2015年 qianbao.com. All rights reserved.
//

#import "CTHttpManager.h"
#import "CTHttpRequestFactory.h"

#ifdef DEBUG
#   define HttpLog(...) NSLog(__VA_ARGS__);
#else
#   define HttpLog(...)
#endif

@interface CTHttpManager ()
{
    CTHttpRequestFactory                    *_factory;
    NSMutableDictionary                     *_requestlist;
}
@end

@implementation CTHttpManager

+ (instancetype)shareHttpManager
{
    static CTHttpManager *managerInstance = nil;
    static dispatch_once_t mgronce = 0;
    
    dispatch_once(&mgronce, ^{
        managerInstance = [[CTHttpManager alloc]init];
    });
    
    return managerInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _factory = [[CTHttpRequestFactory alloc]initWithImplType:apiAFNewWorking];
        _requestlist =  [[NSMutableDictionary alloc]init];
    }
    return self;
}

- (void)dealloc
{
    [self cancelAllRequest];
}

- (id<ICTHttpRequestConstruction>)requestConstruct
{
    return _factory;
}

- (void)addRequestToList:(CTHttpRequest *)req
{
    NSString *key = [NSString stringWithFormat:@"%ld",(unsigned long)req.requestid];
    [_requestlist setObject:req forKey:key];
}

- (void)removeRequestFromList:(CTHttpRequest *)req
{
    NSString *key = [NSString stringWithFormat:@"%ld",(unsigned long)req.requestid];
    [_requestlist removeObjectForKey:key];
}

- (void)cancelAllRequest
{
    for (CTHttpRequest *req in [_requestlist allValues]) {
        [req cancel];
    }
    [_requestlist removeAllObjects];
}

- (NSString *)makeSuccessLog:(CTHttpRequest *)req
{
    NSString *log = [NSString stringWithFormat:@"=============================================== \n \
请求成功 \n \
请求Url = %@ ,\n 请求头域 = %@ ,\n 响应头域 = %@ ,\n 响应Body = %@\n \
===============================================",
     req.url.absoluteString,req.requestHeaders,
    req.response.allResponseHeaders,req.response.responseObject];
    return log;
}

- (NSString *)makeFailedLog:(CTHttpRequest *)req withError:(NSError *)err
{
    NSString *log = [NSString stringWithFormat:@"=============================================== \n \
请求失败 \n \
请求Url = %@ ,\n 请求头域 = %@ ,\n 响应头域 = %@,\n 错误 = %@ \n \
===============================================",req.url.absoluteString,
                     req.requestHeaders,req.response.allResponseHeaders,err];
    return log;
}

/***********************************普通请求******************************/
- (CTHttpRequest *)requesturl:(NSString *)url
               withHttpMothod:(CTHttpMethod)mothod
                  withHeaders:(NSDictionary *)headers
                   withParams:(id)params
                   useCookies:(BOOL)usecookie
           withTransferAsJson:(BOOL)isJson
                cacheResponse:(CTHttpCachePolicy)cache
                      andThen:(SuccessCompletion)success
                   withFailed:(FailedCompletion)failure
{
    CTHttpRequest *req = [_factory createRequest];
    [req setMethod:mothod];
    [req setRequestUrlString:url];
    
    if (req.isSSL) {
        if (!self.ssl) {
            req.security.allowInvalidCertificates = YES;
        }
        else
        {
            req.security = self.ssl;
        }
    }
    
    [req setRequestHeaders:headers];
    [req setRequestParams:params];
    [req setUseCookies:usecookie];
    [req setCachepolicy:cache];
    [req setUseJsonFormat:isJson];

    //设置回调
    [req setFinish:^(CTHttpRequest *request) {
        HttpLog(@"%@",[self makeSuccessLog:request]);
        if (success) {
            success(request);
        }
        [self removeRequestFromList:request];
    } withFailed:^(CTHttpRequest *request, NSError *error) {
        HttpLog(@"%@",[self makeFailedLog:request withError:error]);
        if (failure) {
            failure(request,error);
        }
        [self removeRequestFromList:request];
    }];
    
    [self addRequestToList:req];
    
    [req go];
    
    return req;
}

- (CTHttpRequest *)GET:(NSString *)URLString
           withHeaders:(NSDictionary *)headers
            parameters:(id)parameters
               success:(SuccessCompletion)success
               failure:(FailedCompletion)failure
{
    return [self requesturl:URLString withHttpMothod:httpGet withHeaders:headers withParams:parameters useCookies:YES withTransferAsJson:NO cacheResponse:httpCachePolicyNone andThen:success withFailed:failure];
}

- (CTHttpRequest *)GETForJson:(NSString *)URLString
                  withHeaders:(NSDictionary *)headers
                   withParams:(id)parameters
                      success:(SuccessCompletion)success
                      failure:(FailedCompletion)failure
{
    return [self requesturl:URLString withHttpMothod:httpGet withHeaders:headers withParams:parameters useCookies:YES withTransferAsJson:YES cacheResponse:httpCachePolicyNone andThen:success withFailed:failure];
}

- (CTHttpRequest *)HEAD:(NSString *)URLString
             parameters:(id)parameters
                success:(SuccessCompletion)success
                failure:(FailedCompletion)failure
{
    return [self requesturl:URLString withHttpMothod:httpHead withHeaders:nil withParams:parameters useCookies:YES withTransferAsJson:NO cacheResponse:httpCachePolicyNone andThen:success withFailed:failure];
}

- (CTHttpRequest *)POST:(NSString *)URLString
            withHeaders:(NSDictionary *)headers
             parameters:(id)parameters
                success:(SuccessCompletion)success
                failure:(FailedCompletion)failure
{
    return [self requesturl:URLString withHttpMothod:httpPost withHeaders:headers withParams:parameters useCookies:YES withTransferAsJson:NO cacheResponse:httpCachePolicyNone andThen:success withFailed:failure];
}

- (CTHttpRequest *)POSTForJson:(NSString *)URLString
                   withHeaders:(NSDictionary *)headers
                    withParams:(id)parameters
                       success:(SuccessCompletion)success
                       failure:(FailedCompletion)failure
{
    return [self requesturl:URLString withHttpMothod:httpPost withHeaders:headers withParams:parameters useCookies:YES withTransferAsJson:YES cacheResponse:httpCachePolicyNone andThen:success withFailed:failure];
}


- (CTHttpRequest *)POST:(NSString *)URLString
            withHeaders:(NSDictionary *)headers
             parameters:(id)parameters
constructingBodyWithBlock:(void (^)(id <CTHttpMutipartFormData> formData))block
                success:(SuccessCompletion)success
                failure:(FailedCompletion)failure
{
    CTHttpUploadRequest *req = [_factory createUploadRequest];
    [req setMethod:httpPost];
    [req setRequestUrlString:URLString];
    [req setRequestParams:parameters];
    [req setRequestHeaders:headers];
    
    if (req.isSSL) {
        if (!self.ssl) {
            req.security.allowInvalidCertificates = YES;
        }
        else
        {
            req.security = self.ssl;
        }
    }
    
    [req setPostFormdataBlock:^(CTHttpRequest *request, id<CTHttpMutipartFormData> formdata) {
        block(formdata);
    }];
    
    //设置回调
    [req setFinish:^(CTHttpRequest *request) {
        HttpLog(@"%@",[self makeSuccessLog:request]);
        if (success) {
            success(request);
        }
        [self removeRequestFromList:request];
    } withFailed:^(CTHttpRequest *request, NSError *error) {
        HttpLog(@"%@",[self makeFailedLog:request withError:error]);
        if (failure) {
            failure(request,error);
        }
        [self removeRequestFromList:request];
    }];
    
    [self addRequestToList:req];
    
    [req go];
    
    return req;
}


- (CTHttpRequest *)PUT:(NSString *)URLString
            parameters:(id)parameters
               success:(SuccessCompletion)success
               failure:(FailedCompletion)failure
{
    return [self requesturl:URLString withHttpMothod:httpPut withHeaders:nil withParams:parameters useCookies:YES withTransferAsJson:NO cacheResponse:httpCachePolicyNone andThen:success withFailed:failure];
}


- (CTHttpRequest *)DELETE:(NSString *)URLString
               parameters:(id)parameters
                  success:(SuccessCompletion)success
                  failure:(FailedCompletion)failure
{
    return [self requesturl:URLString withHttpMothod:httpDelete withHeaders:nil withParams:parameters useCookies:YES withTransferAsJson:NO cacheResponse:httpCachePolicyNone andThen:success withFailed:failure];
}

/*************************************上传***********************************************/
- (CTHttpUploadRequest *)upload:(NSString *)url
                    withHeaders:(NSDictionary *)headers
                     withParams:(id)params
                   withFilePath:(NSString *)fullpath
                   withMimetype:(NSString *)mimetype
                     useCookies:(BOOL)usecookie
                        andThen:(Progressing)progress
                   withComplete:(SuccessCompletion)success
                     withFailed:(FailedCompletion)failure
{
    CTHttpUploadRequest *uploadreq    = [_factory createUploadRequest];
    uploadreq.requestParams             = params;
    uploadreq.useCookies                = usecookie;
    uploadreq.requestHeaders            = headers;
    
    //如果未设置ssl但又是https 访问。则默认使用忽略认证服务器证书策略进行访问
    if (uploadreq.isSSL) {
        if (!self.ssl) {
            uploadreq.security.allowInvalidCertificates = YES;
        }
        else
        {
            uploadreq.security = self.ssl;
        }
    }
    
    NSString *filename = [fullpath lastPathComponent];
    
    [uploadreq setPostFormdataBlock:^(CTHttpRequest *request, id<CTHttpMutipartFormData> formdata) {
        [formdata appendPartWithFileURL:[NSURL fileURLWithPath:fullpath] name:@"file" fileName:filename mimeType:mimetype error:nil];
    }];
    
    [uploadreq setUploadProgress:progress];
    
    [uploadreq setFinish:^(CTHttpRequest *request) {
        HttpLog(@"%@",[self makeSuccessLog:request]);
        if (success) {
            success(request);
        }
        [self removeRequestFromList:request];
    } withFailed:^(CTHttpRequest *request, NSError *error) {
        HttpLog(@"%@",[self makeFailedLog:request withError:error]);
        if (failure) {
            failure(request,error);
        }
        [self removeRequestFromList:request];
    }];
    
    [self addRequestToList:uploadreq];
    
    [uploadreq go];
    
    return uploadreq;
}

- (CTHttpUploadRequest *)uploadImage:(NSString *)url
                         withHeaders:(NSDictionary *)headers
                          withParams:(id)params
                       withImageData:(NSData *)image
                        withFileName:(NSString *)filename
                        withMimetype:(NSString *)mimetype
                          useCookies:(BOOL)usecookie
                        withComplete:(SuccessCompletion)success
                          withFailed:(FailedCompletion)failure
{
    CTHttpUploadRequest *uploadreq    = [_factory createUploadRequest];
    uploadreq.requestParams             = params;
    uploadreq.useCookies                = usecookie;
    uploadreq.requestHeaders            = headers;
    
    //如果未设置ssl但又是https 访问。则默认使用忽略认证服务器证书策略进行访问
    if (uploadreq.isSSL) {
        if (!self.ssl) {
            uploadreq.security.allowInvalidCertificates = YES;
        }
        else
        {
            uploadreq.security = self.ssl;
        }
    }

    [uploadreq setPostFormdataBlock:^(CTHttpRequest *request, id<CTHttpMutipartFormData> formdata) {
        [formdata appendPartWithFileData:image name:@"file" fileName:filename mimeType:mimetype];
    }];
    
    [uploadreq setFinish:^(CTHttpRequest *request) {
        HttpLog(@"%@",[self makeSuccessLog:request]);
        if (success) {
            success(request);
        }
        [self removeRequestFromList:request];
    } withFailed:^(CTHttpRequest *request, NSError *error) {
        HttpLog(@"%@",[self makeFailedLog:request withError:error]);
        if (failure) {
            failure(request,error);
        }
        [self removeRequestFromList:request];
    }];
    
    [self addRequestToList:uploadreq];
    
    [uploadreq go];
    
    return uploadreq;
}

/************************************下载***************************************/

- (CTHttpDownloadRequest *)downloadFileForURLString:(NSString *)url
                                      withStorepath:(NSString *)filepath
                                        withHeaders:(NSDictionary *)headers
                                         withParams:(id)params
                                             resume:(BOOL)isbreakpoint
                                         useCookies:(BOOL)usecookie
                                            andThen:(Progressing)progress
                                       withComplete:(SuccessCompletion)success
                                         withFailed:(FailedCompletion)failure
{
    CTHttpDownloadRequest *downloadreq    = [_factory createDownloadRequest];
    downloadreq.requestParams               = params;
    downloadreq.requestHeaders              = headers;
    downloadreq.useCookies                  = usecookie;
    downloadreq.downloadPath                = [filepath stringByDeletingLastPathComponent];
    downloadreq.storeFileName               = [filepath lastPathComponent];
    downloadreq.isResumeBreakpoint          = isbreakpoint;
    
    //如果未设置ssl但又是https 访问。则默认使用忽略认证服务器证书策略进行访问
    if (downloadreq.isSSL) {
        if (!self.ssl) {
            downloadreq.security.allowInvalidCertificates = YES;
        }
        else
        {
            downloadreq.security = self.ssl;
        }
    }
    
    [downloadreq setDownloadProgress:progress];
    
    [downloadreq setFinish:^(CTHttpRequest *request) {
        HttpLog(@"%@",[self makeSuccessLog:request]);
        if (success) {
            success(request);
        }
        [self removeRequestFromList:request];
    } withFailed:^(CTHttpRequest *request, NSError *error) {
        HttpLog(@"%@",[self makeFailedLog:request withError:error]);
        if (failure) {
            failure(request,error);
        }
        [self removeRequestFromList:request];
    }];
    
    [self addRequestToList:downloadreq];
    
    [downloadreq go];
    
    return downloadreq;
}

@end
