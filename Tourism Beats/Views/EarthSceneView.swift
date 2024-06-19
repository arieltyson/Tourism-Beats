//
//  EarthSceneView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 17/6/24.
//

import SwiftUI
import SceneKit

struct EarthSceneView: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = createScene()
        sceneView.allowsCameraControl = false
        sceneView.showsStatistics = false
        sceneView.backgroundColor = UIColor.black
        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    private func createScene() -> SCNScene {
        let scene = SCNScene()

        // Create and add the Earth node
        let earthNode = createEarthNode()
        scene.rootNode.addChildNode(earthNode)

        // Rotate the Earth node
        let rotation = CABasicAnimation(keyPath: "rotation")
        rotation.toValue = NSValue(scnVector4: SCNVector4(0, 1, 0, CGFloat.pi * 2))
        rotation.duration = 60
        rotation.repeatCount = .infinity
        earthNode.addAnimation(rotation, forKey: "rotation")

        return scene
    }

    private func createEarthNode() -> SCNNode {
        let earth = SCNSphere(radius: 1.0)
        let earthMaterial = SCNMaterial()
        earthMaterial.diffuse.contents = UIImage(named: "earth_night.jpg")
        earth.firstMaterial = earthMaterial

        let earthNode = SCNNode(geometry: earth)
        earthNode.position = SCNVector3(0, 0, 0)
        return earthNode
    }
}

struct EarthSceneView_Previews: PreviewProvider {
    static var previews: some View {
        EarthSceneView()
            .edgesIgnoringSafeArea(.all)
    }
}
