//
//  YKSDrugListViewController.m
//  YueKangSong
//
//  Created by gongliang on 15/5/14.
//  Copyright (c) 2015年 YKS. All rights reserved.
//

#import "YKSDrugListViewController.h"
#import "GZBaseRequest.h"
#import "YKSDrugListCell.h"
#import <MJRefresh/MJRefresh.h>
#import "YKSUIConstants.h"
#import "YKSDrugDetailViewController.h"
#import "YKSUserModel.h"
#import "YKSAddressListViewController.h"
#import "YKSAddAddressVC.h"

@interface YKSDrugListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *totalPriceLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomHeight;

@property (assign, nonatomic) CGFloat totalPrice;
@property (weak, nonatomic) IBOutlet UILabel *freightLabel;
@property (weak, nonatomic) IBOutlet UIButton *yiJianAddToChat;

@end

@implementation YKSDrugListViewController

- (void)awakeFromNib {
    _drugListType = YKSDrugListTypeSpecail;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (_drugListType != YKSDrugListTypeSpecail) {
        _bottomHeight.constant = 0.0f;
    }
    // Do any additional setup after loading the view.
    self.tableView.tableFooterView = [UIView new];
    [self requestSubSpecialList];
}

#pragma mark - custom
- (void)requestSubSpecialList {
    if (!self.specialId) {
        return ;
    }
    [self showProgress];
    if (_drugListType == YKSDrugListTypeSpecail) {
        [GZBaseRequest subSpecialDetailBy:self.specialId
                                 callback:^(id responseObject, NSError *error) {
                                     [self handleResult:responseObject error:error];
                                 }];
    } else if (_drugListType == YKSDrugListTypeCategory) {
        [GZBaseRequest drugListByCategoryId:self.specialId
                                   callback:^(id responseObject, NSError *error) {
                                       [self handleResult:responseObject error:error];
                                   }];
    }
}

- (void)handleResult:(id)responseObject error:(NSError *)error {
    [self hideProgress];
    if (error) {
        [self showToastMessage:@"网络加载失败"];
//        //一键加入购物车不能用
//        if (self.datas.count==0) {
//            self.yiJianAddToChat.enabled = NO;
//        }else{
//            self.yiJianAddToChat.enabled = YES;
//        }
        
        
        return ;
    }
    if (ServerSuccess(responseObject)) {
        NSLog(@"responseObject = %@", responseObject);
        NSDictionary *dic = responseObject[@"data"];
        if ([dic isKindOfClass:[NSDictionary class]] && dic[@"glist"]) {
            _datas = responseObject[@"data"][@"glist"];
//            //一键加入购物车不能用
//            if (self.datas.count==0) {
//                self.yiJianAddToChat.enabled = NO;
//            }else{
//                self.yiJianAddToChat.enabled = YES;
//            }
            
            
            NSArray *totalPrices = [_datas valueForKeyPath:@"gprice"];
            if (totalPrices) {
                _totalPrice = [[totalPrices valueForKeyPath:@"@sum.floatValue"] floatValue];
            }
        }
        [self updateUI];
    } else {
        [self showToastMessage:responseObject[@"msg"]];
    }
}

- (void)updateUI {
    [self.tableView reloadData];
    _totalPriceLabel.attributedText = [YKSTools priceString:_totalPrice];
    [YKSTools showFreightPriceTextByTotalPrice:_totalPrice
                                      callback:^(NSAttributedString *totalPriceString,  NSString *freightPriceString) {
                                          _totalPriceLabel.attributedText = totalPriceString;
                                          _freightLabel.text = freightPriceString;
                                      }];
}




////////////////////
- (void)jumpAddCard
{
    //这里已经加载网络.拉倒当前地址了
    NSDictionary *currentAddr = [UIViewController selectedAddressUnArchiver];
    
    //显示判断登陆没有,请登陆
    if (![YKSUserModel isLogin]) {
        [self showToastMessage:@"请登陆"];
        [YKSTools login:self];
        return;
    }
    
    
    //如果列表为空,什么地址都没有,去添加地址控制器
    if (!currentAddr[@"express_mobilephone"]) {
        //这里要默认点击那个地址button所以也要加记录
        //默认让点击这个地址列表
        [UIViewController selectedAddressButtonArchiver:1];
        self.tabBarController.selectedIndex = 0;
        [self.navigationController popToRootViewControllerAnimated:NO];
        return;
    }
    
    //不支持配送
    if ([currentAddr[@"sendable"] integerValue] == 0) {
        [self showToastMessage:@"暂不支持配送您选择的区域，我们会尽快开通"];
        return;
    }
    
    //号码不为空,能送达
    if (currentAddr[@"express_mobilephone"] && ([currentAddr[@"sendable"] integerValue] != 0)) {
        
        if (![YKSUserModel shareInstance].addressLists) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                                 bundle:[NSBundle mainBundle]];
            YKSAddAddressVC *vc = [storyboard instantiateViewControllerWithIdentifier:@"YKSAddAddressVC"];
            vc.callback = ^{
                [self showProgress];
                [GZBaseRequest addressListCallback:^(id responseObject, NSError *error) {
                    [self hideProgress];
                    if (error) {
                        [self showToastMessage:@"网络加载失败"];
                        return ;
                    }
                    if (ServerSuccess(responseObject)) {
                        NSLog(@"responseObject = %@", responseObject);
                        NSDictionary *dic = responseObject[@"data"];
                        if ([dic isKindOfClass:[NSDictionary class]] && dic[@"addresslist"]) {
                            [YKSUserModel shareInstance].addressLists = _datas;
                        }
                    } else {
                        [self showToastMessage:responseObject[@"msg"]];
                    }
                }];
            };
            [self.navigationController pushViewController:vc animated:YES];
            return ;
        }
        
        if (![YKSUserModel shareInstance].currentSelectAddress) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                                 bundle:[NSBundle mainBundle]];
            YKSAddressListViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"YKSAddressListViewController"];
            vc.callback = ^(NSDictionary *info){
                [YKSUserModel shareInstance].currentSelectAddress = info;
            };
            [self.navigationController pushViewController:vc animated:YES];
            return ;
        }
        
        
        [self showProgress];
        
        __block NSMutableArray *gcontrasts = [NSMutableArray new];
        __block NSMutableArray *gids = [NSMutableArray new];
        [_datas enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *dic = @{@"gid": obj[@"gid"],
                                  @"gcount": @(1),
                                  @"gtag": obj[@"gtag"],
                                  @"banners": obj[@"banners"],
                                  @"gtitle": obj[@"gtitle"],
                                  @"gprice": obj[@"gprice"],
                                  @"gpricemart": obj[@"gpricemart"],
                                  @"glogo": obj[@"glogo"],
                                  @"gdec": obj[@"gdec"],
                                  @"purchase": obj[@"purchase"],
                                  @"gstandard": obj[@"gstandard"],
                                  @"vendor": obj[@"vendor"],
                                  @"iscollect": obj[@"iscollect"],
                                  @"gmanual": obj[@"gmanual"]};
            [gcontrasts addObject:dic];
            [gids addObject:obj[@"gid"]];
        }];
        
        [GZBaseRequest addToShoppingcartParams:gcontrasts
                                          gids:[gids componentsJoinedByString:@","]
                                      callback:^(id responseObject, NSError *error) {
                                          [self hideProgress];
                                          if (error) {
                                              [self showToastMessage:@"网络加载失败"];
                                              return ;
                                          }
                                          if (ServerSuccess(responseObject)) {
                                              [self showToastMessage:@"加入购物车成功"];
                                              [self performSegueWithIdentifier:@"gotoShoppingCart" sender:nil];
                                          } else {
                                              [self showToastMessage:responseObject[@"msg"]];
                                          }
                                      }];
        
    }
}


#pragma mark - IBOutlets
// "一键加入购物车"
- (IBAction)addShoppingCartAction:(id)sender {
    //    if (![YKSUserModel isLogin]) {
    //        [YKSTools login:self];
    //        return;
    //    }
    //如果没有药品，提示用户8月12新增
    if (self.datas.count==0) {
        [self showToastMessage:@"没有商品可以加入购物车！！！"];
        return;
    }
    
    
    
    
    [self jumpAddCard];
}




#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YKSDrugListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"drugList" forIndexPath:indexPath];
    cell.drugInfo = self.datas[indexPath.row];
    return cell;
}

#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"drugDetail"]) {
        YKSDrugDetailViewController *vc = segue.destinationViewController;
        YKSDrugListCell *cell = (YKSDrugListCell *)sender;
        vc.drugInfo = cell.drugInfo;
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end
