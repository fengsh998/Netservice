//
//  CTNetServerDTOBase.h
//  QianbaoIM
//
//  Created by fengsh on 10/5/15.
//  Copyright (c) 2015年 qianbao.com. All rights reserved.
//
/**
 *  网络数据传输模块(基类)
 *  基类的属性推荐使用Copy属性
 */
#import "CTModelObject.h"

@protocol CTNetServerDTOIntf <NSObject>

/**
 *  子类进行实现
 *  将子类中DTO的各属性处理成提交给服务器需要的参数格式的Dic
 *  @return NSDictionary
 */
- (NSDictionary *)convertObjctToDictionary;

/**
 *  通过网络返回的Dictionary来生成对象
 *
 *  @param dictionary 网络返回的Dictionary
 *
 *  @return 对象
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

@interface CTNetServerDTOBase : CTModelObject<CTNetServerDTOIntf>
{
    @private
    NSDictionary                        *_custom;
}

//用户可以自定义(用于请求时传递的参数)
//通过父类的convertObjctToDictionary方法可以获取到custom
/**
 *  子类只需要实现
    - (NSDictionary *)convertObjctToDictionary
    {
            //自定义的构建
            NSDictionary *param = [super convertObjctToDictionary];
            if (!param)
            {
                 param = //TODO:(子类的构建)
            }
            return param;
    }
 */
- (void)setCustomDTODictionary:(NSDictionary *)custom;
@end



