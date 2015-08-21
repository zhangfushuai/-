//
//  YKSHomeTableViewController.m
//  YueKangSong
//
//  Created by gongliang on 15/5/12.
//  Copyright (c) 2015年 YKS. All rights reserved.
//
#import "UIAlertView+Block.h"
#import "YKSHomeTableViewController.h"
#import "GZBaseRequest.h"
#import "UIViewController+Common.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "YKSSpecialView.h"
#import "YKSSpecial.h"
#import <ImagePlayerView/ImagePlayerView.h>
#import "YKSSubSpecialListTableViewController.h"
#import "YKSAppDelegate.h"
#import <INTULocationManager/INTULocationManager.h>
#import "YKSSelectAddressView.h"
#import "YKSAddAddressVC.h"
#import "YKSQRCodeViewController.h"
#import "YKSDrugListViewController.h"
#import "YKSUserModel.h"
#import "YKSHomeListCell.h"
#import "YKSWebViewController.h"

@interface YKSHomeTableViewController () <ImagePlayerViewDelegate,UIAlertViewDelegate,UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *addressButton;
@property (strong, nonatomic) ImagePlayerView *imagePlayview;

@property (assign, nonatomic) BOOL isShowAddressView;

@property (copy, nonatomic) NSArray *datas;
@property (strong, nonatomic) NSArray *imageURLStrings;
@property (strong, nonatomic) NSDictionary *myAddressInfo;


@property (strong, nonatomic) NSDictionary *info;
@property (assign, nonatomic) BOOL isCreat;

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIPageControl *pageControl;

@end

@implementation YKSHomeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"";
    
    _addressButton.frame = CGRectMake(0, 0, SCREEN_WIDTH - 10, 25);
    //    _addressButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    //    _addressButton.titleLabel.minimumScaleFactor = 8/[UIFont labelFontSize];
    
    //    UIImageView *logoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 141, 25)];
    //    logoImageView.image = [UIImage imageNamed:@"logo"];
    //    UIBarButtonItem *leftBar = [[UIBarButtonItem alloc] initWithCustomView:logoImageView];
    //    self.navigationItem.leftBarButtonItem = leftBar;
    
    self.tableView.tableHeaderView = [self tableviewHeaderView];
    [self startSingleLocationRequest];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    NSInteger offset = scrollView.contentOffset.x/SCREEN_WIDTH;
    _pageControl.currentPage = offset;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!_datas) {
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"kHomeDatas"]) {
            _datas = [[NSUserDefaults standardUserDefaults] objectForKey:@"kHomeDatas"];
            [self.tableView reloadData];
        }
        [GZBaseRequest specialListCallback:^(id responseObject, NSError *error) {
            //        NSLog(@"responseObject = %@", responseObject);
            if (ServerSuccess(responseObject)) {
                _datas = responseObject[@"data"][@"list"];
                [self.tableView reloadData];
                [[NSUserDefaults standardUserDefaults] setObject:_datas forKey:@"kHomeDatas"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            } else {
                [self showToastMessage:responseObject[@"msg"]];
            }
        }];
    }
    if (!_imageURLStrings) {
        
        [GZBaseRequest bannerListByMobilephone:@""
                                      callback:^(id responseObject, NSError *error) {
                                          if (error) {
                                              [self showToastMessage:@"网络加载失败"];
                                              return ;
                                          }
                                          if (ServerSuccess(responseObject)) {
                                              _imageURLStrings = responseObject[@"data"][@"data"];
                                              _scrollView.contentSize = CGSizeMake(SCREEN_WIDTH*_imageURLStrings.count, 0);
                                              _pageControl.pageIndicatorTintColor= [UIColor colorWithRed:50.0/255 green:143.0/255 blue:250.0/255 alpha:1];
                                              _pageControl.currentPageIndicatorTintColor = [UIColor redColor];
                                              _pageControl.numberOfPages = _imageURLStrings.count;
                                              _pageControl.currentPage = 0;
                                              for (int i = 0; i<_imageURLStrings.count; i++) {
                                                  UIImageView *iv = [[UIImageView alloc]initWithFrame:CGRectMake(i*SCREEN_WIDTH, 0, SCREEN_WIDTH, _scrollView.bounds.size.height)];
                                                  [iv sd_setImageWithURL:_imageURLStrings[i][@"imgurl"]placeholderImage:[UIImage imageNamed:@"defatul320"]];
                                                  [_scrollView addSubview:iv];
                                              }
                                              
                                              
                                              
//                                              [_imagePlayview reloadData];
                                          } else {
                                              [self showToastMessage:responseObject[@"msg"]];
                                          }
                                      }];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (_isShowAddressView) {
        [self showAddressView];
    }
    
    //首页显示,如果有标志,我们直接显示地址列表
    if ([UIViewController selectedAddressButtonUnArchiver] == 1) {
        [UIViewController selectedAddressButtonArchiver:1000];
        [self showAddressView];
    }
    
}

#pragma mark - custom
- (UIView *)tableviewHeaderView {
    
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH / 320 * kCycleHeight)];
    UIView *view = [[UIView alloc]initWithFrame:_scrollView.bounds];
    [view addSubview:_scrollView];
    _pageControl = [[UIPageControl alloc]init];
    [view addSubview:_pageControl];
    _pageControl.center = CGPointMake(SCREEN_WIDTH/2, _scrollView.bounds.size.height-10);
    
    _pageControl.currentPageIndicatorTintColor = [UIColor redColor];
    _pageControl.pageIndicatorTintColor = [UIColor colorWithRed:50.0/255 green:143.0/255 blue:250.0/255 alpha:1];

    
//    _pageControl.center = CGPointMake(SCREEN_WIDTH/2, _scrollView.bounds.size.height-50);
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.delegate = self;
    _scrollView.bounces = NO;
    _scrollView.pagingEnabled = YES;
    return view;
    
    
    
//    _imagePlayview = [[ImagePlayerView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH / 320 * kCycleHeight)];
//    _imagePlayview.imagePlayerViewDelegate = self;
//    _imagePlayview.scrollInterval = 99999;
//    _imagePlayview.pageControlPosition = ICPageControlPosition_BottomRight;
//    return _imagePlayview;
}

- (void)startSingleLocationRequest {
    INTULocationManager *locMgr = [INTULocationManager sharedInstance];
    [locMgr requestLocationWithDesiredAccuracy:INTULocationAccuracyNeighborhood
                                       timeout:10.0f
                                         block:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
                                             NSString *latLongString = [[NSString alloc] initWithFormat:@"%f,%f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude];
                                             if ([YKSUserModel shareInstance].lat == 0) {
                                                 [YKSUserModel shareInstance].lat = currentLocation.coordinate.latitude;
                                                 [YKSUserModel shareInstance].lng = currentLocation.coordinate.longitude;
                                             }
                                             
                                             if ([YKSUserModel isLogin]) {
                                                 [GZBaseRequest locationUploadLat:currentLocation.coordinate.latitude
                                                                              lng:currentLocation.coordinate.longitude
                                                                         callback:^(id responseObject, NSError *error) {
                                                                             
                                                                         }];
                                             }
                                             
                                             [[GZHTTPClient shareClient] GET:BaiduMapGeocoderApi
                                                                  parameters:@{@"location": latLongString,
                                                                               @"coordtype": @"wgs84ll",
                                                                               @"ak": BaiduMapAK,
                                                                               @"output": @"json"}
                                                                     success:^(NSURLSessionDataTask *task, id responseObject) {
                                                                         if (responseObject && [responseObject[@"status"] integerValue] == 0) {
                                                                             NSDictionary *dic = responseObject[@"result"];
                                                                             _myAddressInfo = dic;
                                                                             [self.addressButton setTitle:dic[@"sematic_description"] forState:UIControlStateNormal];
                                                                             if ([YKSUserModel shareInstance].currentSelectAddress) {
                                                                                 NSDictionary *info = [YKSUserModel shareInstance].currentSelectAddress;
                                                                                 NSString *tempString = [NSString stringWithFormat:@"%@", info[@"community"] ? info[@"community"] : @""];
                                                                                 if (info[@"sendable"] && ![info[@"sendable"] boolValue]) {
                                                                                     NSString *title = [NSString stringWithFormat:@"%@(暂不支持配送)", tempString];
                                                                                     [self.addressButton setTitle:title
                                                                                                         forState:UIControlStateNormal];
                                                                                 } else {
                                                                                     [self.addressButton setTitle:tempString
                                                                                                         forState:UIControlStateNormal];
                                                                                 }
                                                                             }
                                                                         }
                                                                         NSLog(@"responseObject %@", responseObject);
                                                                     }
                                                                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                                                                         NSLog(@"error = %@", error);
                                                                     }];
                                         }];
}

- (NSDictionary *)currentAddressInfo {
    NSString *district = _myAddressInfo[@"addressComponent"][@"district"];
    NSString *street = _myAddressInfo[@"addressComponent"][@"street"];
    NSString *street_number = _myAddressInfo[@"addressComponent"][@"street_number"];
    NSString *formatted_address = _myAddressInfo[@"formatted_address"];
    return @{@"province": @"11",
             @"district": district ? district : @"",
             @"street":  street ? street : @"",
             @"street_number":  street_number ? street_number : @"",
             @"express_username": @"我的位置",
             @"express_mobilephone": @"",
             @"express_detail_address":  formatted_address? formatted_address : @""};
}

- (void)gotoAddressVC:(NSDictionary *)addressInfo {
    _isShowAddressView = YES;
    if (![YKSUserModel isLogin]) {
        [YKSTools login:self];
        return;
    }
    
    UIStoryboard *mainBoard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    YKSAddAddressVC *vc = [mainBoard instantiateViewControllerWithIdentifier:@"YKSAddAddressVC"];
    vc.addressInfo = [addressInfo mutableCopy];
    vc.isCurrentLocation = YES;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}


-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==1) {
        __weak id bself = self;
        YKSSelectAddressView *selectAddressView = nil;
         {
           //新添
             NSDictionary *info = self.info;
             BOOL isCreate = self.isCreat;
                                                                   
//                                                                   if (![[[YKSUserModel shareInstance]currentSelectAddress][@"id"]isEqualToString:info[@"id"]]) {
//                                                                       UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"修改地址？" message:@"确认修改地址将清空购物车" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
//                                                                       [alert show];
//                                                                       
//                                                                       
//                                                                   }
                                                                   if (info) {
                                                                       if (info[@"community_lat_lng"]) {
                                                                           NSArray *array = [info[@"community_lat_lng"] componentsSeparatedByString:@","];
                                                                           [YKSUserModel shareInstance].lat = [[array firstObject] floatValue];
                                                                           [YKSUserModel shareInstance].lng = [[array lastObject] floatValue];
                                                                       }
                                                                       if (![YKSUserModel shareInstance].currentSelectAddress) {
                                                                           [YKSUserModel shareInstance].currentSelectAddress = info;
                                                                           //                                                                       NSLog(@"当前经纬度 = %f %f \n %@", [YKSUserModel shareInstance].lat,
                                                                           //                                                                             [YKSUserModel shareInstance].lng,
                                                                           //                                                                             [YKSUserModel shareInstance].currentSelectAddress);
                                                                       }
                                                                       
                                                                   }
                                                                   if (isCreate) {
                                                                       [bself gotoAddressVC:info];
                                                                   } else {
                                                                       _isShowAddressView = NO;
                                                                       [YKSUserModel shareInstance].currentSelectAddress = info;
                                                                       //这里就是了,拿到地址,删除旧地址
                                                                       
                                                                       [UIViewController deleteFile];           [UIViewController selectedAddressArchiver:info];
                                                                       
                                                                       NSString *tempString = [NSString stringWithFormat:@"%@", info[@"community"] ? info[@"community"] : @""];
                                                                       if (info[@"sendable"] && ![info[@"sendable"] boolValue]) {
                                                                           NSString *title = [NSString stringWithFormat:@"%@(暂不支持配送)", tempString];
                                                                           [self.addressButton setTitle:title
                                                                                               forState:UIControlStateNormal];
                                                                       } else {
                                                                           [self.addressButton setTitle:tempString
                                                                                               forState:UIControlStateNormal];
                                                                       }
                                                                   }
                                                               };
        //    [selectAddressView reloadData];
        selectAddressView.removeViewCallBack = ^{
            _isShowAddressView = NO;
        };
        [GZBaseRequest addressListCallback:^(id responseObject, NSError *error) {
            if (ServerSuccess(responseObject)) {
                NSDictionary *dic = responseObject[@"data"];
                if ([dic isKindOfClass:[NSDictionary class]] && dic[@"addresslist"]) {
                    selectAddressView.datas = [dic[@"addresslist"] mutableCopy];
                    [YKSUserModel shareInstance].addressLists = selectAddressView.datas;
                    if (!selectAddressView.datas) {
                        selectAddressView.datas = [NSMutableArray array];
                    }
                    [selectAddressView.datas insertObject:[self currentAddressInfo] atIndex:0];
                    [selectAddressView reloadData];
                }
            }
        }];

    }
    
    
}

//显示地址
- (void)showAddressView {
    if (![YKSUserModel isLogin]) {
        [YKSTools login:self];
        return ;
    }
    __weak id bself = self;
    YKSSelectAddressView *selectAddressView = nil;
    selectAddressView = [YKSSelectAddressView showAddressViewToView:self.view.window
                                                              datas:@[[self currentAddressInfo]]
                                                           callback:^(NSDictionary *info, BOOL isCreate) {
                                                            //新添
                                                               self.info = info;
                                                               self.isCreat = isCreate;
                                                               
                                                               if (![[[YKSUserModel shareInstance]currentSelectAddress][@"id"]isEqualToString:info[@"id"]]) {
                                                                   UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"修改地址？" message:@"确认修改地址将清空购物车" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
                                                                   [alert show];
                                                                   return ;
//                                                              [alert callBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
//                                                                  if (buttonIndex == 1) {
//                                                                      
//                                                                  }
//                                                              }];
                                                               }
                                                               if (info) {
                                                                   if (info[@"community_lat_lng"]) {
                                                                       NSArray *array = [info[@"community_lat_lng"] componentsSeparatedByString:@","];
                                                                       [YKSUserModel shareInstance].lat = [[array firstObject] floatValue];
                                                                       [YKSUserModel shareInstance].lng = [[array lastObject] floatValue];
                                                                   }
                                                                   if (![YKSUserModel shareInstance].currentSelectAddress) {
                                                                       [YKSUserModel shareInstance].currentSelectAddress = info;
                                                                   }
                                                                   
                                                               }
                                                               if (isCreate) {
                                                                   [bself gotoAddressVC:info];
                                                               } else {
                                                                   _isShowAddressView = NO;
                                                                   [YKSUserModel shareInstance].currentSelectAddress = info;
                                                                   //这里就是了,拿到地址,删除旧地址
                                                                   
                                                                   [UIViewController deleteFile];           [UIViewController selectedAddressArchiver:info];
                                                                   
                                                                   NSString *tempString = [NSString stringWithFormat:@"%@", info[@"community"] ? info[@"community"] : @""];
                                                                   if (info[@"sendable"] && ![info[@"sendable"] boolValue]) {
                                                                       NSString *title = [NSString stringWithFormat:@"%@(暂不支持配送)", tempString];
                                                                       [self.addressButton setTitle:title
                                                                                           forState:UIControlStateNormal];
                                                                   } else {
                                                                       [self.addressButton setTitle:tempString
                                                                                           forState:UIControlStateNormal];
                                                                   }
                                                               }
                                                           }];
    //    [selectAddressView reloadData];
    selectAddressView.removeViewCallBack = ^{
        _isShowAddressView = NO;
    };
    [GZBaseRequest addressListCallback:^(id responseObject, NSError *error) {
        if (ServerSuccess(responseObject)) {
            NSDictionary *dic = responseObject[@"data"];
            if ([dic isKindOfClass:[NSDictionary class]] && dic[@"addresslist"]) {
                selectAddressView.datas = [dic[@"addresslist"] mutableCopy];
                [YKSUserModel shareInstance].addressLists = selectAddressView.datas;
                if (!selectAddressView.datas) {
                    selectAddressView.datas = [NSMutableArray array];
                }
                [selectAddressView.datas insertObject:[self currentAddressInfo] atIndex:0];
                [selectAddressView reloadData];
            }
        }
    }];

}

#pragma mark - IBOutlets
- (IBAction)qrCodeAction:(UIButton *)sender {
    
}

- (IBAction)addressAction:(id)sender {
    //这里会显示地址,我们跟踪拿到选择的地址
    [self showAddressView];
}

#pragma mark - UITableViewdelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 50;
    } else if (indexPath.section == 1) {
        return 170;
    } else {
        return 84;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        UIView *aView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 20)];
        aView.backgroundColor = [UIColor clearColor];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, SCREEN_WIDTH - 30, 20)];
        if (section == 1) {
            label.text = @"常见症状解决方案";
        }
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor darkGrayColor];
        [aView addSubview:label];
        return aView;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return 26.0f;
    }
    return 0.0;
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return _datas.count < 1 ? 1 : _datas.count;
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"homeCell1" forIndexPath:indexPath];
        return cell;
    } else if (indexPath.section == 1) {
        NSDictionary *dic;
        if (_datas.count > indexPath.row) {
            dic = _datas[indexPath.row];
        }
        NSString *displaylayout = dic[@"displaylayout"];
        NSString *identifier = [NSString stringWithFormat:@"homeSpecial%@", displaylayout ? displaylayout : @"1"];
        YKSHomeListCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        if (dic) {
            [cell setHomeListInfo:dic];
        }
        cell.tapAction = ^(YKSSpecial *special){
            [self performSegueWithIdentifier:@"gotoSplecialList" sender:special];
        };
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"homeCell2" forIndexPath:indexPath];
        return cell;
    }
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2) {
        [YKSTools call:kServerPhone inView:self.view];
    }
}

#pragma mark - imagePlayViewDelegate
- (NSInteger)numberOfItems {
    return _imageURLStrings.count;
}

- (void)imagePlayerView:(ImagePlayerView *)imagePlayerView loadImageForImageView:(UIImageView *)imageView index:(NSInteger)index {
    [imageView sd_setImageWithURL:[NSURL URLWithString:_imageURLStrings[index][@"imgurl"]] placeholderImage:[UIImage imageNamed:@"defatul320"]];
}

- (void)imagePlayerView:(ImagePlayerView *)imagePlayerView didTapAtIndex:(NSInteger)index {
   
    if (![YKSUserModel isLogin]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"未登录"
                                                        message:@"请登录后查看"
                                                       delegate:nil
                                              cancelButtonTitle:@"随便看看"
                                              otherButtonTitles:@"登录", nil];
        [alert show];
        [alert callBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex == 0) {
                self.tabBarController.selectedIndex = 0;
            } else {
                [YKSTools login:self];
            }
        }];
        return ;
    } else {
        if (IS_NULL(_imageURLStrings[index][@"actiontarget"])) {
            return ;
        }
        [self performSegueWithIdentifier:@"gotoYKSWebViewController" sender:_imageURLStrings[index]];
    }
}

//#pragma mark - UITableViewDelegate

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *aa = segue.destinationViewController;
    aa.hidesBottomBarWhenPushed = YES;

    
    if ([segue.identifier isEqualToString:@"gotoSplecialList"]) {
        YKSSubSpecialListTableViewController *vc = segue.destinationViewController;
        vc.special = sender;
    } else if ([segue.identifier isEqualToString:@"gotoYKSQRCodeViewController"]) {
        YKSQRCodeViewController *vc = segue.destinationViewController;
        vc.qrUrlBlock = ^(NSString *stringValue){
            [self showProgress];
            [GZBaseRequest searchByKey:stringValue
                                  page:1
                              callback:^(id responseObject, NSError *error) {
                                  [self hideProgress];
                                  if (error) {
                                      [self showToastMessage:@"网络加载失败"];
                                      return ;
                                  }
                                  if (ServerSuccess(responseObject)) {
                                      NSLog(@"responseObject %@", responseObject);
                                      if ([responseObject[@"data"] count] == 0) {
                                          [self showToastMessage:@"没有相关的药品"];
                                      } else {
                                          UIStoryboard *mainBoard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
                                          YKSDrugListViewController *vc = [mainBoard instantiateViewControllerWithIdentifier:@"YKSDrugListViewController"];
                                          vc.datas = responseObject[@"data"][@"glist"];
                                          vc.hidesBottomBarWhenPushed = YES;
                                          vc.drugListType = YKSDrugListTypeSearchKey;
                                          vc.title = @"药品";
                                          [self.navigationController pushViewController:vc animated:YES];
                                      }
                                  } else {
                                      [self showToastMessage:responseObject[@"msg"]];
                                  }
                              }];
        };
    } else if ([segue.identifier isEqualToString:@"gotoYKSWebViewController"]) {
        YKSWebViewController *webVC = segue.destinationViewController;
        webVC.webURLString = sender[@"actiontarget"];
    }
    
}


@end
