//
//  SwiftUIView.swift
//  Momentum measurement
//
//  Created by 滝瀬隆斗 on 2023/03/29.
//

import SwiftUI
import CoreMotion
import SwiftUICharts

struct GraphView: View {
    let motionManager = CMMotionManager()
    @State private var accelerationData: [Double] = []
    @State private var gyroData: [Double] = []
    @State private var isMeasuring = false
    @State private var selectedFolderIndex = 0
    @Binding var listOfPath: [URL]
    var body: some View {
        VStack {
        Text("Graph View")
            Button(isMeasuring ? "Stop Measuring" : "Start Measuring") {
                isMeasuring.toggle()
                if isMeasuring {
                    startMotionUpdates()
                } else {
                    stopMotionUpdates()
                }
            }
            Picker("記録する動作を選択", selection: $selectedFolderIndex) {
                ForEach(0..<listOfPath.count, id: \.self) { index in
                    if listOfPath[index].hasDirectoryPath {
                        Text(listOfPath[index].lastPathComponent)
                    }
                }
            }
            .pickerStyle(WheelPickerStyle())
            LineView(data: accelerationData, title: "Acceleration")
            LineView(data: gyroData, title: "Gyro")
        }
    }
    
    func startMotionUpdates() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
                if let acceleration = data?.acceleration {
                    accelerationData.append(sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2)))
                }
            }
        }
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = 0.1
            motionManager.startGyroUpdates(to: .main) { (data, error) in
                if let rotation = data?.rotationRate {
                    gyroData.append(sqrt(pow(rotation.x, 2) + pow(rotation.y, 2) + pow(rotation.z, 2)))
                }
            }
        }
    }

    func stopMotionUpdates() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
    }
}


//struct GraphView_Previews: PreviewProvider {
//    
//    static var previews: some View {
//        GraphView(listOfPath: updateListOfPath())
//    }
//}
