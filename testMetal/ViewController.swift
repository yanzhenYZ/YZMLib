//
//  ViewController.swift
//  testMetal
//
//  Created by 闫振 on 2020/12/10.
//

import UIKit
/**
 1.0.1 清理资源
 1.0.2 拆解流程
 1.0.3 MTKView手动初始化问题
 1.0.4 MTKView delegate问题
 */
class ViewController: UIViewController {

    var camera:Camera!
    
    @IBOutlet weak var xibRenderView: RenderView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        do {
            camera = try Camera(sessionPreset: .vga640x480)
//            camera.runBenchmark = true
//            camera --> operation --> renderView
            

//            let renderView = RenderView(frame: UIScreen.main.bounds, device: sharedMetalRenderingDevice.device)
//            camera.renderView = renderView;
            
            camera.renderView = xibRenderView
            
            camera.startCapture()
        } catch {
            fatalError("Could not initialize rendering pipeline: \(error)")
        }
    }


}

