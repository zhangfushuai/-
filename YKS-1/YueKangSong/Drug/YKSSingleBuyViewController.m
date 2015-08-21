//
//  YKSSingleBuyViewController.m
//  YueKangSong
//
//  Created by gongliang on 15/5/21.
//  Copyright (c) 2015年 YKS. All rights reserved.
//

#import "YKSSingleBuyViewController.h"
#import "YKSBuyCell.h"
#import "YKSConstants.h"
#import "YKSTools.h"
#import "GZBaseRequest.h"
#import "YKSAddressListViewController.h"
#import "YKSOrderConfirmView.h"
#import "YKSCloseButton.h"
#import "YKSCouponViewController.h"
#import "YKSUserModel.h"

@interface YKSSingleBuyViewController () <
UITableViewDataSource,
UITableViewDelegate,
UIImagePickerControllerDelegate,
UINavigationControllerDelegate,
UIActionSheetDelegate>
{
    NSTimer *theTimer;
}
//这个是表哥
@property (weak, nonatomic) IBOutlet UITableView *tableView;
//价格标签
@property (weak, nonatomic) IBOutlet UILabel *totalPriceLabel;
@property (assign, nonatomic) BOOL isPrescription; //是否是处方药
@property (assign, nonatomic) NSInteger buyCount;
@property (strong, nonatomic) NSDictionary *addressInfos;
//这里有一个优惠券信息
@property (strong, nonatomic) NSDictionary *couponInfo;
@property (strong, nonatomic) NSMutableArray *uploadImages;
//这个是更新图片
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;

//目前总价,需要从网络上获取,我们已经有了
@property (assign, nonatomic) CGFloat totalPrice;
@property (assign, nonatomic) CGFloat originTotalPrice;
@property (weak, nonatomic) IBOutlet UILabel *freightLabel;
@end

@implementation YKSSingleBuyViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _uploadImages = [NSMutableArray array];
    
    NSLog(@"_drugInfo = %@", _drugInfo);
    _isPrescription = [_drugInfo[@"gtag"] boolValue];
    _confirmButton.layer.masksToBounds = YES;
    _confirmButton.layer.cornerRadius = 5.0f;
    
    if (_isPrescription) {
        [_confirmButton setTitle:@"含处方药，请医师与我联系" forState:UIControlStateNormal];
        [_confirmButton setBackgroundImage:nil forState:UIControlStateNormal];
    }
    _buyCount = 1;
    _totalPrice = [_drugInfo[@"gprice"] floatValue] * _buyCount;
    _originTotalPrice = _totalPrice;
    [YKSTools showFreightPriceTextByTotalPrice:_totalPrice callback:^(NSAttributedString *totalPriceString, NSString *freightPriceString) {
        _totalPriceLabel.attributedText = totalPriceString;
        _freightLabel.text = freightPriceString;
    }];
    
    if ([YKSUserModel shareInstance].currentSelectAddress) {
        _addressInfos = [[YKSUserModel shareInstance] currentSelectAddress];
    }
    [self.tableView reloadData];
}

#pragma mark - custom
- (void)addImageAction:(YKSCloseButton *)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"取消"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"拍照", @"从相册选取", nil];
    [actionSheet showInView:self.view];
}

- (void)removeUpdaloadImage:(UIButton *)sender {
    YKSCloseButton *closeButton = (YKSCloseButton *)sender.superview;
    [_uploadImages removeObject:closeButton.imageView.image];
    [self.tableView reloadData];
}

#pragma mark - IBOutlets
- (IBAction)buyAction:(id)sender {
    if (!_addressInfos) {
        [self showToastMessage:@"请选择收货地址"];
        return ;
    }
    if (_isPrescription && _uploadImages.count == 0) {
        [self showToastMessage:@"处方药请上传医嘱说明"];
        return;
    }
  
    [self showProgress];
    //请求网络获取药品处方药非处方药详情
    [GZBaseRequest submitOrderContrast:@[@{@"gid": _drugInfo[@"gid"],
                                           @"gcount": @(_buyCount),
                                           @"gtag": _drugInfo[@"gtag"]}]
                              couponid:_couponInfo ? _couponInfo[@"id"] : nil
                             addressId:_addressInfos[@"id"]
                                images:_uploadImages
                              callback:^(id responseObject, NSError *error) {
                                  [self hideProgress];
                                  if (error) {
                                      [self showToastMessage:@"网络加载失败"];
                                      return ;
                                  }
                                  
                                  //这里都提交订单了,里面应该有价格提交吧
                                  if (ServerSuccess(responseObject)) {
                                      NSLog(@"订单处理中 %@", responseObject);
                                      [YKSOrderConfirmView showOrderToView:self.view.window orderId:responseObject[@"data"][@"orderid"] callback:^{
                                          
                                          [self dismissViewControllerAnimated:NO completion:nil];
                                          if (self.navigationController.presentingViewController) {
                                              if ([self.navigationController.presentingViewController isKindOfClass:[UITabBarController class]]) {
                                                  [(UITabBarController *)self.navigationController.presentingViewController setSelectedIndex:0];
                                              }
                                              [self.navigationController dismissViewControllerAnimated:NO completion:^{                                                  
                                              }];
                                          } else {
                                              self.tabBarController.selectedIndex = 0;
                                              [self.navigationController popToRootViewControllerAnimated:NO];
                                          }
                                      }];
                                  } else {
                                      [self showToastMessage:responseObject[@"msg"]];
                                  }
        
                              }];
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) { //拍照
        UIImagePickerController * imagePicker = [[UIImagePickerController alloc]init];
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:imagePicker animated:YES completion:nil];
    } else if (buttonIndex == 1) { //从相册选取
        UIImagePickerController * imagePicker = [[UIImagePickerController alloc]init];
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker
        didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    [_uploadImages addObject:image]; //imageView为自己定义的UIImageView
    [self.tableView reloadData];
    [picker dismissModalViewControllerAnimated:YES];
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 73.f;
    } else if (indexPath.section == 1) {
        return 148;
    } else if (indexPath.section == 2) {
        if (_isPrescription) {
            return 69;
        } else {
            return 44;
        }
    }
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //这里他慢了
    NSDictionary *currentAddr = [UIViewController selectedAddressUnArchiver];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        if (currentAddr) {
            if ([currentAddr[@"sendable"] integerValue] == 1) {
                return ;
            }
        }
        //[self performSegueWithIdentifier:@"gotoYKSAddressListViewController" sender:nil];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//    if (indexPath.section == 0) {
//        if ([[YKSUserModel shareInstance] currentSelectAddress]) {
//            if ([[YKSUserModel shareInstance].currentSelectAddress[@"sendable"] integerValue] == 1) {
//                return ;
//            }
//        }
//        [self performSegueWithIdentifier:@"gotoYKSAddressListViewController" sender:nil];
//    }
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _isPrescription ? 4 : 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
     NSDictionary *currentAddr = [UIViewController selectedAddressUnArchiver];
    
    if (indexPath.section == 0) {
        YKSBuyAddressCell *addressCell = [tableView dequeueReusableCellWithIdentifier:@"BuyAddressCell" forIndexPath:indexPath];
        
        if (currentAddr) {
            if ([currentAddr[@"sendable"] integerValue] == 1) {
                addressCell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        NSDictionary *dic = currentAddr;
        
//        if ([[YKSUserModel shareInstance] currentSelectAddress]) {
//            if ([[YKSUserModel shareInstance].currentSelectAddress[@"sendable"] integerValue] == 1) {
//                addressCell.accessoryType = UITableViewCellAccessoryNone;
//            }
//        }
//        NSDictionary *dic = _addressInfos;
        if (!dic) {
            addressCell.nameLabel.text = @"点击进入选择收货地址";
            addressCell.phoneLabel.text = @"";
            addressCell.addressLabel.text = @"";
        } else {
            addressCell.nameLabel.text = DefuseNUllString(dic[@"express_username"]);
            addressCell.phoneLabel.text = DefuseNUllString(dic[@"express_mobilephone"]);
            addressCell.addressLabel.text = [NSString stringWithFormat:@"%@%@", dic[@"community"], dic[@"express_detail_address"]];
        }
        return addressCell;
    } else if (indexPath.section == 1) {
        YKSBuyDrugCell *drugCell = [tableView dequeueReusableCellWithIdentifier:@"BuyDrugCell" forIndexPath:indexPath];
        [drugCell.logoImageView sd_setImageWithURL:[NSURL URLWithString:_drugInfo[@"glogo"]] placeholderImage:[UIImage imageNamed:@"default160"]];
        drugCell.recipeFlagView.hidden = ![_drugInfo[@"gtag"] boolValue];
        drugCell.titleLabel.text = _drugInfo[@"gtitle"];
        drugCell.priceLabel.attributedText = [YKSTools priceString:[_drugInfo[@"gprice"] floatValue]];
        drugCell.countLabel.text = [[NSString alloc] initWithFormat:@"x%@", @(_buyCount)];
        drugCell.centerCountLabel.text = [[NSString alloc] initWithFormat:@"%@", @(_buyCount)];
        [drugCell.addButton addTarget:self action:@selector(addCount:) forControlEvents:UIControlEventTouchUpInside];
        [drugCell.minusButton addTarget:self action:@selector(minusCount:) forControlEvents:UIControlEventTouchUpInside];
        return drugCell;
    } else if (indexPath.section == 2) {
        if (_isPrescription) {
            YKSBuyLabelCell *labelCell = [tableView dequeueReusableCellWithIdentifier:@"BuyLabelCell" forIndexPath:indexPath];
            [labelCell.rightButton addTarget:self
                                    action:@selector(addImageAction:)
                          forControlEvents:UIControlEventTouchUpInside];
            [labelCell.leftButton.closeButton addTarget:self
                                                  action:@selector(removeUpdaloadImage:)
                                        forControlEvents:UIControlEventTouchUpInside];
            [labelCell.centerButton.closeButton addTarget:self
                                                  action:@selector(removeUpdaloadImage:)
                                        forControlEvents:UIControlEventTouchUpInside];
            [labelCell.rightButton.closeButton addTarget:self
                                                  action:@selector(removeUpdaloadImage:)
                                        forControlEvents:UIControlEventTouchUpInside];
            
            labelCell.centerButton.hidden = NO;
            labelCell.leftButton.hidden = NO;
            labelCell.rightButton.closeButton.hidden = NO;
            if (_uploadImages.count > 0) {
                [labelCell.centerButton setImage:[_uploadImages firstObject] forState:UIControlStateNormal];
                if (_uploadImages.count > 1) {
                    [labelCell.leftButton setImage:_uploadImages[1] forState:UIControlStateNormal];
                } else {
                    labelCell.leftButton.hidden = YES;
                }
                if (_uploadImages.count > 2) {
                    [labelCell.rightButton setImage:_uploadImages[2] forState:UIControlStateNormal];
                } else {
                    labelCell.rightButton.closeButton.hidden = YES;
                    [labelCell.rightButton setImage:[UIImage imageNamed:@"add_image"] forState:UIControlStateNormal];
                }
            } else {
                labelCell.centerButton.hidden = YES;
                labelCell.leftButton.hidden = YES;
                labelCell.rightButton.closeButton.hidden = YES;
                [labelCell.rightButton setImage:[UIImage imageNamed:@"add_image"] forState:UIControlStateNormal];
            }
            return labelCell;
        } else {
            YKSBuyCouponCell *couponCell = [tableView dequeueReusableCellWithIdentifier:@"BuyCouponCell" forIndexPath:indexPath];
            if (_couponInfo) {
                couponCell.detailTextLabel.text = [NSString stringWithFormat:@"%0.2f优惠劵", [_couponInfo[@"faceprice"] floatValue]];
            }
            return couponCell;
        }
    } else  {
        YKSBuyCouponCell *couponCell = [tableView dequeueReusableCellWithIdentifier:@"BuyCouponCell" forIndexPath:indexPath];
        if (_couponInfo) {
            couponCell.detailTextLabel.text = [NSString stringWithFormat:@"%0.2f优惠劵", [_couponInfo[@"faceprice"] floatValue]];
        }
        return couponCell;
    }
}

#pragma mark - UITableView Action
- (void)addCount:(UIButton *)sender {
    CGPoint point = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    YKSBuyDrugCell *drugCell = (YKSBuyDrugCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    _buyCount++;
    
    if (_drugInfo[@"repertory"] && _buyCount > [_drugInfo[@"repertory"] integerValue]) {
        [YKSTools showToastMessage:@"已超出最大库存" inView:[[[UIApplication sharedApplication] delegate] window]];
        return;
    }
    [self showPirce:drugCell];
}

- (void)minusCount:(UIButton *)sender {
    CGPoint point = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    YKSBuyDrugCell *drugCell = (YKSBuyDrugCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    _buyCount--;
    if (_buyCount == 0) {
        _buyCount = 1;
    }
    [self showPirce:drugCell];
}

- (void)showPirce:(YKSBuyDrugCell *)drugCell {
    drugCell.countLabel.text = [[NSString alloc] initWithFormat:@"x%@", @(_buyCount)];
    drugCell.centerCountLabel.text = [[NSString alloc] initWithFormat:@"%@", @(_buyCount)];
    _totalPrice = [_drugInfo[@"gprice"] floatValue] * _buyCount;
    [YKSTools showFreightPriceTextByTotalPrice:_totalPrice
                                      callback:^(NSAttributedString *totalPriceString, NSString *freightPriceString) {
                                          _totalPriceLabel.attributedText = totalPriceString;
                                          _freightLabel.text = freightPriceString;
    }];
}

#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"gotoYKSAddressListViewController"]) {
        YKSAddressListViewController *vc = segue.destinationViewController;
        vc.callback = ^(NSDictionary *info){
            _addressInfos = info;
            [self.tableView reloadData];
        };
        
        //优惠券
    } else if ([segue.identifier isEqualToString:@"gotoYKSCouponViewController"]) {
        YKSCouponViewController *vc = segue.destinationViewController;
        vc.totalPirce = _originTotalPrice;
//        if (!_couponInfo) {
//            vc.totalPirce = _totalPrice;
//        } else {
//            vc.totalPirce = _totalPrice + [_couponInfo[@"faceprice"] floatValue];
//        }
        vc.callback = ^(NSDictionary *info) {
            _couponInfo = info;
            if (_couponInfo && _couponInfo[@"faceprice"]) {
                _totalPrice = _originTotalPrice - [self.couponInfo[@"faceprice"] floatValue];
                [YKSTools showFreightPriceTextByTotalPrice:_totalPrice callback:^(NSAttributedString *totalPriceString, NSString *freightPriceString) {
                    _totalPriceLabel.attributedText = totalPriceString;
                    _freightLabel.text = freightPriceString;
                }];
            }
            [self.tableView reloadData];
        };
    }
}


@end
