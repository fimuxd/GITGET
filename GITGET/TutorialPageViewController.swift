//
//  TutorialPageViewController.swift
//  GITGET
//
//  Created by Bo-Young PARK on 30/11/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import UIKit

class TutorialPageViewController: UIPageViewController {

    /********************************************/
    //MARK:-      Variation | IBOutlet          //
    /********************************************/
    private(set) lazy var orderedViewControllers:[UIViewController] = {
        return [self.viewController(forTutorial: "OpenTodayViewController"),
                self.viewController(forTutorial: "AddWidgetViewController"),
                self.viewController(forTutorial: "WidgetViewController"),
                self.viewController(forTutorial: "SingleTapViewController"),
                self.viewController(forTutorial: "DoubleTapViewController")]
    }()
    
    /********************************************/
    //MARK:-            LifeCycle               //
    /********************************************/
    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
        
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let scrollView = view.subviews.filter({ $0 is UIScrollView }).first,
            let pageControl = view.subviews.filter({ $0 is UIPageControl }).first {
            scrollView.frame = view.bounds
            view.bringSubview(toFront:pageControl)
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /********************************************/
    //MARK:-       Methods | IBAction           //
    /********************************************/
    
    private func viewController(forTutorial storyboardID:String) -> UIViewController {
        let storyboard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController:UIViewController = storyboard.instantiateViewController(withIdentifier: storyboardID)
        return viewController
    }
    

}

extension TutorialPageViewController:UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {return nil}
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0,
         orderedViewControllers.count > previousIndex else {return nil}
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {return nil}
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        
        guard orderedViewControllersCount != nextIndex,
            orderedViewControllersCount > nextIndex else {return nil}
        
        return orderedViewControllers[nextIndex]
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return orderedViewControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let firstViewController = viewControllers?.first,
            let firstViewControllerIndex = orderedViewControllers.index(of: firstViewController) else {return 0}
        
        return firstViewControllerIndex
    }

}
