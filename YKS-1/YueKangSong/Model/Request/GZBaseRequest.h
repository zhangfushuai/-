//
//  GZBaseRequest.h
//  GZTour
//
//  Created by gongliang on 14/12/4.
//  Copyright (c) 2014年 . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GZHTTPClient.h"
#import "YKSTools.h"
#import "YKSConstants.h"


@interface GZBaseRequest : NSObject

//获取后台版本
+(void)getBackgroundVersionAndcallBack:(void (^)(id responseObject, NSError *error ))callback;


/************************* 登录 *************************/
+ (NSURLSessionDataTask *)loginByMobilephone:(NSString *)phone
                                    password:(NSString *)password
                                    callback:(void (^)(id responseObject, NSError *error))callback;
//获取验证码
+ (NSURLSessionDataTask *)verifyCodeByMobilephone:(NSString *)phone
                                         callback:(void (^)(id responseObject, NSError *error))callback;

+ (NSURLSessionDataTask *)modifyToken:(NSString *)token
                             callback:(void (^)(id responseObject, NSError *error))callback;

/************************* 首页 *************************/
//首页列表
+ (NSURLSessionDataTask *)specialListCallback:(void (^)(id responseObject, NSError *error))callback;

//子专题列表
+ (NSURLSessionDataTask *)subSpecialListByspecialId:(NSString *)specialId
                                           callback:(void (^)(id responseObject, NSError *error))callback;

//子专题内容
+ (NSURLSessionDataTask *)subSpecialDetailBy:(NSString *)specialId
                                    callback:(void (^)(id responseObject, NSError *error))callback;
//首页轮播图banner
+ (NSURLSessionDataTask *)bannerListByMobilephone:(NSString *)phone
                                         callback:(void (^)(id responseObject, NSError *error))callback;

//通过key搜索商品
+ (NSURLSessionDataTask *)searchByKey:(NSString *)key
                                 page:(NSInteger)page
                             callback:(void (^)(id responseObject, NSError *error))callback;

/************************* 药品 *************************/
//药品分类列表
+ (NSURLSessionDataTask *)drugCategoryListCallback:(void (^)(id responseObject, NSError *error))callback;
//根据药品该类获得
+ (NSURLSessionDataTask *)drugListByCategoryId:(NSString *)categoryId
                                      callback:(void (^)(id responseObject, NSError *error))callback;

/************************* 购物车 *************************/
+ (NSURLSessionDataTask *)shoppingcartListCallback:(void (^)(id responseObject, NSError *error))callback;
+ (NSURLSessionDataTask *)addToShoppingcartParams:(NSArray *)gcontrast
                                             gids:(NSString *)gids
                                         callback:(void (^)(id responseObject, NSError *error))callback;
+ (NSURLSessionDataTask *)deleteShoppingCartBygids:(NSString *)gids
                                          callback:(void (^)(id responseObject, NSError *error))callback;
+ (NSURLSessionDataTask *)restartShoppingCartBygids:(NSString *)gids
                                           callback:(void (^)(id responseObject, NSError *error))callback;

/************************* 收藏 *************************/
/**
 *  收藏列表
 *  @param page     第几页 每页10条
 */
+ (NSURLSessionDataTask *)collectListByPage:(NSInteger)page
                                   callback:(void (^)(id responseObject, NSError *error))callback;
+ (NSURLSessionDataTask *)addCollectByGid:(NSString *)gid
                                 callback:(void (^)(id responseObject, NSError *error))callback;
+ (NSURLSessionDataTask *)deleteCollectByGid:(NSString *)gids
                                    callback:(void (^)(id responseObject, NSError *error))callback;

/************************* 收货地址 *************************/
+ (NSURLSessionDataTask *)areaInfoCallBack:(void (^)(id responseObject, NSError *error))callback;
+ (NSURLSessionDataTask *)addressListCallback:(void (^)(id responseObject, NSError *error))callback;
//增加收货地址
+ (NSURLSessionDataTask *)addAddressExpressArea:(NSString *)expressArea
                                      community:(NSString *)community
                                communityLatLng:(NSString *)communityLatLng
                                  detailAddress:(NSString *)detailAddress
                                       contacts:(NSString *)contact
                                      telePhone:(NSString *)telePhone
                                       callback:(void (^)(id responseObject, NSError *error))callback;
//编辑收货地址
+ (NSURLSessionDataTask *)editAddressById:(NSString *)addressId
                              expressArea:(NSString *)expressArea
                                community:(NSString *)community
                          communityLatLng:(NSString *)communityLatLng
                            detailAddress:(NSString *)detailAddress
                                 contacts:(NSString *)contact
                                telePhone:(NSString *)telePhone
                                 callback:(void (^)(id responseObject, NSError *error))callback;
//删除收货地址
+ (NSURLSessionDataTask *)deleteAddressById:(NSString *)addressId
                                   callback:(void (^)(id responseObject, NSError *error))callback;

//快递单号查询
+ (NSURLSessionDataTask *)expressInfo:(NSString *)expressId
                             callback:(void (^)(id responseObject, NSError *error))callback;

/************************* 订单 *************************/
+ (NSURLSessionDataTask *)searchOrderByOrderId:(NSString *)orderId
                                          page:(NSInteger)page
                                      callback:(void (^)(id responseObject, NSError *error))callback;
+ (NSURLSessionDataTask *)searchOrderByOrderStatus:(NSInteger)status
                                              page:(NSInteger)page
                                          callback:(void (^)(id responseObject, NSError *error))callback;
+ (NSURLSessionDataTask *)searchOrderByDrugId:(NSString *)did
                                         page:(NSInteger)page
                                     callback:(void (^)(id responseObject, NSError *error))callback;
+ (NSURLSessionDataTask *)submitOrderContrast:(NSArray *)gcontrast
                                     couponid:(NSString *)couponId
                                    addressId:(NSString *)addressId
                                       images:(NSArray *)images
                                     callback:(void (^)(id responseObject, NSError *error))callback;

/************************* 优惠劵 *************************/
+ (NSURLSessionDataTask *)couponList:(NSInteger)page
                            callback:(void (^)(id responseObject, NSError *error))callback;
+ (NSURLSessionDataTask *)convertCouponBByCode:(NSString *)code
                                      callback:(void (^)(id responseObject, NSError *error))callback;

/************************* 其它 *************************/
//问题反馈
+ (NSURLSessionDataTask *)feedbackByContent:(NSString *)content
                                   callback:(void (^)(id responseObject, NSError *error))callback;

+ (NSURLSessionDataTask *)myInfocallback:(void (^)(id responseObject, NSError *error))callback;
+ (NSURLSessionDataTask *)editMyInfoAge:(NSInteger)age
                                    sex:(NSInteger)sex
                                   name:(NSString *)name
                               callback:(void (^)(id responseObject, NSError *error))callbac;
//配送区域
+ (NSURLSessionDataTask *)baseInfocallback:(void (^)(id responseObject, NSError *error))callback;

//消息
+ (NSURLSessionDataTask *)msgListByPage:(NSInteger)page
                               callback:(void (^)(id responseObject, NSError *error))callback;
//上传经纬度
+ (NSURLSessionDataTask *)locationUploadLat:(CGFloat)lat
                                        lng:(CGFloat)lng
                                   callback:(void (^)(id responseObject, NSError *error))callback;

@end
