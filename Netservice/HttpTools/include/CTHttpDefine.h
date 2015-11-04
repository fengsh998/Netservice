//
//  CTHttpDefine.h
//  QianbaoIM
//
//  Created by fengsh on 18/4/15.
//  Copyright (c) 2015年 qianbao.com. All rights reserved.
//
/**
 *  此头文件的中的各对象可供上层自由调用灵活处理。
 *
 *
 **********************************************************************************************
 /
 /                         上层业务只需要单纯的与CTHttpRequestConstruction交互即可
 /                                             ↓
 /                                   CTHttpRequestConstruction
 /                                             ↓
 /                                       底层隐藏实现细节
 /
 /
 **********************************************************************************************
 */

#ifndef QianbaoIM_CTHttpDefine_h
#define QianbaoIM_CTHttpDefine_h
//***********************************使用对象方式请求**************************************//
//********************************可对外独立使用的一套API**********************************//

@class CTHttpResponse;
@class CTHttpRequest;
@class CTHttpUploadRequest;
@class CTHttpDownloadRequest;

typedef NSError CTHttpError;

typedef NSUInteger CTHttpRequestID;

//使用传参的方式，避免block retain cycle.
typedef void (^SuccessCompletion)(CTHttpRequest *request);
//使用传参的方式，避免block retain cycle.
typedef void (^FailedCompletion)(CTHttpRequest *request,CTHttpError *error);
typedef void (^Progressing)(CTHttpRequest *request,long long int recvLen,
                            long long int recvTotalLen,
                            long long int totalLength);


///预留协议库引擎处理
typedef NS_ENUM(NSInteger, APIType)
{
    apiAFNewWorking             = 0,
    apiASIHttpRequest              ,    //暂未支持(后备扩展)
    apiNSURLSession                     //暂未支持(后备扩展)
};

typedef NS_ENUM(NSUInteger, CTSSLPinningMode) {
    CTSSLPinningModeNone,
    CTSSLPinningModePublicKey,
    CTSSLPinningModeCertificate,
};

///常用http请求方式
typedef NS_ENUM(NSInteger, CTHttpMethod)
{
    httpGet                  = 0,
    httpPost                 ,
    httpPut                  ,
    httpDelete               ,
    httpHead
};

// /缓存策略
typedef NS_ENUM(NSInteger, CTHttpCachePolicy)
{
    httpCachePolicyNone                             = -1,//不设置缓存
    ///基础缓存
    httpCachePolicyDefault                          ,//NSURLRequestUseProtocolCachePolicy
    ///忽略本地缓存
    httpCachePolicyIgnoringLocalCache               ,//NSURLRequestReloadIgnoringLocalCacheData
    ///首先使用缓存，如果没有本地缓存，才从原地址下载
    httpCachePolicyCheckLocalCache                  ,//NSURLRequestReturnCacheDataElseLoad
    ///使用本地缓存，从不下载，如果本地没有缓存，则请求失败。此策略多用于离线操作
    httpCachePolicyOnlyLocalCache                   ,//NSURLRequestReturnCacheDataDontLoad
    ///无视任何的缓存策略，无论是本地的还是远程的，总是从原地址重新下载
    httpCachePolicyNeverRemoteCache                 ,//NSURLRequestReloadIgnoringLocalAndRemoteCacheData
    ///如果本地缓存是有效的则不下载。其他任何情况都从原地址重新下载
    httpCachePolicyNoRequestWhenExsistLocalCache    //NSURLRequestReloadRevalidatingCacheData
};

///协议层错误定义
typedef NS_ENUM(NSInteger, CTNetErrorType)
{
    kCTNetErrorUnkown                = -1,
    kCTNetErrorConnectCancel         = -999,         //连接被取消
    kCTNetErrorBadURL                = -1000,        //URL不正确或URL编码有问题
    kCTNetErrorConnectTimeout        = -1001,        //连接超时
    kCTNetErrorNotconnect            = -1011,        //无网络连接错误
    kCTNetErrorNotFindHost           = -1003,        //找不到主机
    kCTNetErrorCannotConnectToHost   = -1004,        //不能连接到主机
    kCTNetErrorConnectionLost        = -1005         //网络连接掉失
};

///响应对象
@interface CTHttpResponse : NSObject<NSCopying>
///表示该响应来自某个请求
@property (nonatomic,assign)    CTHttpRequestID                 contextRequestid;
///http状态码200,302,404,500等
@property (nonatomic,assign)    NSInteger                       statuscode;
///响应的头域
@property (nonatomic,copy)      NSDictionary                    *allResponseHeaders;
@property (nonatomic,copy)      id                              responseObject;
@end

#pragma mark - 接口实例化构造器

@protocol ICTHttpRequestConstruction <NSObject>
@optional
- (CTHttpRequest *)createRequest;
- (CTHttpUploadRequest *)createUploadRequest;
- (CTHttpDownloadRequest *)createDownloadRequest;
@end

//通过该对象来产生可用的实列
@interface CTHttpRequestConstruction : NSObject
+ (CTHttpRequest *)createAnValidRequest;
+ (CTHttpUploadRequest *)createAnValidUploadRequest;
+ (CTHttpDownloadRequest *)createAnValidDownloadRequest;
@end

@interface CTSecurityPolicy : NSObject
///默认为CTSSLPinningModeNone
@property (nonatomic, assign) CTSSLPinningMode                  sslPinningMode;
///是否验证keyChain中的证书默认为YES
@property (nonatomic, assign) BOOL                              validatesCertificateChain;
///app bundle包括的证书(`.cer`) certificates
@property (nonatomic, strong) NSArray                           *pinnedCertificates;
///是否信认服务器无效证书,默认为NO
@property (nonatomic, assign) BOOL                              allowInvalidCertificates;
// /是否验证域名针对CTSSLPinningModePublicKey,CTSSLPinningModeCertificate,为YES,否则为NO
@property (nonatomic, assign) BOOL                              validatesDomainName;
//使用keychain的证书
@property (nonatomic, assign) BOOL                              shouldUseCredentialStorage;
//当收到挑战后使用的证书
@property (nonatomic, strong) NSURLCredential                   *credential;
@end;

#pragma mark - 接口声明(不能直接实例化使用)
/**
 *  暂未处理，先声明，开发中....
 */
@protocol CTHttpRequestProtocol <NSObject>
///发起请求
- (void)go;  //代理出去给别人实现
///取消请求
- (void)cancel;

@end

@protocol CTHttpRequestTransferProtocol <NSObject>

@optional
/**
 *  主要放在上传和下载中来实现此方法(在外部稍加个定时器每秒调用此方法，通过差值就可以得到网速)
 *  @return 调用此刻已经上传或下载了的流量大小。
 */
- (long long int)sizeOfTranferedTotalBytes;
///特殊场景使用
///暂停请求
- (void)supend;
///恢复请求
- (void)resume;

@end

///post 表单数据协义
@protocol CTHttpMutipartFormData <NSObject>

@optional
- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                        error:(NSError * __autoreleasing *)error;

- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                     fileName:(NSString *)fileName
                     mimeType:(NSString *)mimeType
                        error:(NSError * __autoreleasing *)error;

- (void)appendPartWithFileData:(NSData *)data
                          name:(NSString *)name
                      fileName:(NSString *)fileName
                      mimeType:(NSString *)mimeType;

- (void)appendPartWithHeaders:(NSDictionary *)headers
                         body:(NSData *)body;

@end

///普通的请求(不能直接使用,只为扩展声明)
@interface CTHttpRequest : NSObject<NSCopying,CTHttpRequestProtocol>
@property (nonatomic, readonly) CTHttpRequestID                 requestid;
///请求的URL
@property (nonatomic, readonly) NSURL                           *url;
///如果果请求url的scheam为https 时为YES,否则为NO
@property (nonatomic, readonly) BOOL                            isSSL;
///可供自定义的上下文处理tag
@property (nonatomic, assign)   NSInteger                       tag;
///请求超时(default 60 seconds)
@property (nonatomic, assign)   NSTimeInterval                  timeout;
///请求的方式
@property (nonatomic, assign)   CTHttpMethod                    method;
///请求头
@property (nonatomic, copy)     NSDictionary                    *requestHeaders;
///请求是否使用cookie
@property (nonatomic, assign)   BOOL                            useCookies;
///响应的缓存策略
@property (nonatomic, assign)   CTHttpCachePolicy               cachepolicy;
///响应对象
@property (nonatomic, copy)     CTHttpResponse                  *response;
/**
 *  请求的参数，当GET,HEAD,DELETE时会被追加在url后面传输,POST,PUT时，放在body里传输
 */
@property (nonatomic, copy)     id                              requestParams;
/**
 *  默认为NO,是二进制传输方式，当YES时，支持json格式的请求及响应。
 *  只针对普通的请求对于上传，下载时暂不启作用。
 */
@property (nonatomic, assign)   BOOL                            useJsonFormat;
// /上下文使用
@property (nonatomic, strong)   id                              userInfo;

/*******************************SSL***********************************************/
///SSL安全策略
@property (nonatomic, strong) CTSecurityPolicy                  *security;
/*********************************************************************************/

@property (nonatomic, readonly) SuccessCompletion               successCallBack;
@property (nonatomic, readonly) FailedCompletion                failureCallBack;

- (instancetype)initWithURLString:(NSString *)url;
///设置请求URL(setter)
- (void)setRequestUrlString:(NSString *)url;
///成功和失败的回调(block方式)
- (void)setFinish:(SuccessCompletion)finish withFailed:(FailedCompletion)failure;
@end

typedef void (^PostFormData)(CTHttpRequest *request,id<CTHttpMutipartFormData> formdata);
///上传的
@interface CTHttpUploadRequest : CTHttpRequest<CTHttpRequestTransferProtocol>

- (void)setPostFormdataBlock:(PostFormData)formdata;
///上传进度
- (void)setUploadProgress:(Progressing)progress;
@end

///下载的
@interface CTHttpDownloadRequest : CTHttpRequest<CTHttpRequestTransferProtocol>

///YES,则在下载时恢复断点续传,(default yes)
@property (nonatomic, assign) BOOL                      isResumeBreakpoint;
///下载路径(不带文件名)
@property (nonatomic, strong) NSString                  *downloadPath;
///保存的文件名(如果nil,则文件名从请求的URL中提取,因此对于有些请求需要重定向的，就要进行指定)
@property (nonatomic, strong) NSString                  *storeFileName;
///下载进度
- (void)setDownloadProgress:(Progressing)progress;

@end


#endif
