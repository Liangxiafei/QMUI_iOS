//
//  QMUINavigationController.m
//  qmui
//
//  Created by QMUI Team on 14-6-24.
//  Copyright (c) 2014年 QMUI Team. All rights reserved.
//

#import "QMUINavigationController.h"
#import "QMUICore.h"
#import "QMUINavigationTitleView.h"
#import "QMUICommonViewController.h"
#import "UIViewController+QMUI.h"
#import "UINavigationController+QMUI.h"
#import "QMUILog.h"
#import "QMUIMultipleDelegates.h"

@implementation UIViewController (QMUINavigationController)

- (BOOL)qmui_navigationControllerPoppingInteracted {
    return self.qmui_poppingByInteractivePopGestureRecognizer || self.qmui_willAppearByInteractivePopGestureRecognizer;
}

static char kAssociatedObjectKey_navigationControllerPopGestureRecognizerChanging;
- (void)setQmui_navigationControllerPopGestureRecognizerChanging:(BOOL)qmui_navigationControllerPopGestureRecognizerChanging {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_navigationControllerPopGestureRecognizerChanging, @(qmui_navigationControllerPopGestureRecognizerChanging), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)qmui_navigationControllerPopGestureRecognizerChanging {
    return [((NSNumber *)objc_getAssociatedObject(self, &kAssociatedObjectKey_navigationControllerPopGestureRecognizerChanging)) boolValue];
}

static char kAssociatedObjectKey_poppingByInteractivePopGestureRecognizer;
- (void)setQmui_poppingByInteractivePopGestureRecognizer:(BOOL)qmui_poppingByInteractivePopGestureRecognizer {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_poppingByInteractivePopGestureRecognizer, @(qmui_poppingByInteractivePopGestureRecognizer), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)qmui_poppingByInteractivePopGestureRecognizer {
    return [((NSNumber *)objc_getAssociatedObject(self, &kAssociatedObjectKey_poppingByInteractivePopGestureRecognizer)) boolValue];
}

static char kAssociatedObjectKey_willAppearByInteractivePopGestureRecognizer;
- (void)setQmui_willAppearByInteractivePopGestureRecognizer:(BOOL)qmui_willAppearByInteractivePopGestureRecognizer {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_willAppearByInteractivePopGestureRecognizer, @(qmui_willAppearByInteractivePopGestureRecognizer), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)qmui_willAppearByInteractivePopGestureRecognizer {
    return [((NSNumber *)objc_getAssociatedObject(self, &kAssociatedObjectKey_willAppearByInteractivePopGestureRecognizer)) boolValue];
}

@end


NSString *const UIViewControllerIsViewWillAppearPropertyKey = @"qmuiNav_isViewWillAppear";

@interface UIViewController (QMUINavigationControllerTransition)

@property(nonatomic, assign) BOOL qmuiNav_isViewWillAppear;

@end

@implementation UIViewController (QMUINavigationControllerTransition)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        ExchangeImplementations(class, @selector(viewWillAppear:), @selector(qmuiNav_viewWillAppear:));
        ExchangeImplementations(class, @selector(viewDidAppear:), @selector(qmuiNav_viewDidAppear:));
        ExchangeImplementations(class, @selector(viewDidDisappear:), @selector(qmuiNav_viewDidDisappear:));
    });
}

- (void)qmuiNav_viewWillAppear:(BOOL)animated {
    [self qmuiNav_viewWillAppear:animated];
    self.qmuiNav_isViewWillAppear = YES;
}

- (void)qmuiNav_viewDidAppear:(BOOL)animated {
    [self qmuiNav_viewDidAppear:animated];
    self.qmui_poppingByInteractivePopGestureRecognizer = NO;
    self.qmui_willAppearByInteractivePopGestureRecognizer = NO;
}

- (void)qmuiNav_viewDidDisappear:(BOOL)animated {
    [self qmuiNav_viewDidDisappear:animated];
    self.qmuiNav_isViewWillAppear = NO;
    self.qmui_poppingByInteractivePopGestureRecognizer = NO;
    self.qmui_willAppearByInteractivePopGestureRecognizer = NO;
}

static char kAssociatedObjectKey_qmuiNavIsViewWillAppear;
- (void)setQmuiNav_isViewWillAppear:(BOOL)qmuiNav_isViewWillAppear {
    [self willChangeValueForKey:UIViewControllerIsViewWillAppearPropertyKey];
    objc_setAssociatedObject(self, &kAssociatedObjectKey_qmuiNavIsViewWillAppear, @(qmuiNav_isViewWillAppear), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:UIViewControllerIsViewWillAppearPropertyKey];
}

- (BOOL)qmuiNav_isViewWillAppear {
    return [((NSNumber *)objc_getAssociatedObject(self, &kAssociatedObjectKey_qmuiNavIsViewWillAppear)) boolValue];
}

@end

@interface _QMUINavigationControllerDelegator : NSObject <QMUINavigationControllerDelegate>

@property(nonatomic, weak) QMUINavigationController *navigationController;
@end

@interface QMUINavigationController () <UIGestureRecognizerDelegate>

@property(nonatomic, strong) _QMUINavigationControllerDelegator *delegator;

/// 记录当前是否正在 push/pop 界面的动画过程，如果动画尚未结束，不应该继续 push/pop 其他界面。
/// 在 getter 方法里会根据配置表开关 PreventConcurrentNavigationControllerTransitions 的值来控制这个属性是否生效。
@property(nonatomic, assign) BOOL isViewControllerTransiting;

/// 即将要被pop的controller
@property(nonatomic, weak) UIViewController *viewControllerPopping;

@end

@implementation QMUINavigationController

#pragma mark - 生命周期函数 && 基类方法重写

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self didInitialized];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self didInitialized];
    }
    return self;
}

- (void)didInitialized {
    
    self.qmui_multipleDelegatesEnabled = YES;
    self.delegator = [[_QMUINavigationControllerDelegator alloc] init];
    self.delegator.navigationController = self;
    self.delegate = self.delegator;
    
    // UIView.tintColor 并不支持 UIAppearance 协议，所以不能通过 appearance 来设置，只能在实例里设置
    UIColor *tintColor = NavBarTintColor;
    if (tintColor) {
        self.navigationBar.tintColor = tintColor;
    }
    
    tintColor = ToolBarTintColor;
    if (tintColor) {
        self.toolbar.tintColor = tintColor;
    }
}

- (void)dealloc {
    self.delegate = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 手势允许多次addTarget
    [self.interactivePopGestureRecognizer addTarget:self action:@selector(handleInteractivePopGestureRecognizer:)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self willShowViewController:self.topViewController animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self didShowViewController:self.topViewController animated:animated];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    // 从横屏界面pop 到竖屏界面，系统会调用两次 popViewController，如果这里加这个 if 判断，会误拦第二次 pop，导致错误
//    if (self.isViewControllerTransiting) {
//        NSAssert(NO, @"isViewControllerTransiting = YES, %s, self.viewControllers = %@", __func__, self.viewControllers);
//        return nil;
//    }
    
    if (self.viewControllers.count < 2) {
        // 只剩 1 个 viewController 或者不存在 viewController 时，调用 popViewControllerAnimated: 后不会有任何变化，所以不需要触发 willPop / didPop
        return [super popViewControllerAnimated:animated];
    }
    
    if (animated) {
        self.isViewControllerTransiting = YES;
    }
    
    UIViewController *viewController = [self topViewController];
    self.viewControllerPopping = viewController;
    if ([viewController respondsToSelector:@selector(willPopInNavigationControllerWithAnimated:)]) {
        [((UIViewController<QMUINavigationControllerTransitionDelegate> *)viewController) willPopInNavigationControllerWithAnimated:animated];
    }
    viewController = [super popViewControllerAnimated:animated];
    if ([viewController respondsToSelector:@selector(didPopInNavigationControllerWithAnimated:)]) {
        [((UIViewController<QMUINavigationControllerTransitionDelegate> *)viewController) didPopInNavigationControllerWithAnimated:animated];
    }
    return viewController;
}

- (NSArray<UIViewController *> *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    // 从横屏界面pop 到竖屏界面，系统会调用两次 popViewController，如果这里加这个 if 判断，会误拦第二次 pop，导致错误
//    if (self.isViewControllerTransiting) {
//        NSAssert(NO, @"isViewControllerTransiting = YES, %s, self.viewControllers = %@", __func__, self.viewControllers);
//        return nil;
//    }
    
    if (!viewController || self.topViewController == viewController) {
        // 当要被 pop 到的 viewController 已经处于最顶层时，调用 super 默认也是什么都不做，所以直接 return 掉
        return [super popToViewController:viewController animated:animated];
    }
    
    if (animated) {
        self.isViewControllerTransiting = YES;
    }
    
    self.viewControllerPopping = self.topViewController;
    
    // will pop
    for (NSInteger i = self.viewControllers.count - 1; i > 0; i--) {
        UIViewController *viewControllerPopping = self.viewControllers[i];
        if (viewControllerPopping == viewController) {
            break;
        }
        
        if ([viewControllerPopping respondsToSelector:@selector(willPopInNavigationControllerWithAnimated:)]) {
            BOOL animatedArgument = i == self.viewControllers.count - 1 ? animated : NO;// 只有当前可视的那个 viewController 的 animated 是跟随参数走的，其他 viewController 由于不可视，不管参数的值为多少，都认为是无动画地 pop
            [((UIViewController<QMUINavigationControllerTransitionDelegate> *)viewControllerPopping) willPopInNavigationControllerWithAnimated:animatedArgument];
        }
    }
    
    NSArray<UIViewController *> *poppedViewControllers = [super popToViewController:viewController animated:animated];
    
    // did pop
    for (NSInteger i = poppedViewControllers.count - 1; i >= 0; i--) {
        UIViewController *viewControllerPopped = poppedViewControllers[i];
        if ([viewControllerPopped respondsToSelector:@selector(didPopInNavigationControllerWithAnimated:)]) {
            BOOL animatedArgument = i == poppedViewControllers.count - 1 ? animated : NO;// 只有当前可视的那个 viewController 的 animated 是跟随参数走的，其他 viewController 由于不可视，不管参数的值为多少，都认为是无动画地 pop
            [((UIViewController<QMUINavigationControllerTransitionDelegate> *)viewControllerPopped) didPopInNavigationControllerWithAnimated:animatedArgument];
        }
    }
    
    return poppedViewControllers;
}

- (NSArray<UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated {
    // 从横屏界面pop 到竖屏界面，系统会调用两次 popViewController，如果这里加这个 if 判断，会误拦第二次 pop，导致错误
//    if (self.isViewControllerTransiting) {
//        NSAssert(NO, @"isViewControllerTransiting = YES, %s, self.viewControllers = %@", __func__, self.viewControllers);
//        return nil;
//    }
    
    // 在配合 tabBarItem 使用的情况下，快速重复点击相同 item 可能会重复调用 popToRootViewControllerAnimated:，而此时其实已经处于 rootViewController 了，就没必要继续走后续的流程，否则一些变量会得不到重置。
    if (self.topViewController == self.qmui_rootViewController) {
        return nil;
    }
    
    if (animated) {
        self.isViewControllerTransiting = YES;
    }
    
    self.viewControllerPopping = self.topViewController;
    
    // will pop
    for (NSInteger i = self.viewControllers.count - 1; i > 0; i--) {
        UIViewController *viewControllerPopping = self.viewControllers[i];
        if ([viewControllerPopping respondsToSelector:@selector(willPopInNavigationControllerWithAnimated:)]) {
            BOOL animatedArgument = i == self.viewControllers.count - 1 ? animated : NO;// 只有当前可视的那个 viewController 的 animated 是跟随参数走的，其他 viewController 由于不可视，不管参数的值为多少，都认为是无动画地 pop
            [((UIViewController<QMUINavigationControllerTransitionDelegate> *)viewControllerPopping) willPopInNavigationControllerWithAnimated:animatedArgument];
        }
    }
    
    NSArray<UIViewController *> * poppedViewControllers = [super popToRootViewControllerAnimated:animated];
    
    // did pop
    for (NSInteger i = poppedViewControllers.count - 1; i >= 0; i--) {
        UIViewController *viewControllerPopped = poppedViewControllers[i];
        if ([viewControllerPopped respondsToSelector:@selector(didPopInNavigationControllerWithAnimated:)]) {
            BOOL animatedArgument = i == poppedViewControllers.count - 1 ? animated : NO;// 只有当前可视的那个 viewController 的 animated 是跟随参数走的，其他 viewController 由于不可视，不管参数的值为多少，都认为是无动画地 pop
            [((UIViewController<QMUINavigationControllerTransitionDelegate> *)viewControllerPopped) didPopInNavigationControllerWithAnimated:animatedArgument];
        }
    }
    return poppedViewControllers;
}

- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated {
    UIViewController *topViewController = self.topViewController;
    
    // will pop
    NSMutableArray<UIViewController *> *viewControllersPopping = self.viewControllers.mutableCopy;
    [viewControllersPopping removeObjectsInArray:viewControllers];
    [viewControllersPopping enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(willPopInNavigationControllerWithAnimated:)]) {
            BOOL animatedArgument = obj == topViewController ? animated : NO;// 只有当前可视的那个 viewController 的 animated 是跟随参数走的，其他 viewController 由于不可视，不管参数的值为多少，都认为是无动画地 pop
            [((UIViewController<QMUINavigationControllerTransitionDelegate> *)obj) willPopInNavigationControllerWithAnimated:animatedArgument];
        }
    }];
    
    [super setViewControllers:viewControllers animated:animated];
    
    // did pop
    [viewControllersPopping enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(didPopInNavigationControllerWithAnimated:)]) {
            BOOL animatedArgument = obj == topViewController ? animated : NO;// 只有当前可视的那个 viewController 的 animated 是跟随参数走的，其他 viewController 由于不可视，不管参数的值为多少，都认为是无动画地 pop
            [((UIViewController<QMUINavigationControllerTransitionDelegate> *)obj) didPopInNavigationControllerWithAnimated:animatedArgument];
        }
    }];
    
    // 操作前后如果 topViewController 没发生变化，则为它调用一个特殊的时机
    if (topViewController == viewControllers.lastObject) {
        if ([topViewController respondsToSelector:@selector(viewControllerKeepingAppearWhenSetViewControllersWithAnimated:)]) {
            [((UIViewController<QMUINavigationControllerTransitionDelegate> *)topViewController) viewControllerKeepingAppearWhenSetViewControllersWithAnimated:animated];
        }
    }
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.isViewControllerTransiting || !viewController) {
        QMUILog(NSStringFromClass(self.class), @"%@, 上一次界面切换的动画尚未结束就试图进行新的 push 操作，为了避免产生 bug，拦截了这次 push。\n%s, isViewControllerTransiting = %@, viewController = %@, self.viewControllers = %@", NSStringFromClass(self.class),  __func__, StringFromBOOL(self.isViewControllerTransiting), viewController, self.viewControllers);
        return;
    }
    
    // 增加一个 presentedViewController 作为判断条件是因为这个 issue：https://github.com/QMUI/QMUI_iOS/issues/261
    if (!self.presentedViewController && animated) {
        self.isViewControllerTransiting = YES;
    }
    
    if (self.presentedViewController) {
        QMUILog(NSStringFromClass(self.class), @"push 的时候 navigationController 存在一个盖在上面的 presentedViewController，可能导致一些 UINavigationControllerDelegate 不会被调用");
    }
    
    UIViewController *currentViewController = self.topViewController;
    if (currentViewController) {
        if (!NeedsBackBarButtonItemTitle) {
            // 会自动从 UIBarButtonItem.title 取值作为下一个界面的返回按钮的文字
            currentViewController.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:NULL];
        } else {
            UIViewController<QMUINavigationControllerAppearanceDelegate> *vc = (UIViewController<QMUINavigationControllerAppearanceDelegate> *)viewController;
            if ([vc respondsToSelector:@selector(backBarButtonItemTitleWithPreviousViewController:)]) {
                NSString *title = [vc backBarButtonItemTitleWithPreviousViewController:currentViewController];
                currentViewController.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:nil action:NULL];
            }
        }
    }
    [super pushViewController:viewController animated:animated];
}

// 重写这个方法才能让 viewControllers 对 statusBar 的控制生效
- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;
}

#pragma mark - 自定义方法

- (BOOL)isViewControllerTransiting {
    // 如果配置表里这个开关关闭，则为了使 isViewControllerTransiting 功能失效，强制返回 NO
    if (!PreventConcurrentNavigationControllerTransitions) {
        return NO;
    }
    return _isViewControllerTransiting;
}

// 接管系统手势返回的回调
- (void)handleInteractivePopGestureRecognizer:(UIScreenEdgePanGestureRecognizer *)gestureRecognizer {
    UIGestureRecognizerState state = gestureRecognizer.state;
    if (state == UIGestureRecognizerStateBegan) {
        [self.viewControllerPopping addObserver:self forKeyPath:UIViewControllerIsViewWillAppearPropertyKey options:NSKeyValueObservingOptionNew context:nil];
    }
    
    UIViewController *viewControllerWillDisappear = self.viewControllerPopping;
    UIViewController *viewControllerWillAppear = self.topViewController;
    
    viewControllerWillDisappear.qmui_poppingByInteractivePopGestureRecognizer = YES;
    viewControllerWillDisappear.qmui_willAppearByInteractivePopGestureRecognizer = NO;
    
    viewControllerWillDisappear.qmui_poppingByInteractivePopGestureRecognizer = NO;
    viewControllerWillAppear.qmui_willAppearByInteractivePopGestureRecognizer = YES;
    
    if (state == UIGestureRecognizerStateChanged) {
        viewControllerWillDisappear.qmui_navigationControllerPopGestureRecognizerChanging = YES;
        viewControllerWillAppear.qmui_navigationControllerPopGestureRecognizerChanging = YES;
    } else {
        viewControllerWillDisappear.qmui_navigationControllerPopGestureRecognizerChanging = NO;
        viewControllerWillAppear.qmui_navigationControllerPopGestureRecognizerChanging = NO;
    }
    
    if (state == UIGestureRecognizerStateEnded) {
        if (CGRectGetMinX(self.topViewController.view.superview.frame) < 0) {
            // by molice:只是碰巧发现如果是手势返回取消时，不管在哪个位置取消，self.topViewController.view.superview.frame.orgin.x必定是-124，所以用这个<0的条件来判断
            QMUILog(NSStringFromClass(self.class), @"手势返回放弃了");
            viewControllerWillDisappear = self.topViewController;
            viewControllerWillAppear = self.viewControllerPopping;
        } else {
            QMUILog(NSStringFromClass(self.class), @"执行手势返回");
        }
    }
    
    if ([viewControllerWillDisappear respondsToSelector:@selector(navigationController:poppingByInteractiveGestureRecognizer:viewControllerWillDisappear:viewControllerWillAppear:)]) {
        [((UIViewController<QMUINavigationControllerTransitionDelegate> *)viewControllerWillDisappear) navigationController:self poppingByInteractiveGestureRecognizer:gestureRecognizer viewControllerWillDisappear:viewControllerWillDisappear viewControllerWillAppear:viewControllerWillAppear];
    }
    
    if ([viewControllerWillAppear respondsToSelector:@selector(navigationController:poppingByInteractiveGestureRecognizer:viewControllerWillDisappear:viewControllerWillAppear:)]) {
        [((UIViewController<QMUINavigationControllerTransitionDelegate> *)viewControllerWillAppear) navigationController:self poppingByInteractiveGestureRecognizer:gestureRecognizer viewControllerWillDisappear:viewControllerWillDisappear viewControllerWillAppear:viewControllerWillAppear];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:UIViewControllerIsViewWillAppearPropertyKey]) {
        [self.viewControllerPopping removeObserver:self forKeyPath:UIViewControllerIsViewWillAppearPropertyKey];
        NSNumber *newValue = change[NSKeyValueChangeNewKey];
        if (newValue.boolValue) {
            [self.delegator navigationController:self willShowViewController:self.viewControllerPopping animated:YES];
            self.viewControllerPopping = nil;
            self.isViewControllerTransiting = NO;
        }
    }
}

#pragma mark - 屏幕旋转

- (BOOL)shouldAutorotate {
    return [self.topViewController qmui_hasOverrideUIKitMethod:_cmd] ? [self.topViewController shouldAutorotate] : YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [self.topViewController qmui_hasOverrideUIKitMethod:_cmd] ? [self.topViewController supportedInterfaceOrientations] : SupportedOrientationMask;
}

@end


@implementation QMUINavigationController (UISubclassingHooks)

- (void)willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    // 子类可以重写
}

- (void)didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    // 子类可以重写
}

@end

@implementation _QMUINavigationControllerDelegator

#pragma mark - <UINavigationControllerDelegate>

- (void)navigationController:(QMUINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [navigationController willShowViewController:viewController animated:animated];
}

- (void)navigationController:(QMUINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    navigationController.viewControllerPopping = nil;
    navigationController.isViewControllerTransiting = NO;
    [navigationController didShowViewController:viewController animated:animated];
}

@end
