//
//  ViewController.swift
//  testMetal
//
//  Created by 闫振 on 2020/12/10.
//

import UIKit

let YZBRIGHT = false

class ViewController: UIViewController {

    var camera:Camera!
    
    private var renderView: RenderView!
    
    @IBOutlet private weak var brightSlider: UISlider!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        do {
            camera = try Camera(sessionPreset: .vga640x480)
            
//            camera.renderView = xibRenderView
            
            renderView = RenderView(frame: UIScreen.main.bounds, device: sharedMetalRenderingDevice.device)
            self.view.insertSubview(renderView, at: 0)
            if YZBRIGHT {
                let bright = Brightness()
                bright.renderViwe = renderView
                camera.bright = bright
            } else {
                camera.renderView = renderView
            }
            
            camera.startCapture()
        } catch {
            fatalError("Could not initialize rendering pipeline: \(error)")
        }
    }

    @IBAction func sliderAction(_ sender: UISlider) {
        print(sender.value)
    }
    
}

