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
    @State private var isMeasuring = false
    @ObservedObject var sensorDataManager: SensorDataManager
    @Binding var listOfPath: [URL]
    
    var body: some View {
        VStack {
            Text("Graph View")
            Button(isMeasuring ? "Stop Measuring" : "Start Measuring") {
                            isMeasuring.toggle()
                            if isMeasuring {
                                sensorDataManager.startLogging()
                            } else {
                                sensorDataManager.stopLogging()
                            }
                        }
            HStack {
                Spacer()
                Text("記録する動作")
                Image(systemName: "folder")
                Picker("記録する動作を選択", selection: $sensorDataManager.selectedFolderIndex) {
                    ForEach($sensorDataManager.listOfPath.indices, id: \.self) { index in
                        if sensorDataManager.listOfPath[index].hasDirectoryPath {
                            Text(sensorDataManager.listOfPath[index].lastPathComponent)
                        }
                    }
                }
                .pickerStyle(WheelPickerStyle())
                Spacer()
            }
            LineView(data: sensorDataManager.accelerationData, title: "Acceleration")
            LineView(data: sensorDataManager.gyroData, title: "Gyro")
        }
    }
}

class SensorDataManager: ObservableObject {
    @Published var accelerationData: [Double] = []
    @Published var gyroData: [Double] = []
    @Published var selectedFolderIndex = 0
    private let motionManager = CMMotionManager()
    private var timer: Timer?
    private var csvText = "timestamp,orientation_x,orientation_y,orientation_z,orientation_w,rotation_rate_x,rotation_rate_y,rotation_rate_z,gravity_x,gravity_y,gravity_z,acceleration_x,acceleration_y,acceleration_z,magnetic_field_x,magnetic_field_y,magnetic_field_z\n"
    var listOfPath: [URL]
    init(listOfPath1: [URL]) {
        self.listOfPath = listOfPath1
    }
    
    func startLogging() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical)
            timer = Timer(fire: Date(), interval: (1.0 / 60.0), repeats: true) { [weak self] timer in
                if let data = self?.motionManager.deviceMotion {
                    let timestamp = String(format: "%.2f", data.timestamp)
                    let orientation = data.attitude.quaternion
                    let rotationRate = data.rotationRate
                    let gravity = data.gravity
                    let acceleration = data.userAcceleration
                    let magneticField = data.magneticField.field
                    let row = "\(timestamp),\(orientation.x),\(orientation.y),\(orientation.z),\(orientation.w),\(rotationRate.x),\(rotationRate.y),\(rotationRate.z),\(gravity.x),\(gravity.y),\(gravity.z),\(acceleration.x),\(acceleration.y),\(acceleration.z),\(magneticField.x),\(magneticField.y),\(magneticField.z)\n"
                    self?.csvText.append(row)
                    self?.accelerationData.append(sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2)))
                    self?.gyroData.append(sqrt(pow(rotationRate.x, 2) + pow(rotationRate.y, 2) + pow(rotationRate.z, 2)))
                }
            }
            RunLoop.current.add(timer!, forMode: .default)
        }
    }
    
    func stopLogging() {
        motionManager.stopDeviceMotionUpdates()
        timer?.invalidate()
        writeDataToCSV()
    }
    
    func writeDataToCSV() {
//        guard let url = listOfPath[selectedFolderIndex].appendingPathComponent("data.csv") else {
        guard let url = listOfPath[selectedFolderIndex].appendingPathComponent("data.csv") as URL? else {
            print("Could not create URL")
            return
        }
        
        do {
            try csvText.write(to: url, atomically: true, encoding: .utf8)
            print("Data saved to \(url.absoluteString)")
        } catch {
            print("Error writing data to csv file: \(error.localizedDescription)")
        }
    }
}
//struct GraphView: View {
//    let motionManager = CMMotionManager()
//    @State private var accelerationData: [Double] = []
//    @State private var gyroData: [Double] = []
//    @State private var isMeasuring = false
//    @State private var selectedFolderIndex = 0
//    @Binding var listOfPath: [URL] //ContentViewで定義されたものを参照している
//    var body: some View {
//        VStack {
//        Text("Graph View")
//            HStack {
//                Spacer()
//                Text("記録する動作")
//                Image(systemName: "folder")
//
//                Picker("記録する動作を選択", selection: $selectedFolderIndex) {
//                    ForEach(0..<listOfPath.count, id: \.self) { index in
//                        if listOfPath[index].hasDirectoryPath {
//                            Text(listOfPath[index].lastPathComponent)
//                        }
//                    }
//                .pickerStyle(WheelPickerStyle())
//                }
////            Text(documents.listOfPath[selectedFolderIndex].lastPathComponent)
//            Spacer()
//            }
//            LineView(data: accelerationData, title: "Acceleration")
//            LineView(data: gyroData, title: "Gyro")
//        }
//    }
//
//    func startMotionUpdates() {
//        if motionManager.isAccelerometerAvailable {
//            motionManager.accelerometerUpdateInterval = 0.1
//            motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
//                if let acceleration = data?.acceleration {
//                    accelerationData.append(sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2)))
//                    let accelerometerData = CMAccelerometerData()
//                }
//            }
//        }
//        if motionManager.isGyroAvailable {
//            motionManager.gyroUpdateInterval = 0.1
//            motionManager.startGyroUpdates(to: .main) { (data, error) in
//                if let rotation = data?.rotationRate {
//                    gyroData.append(sqrt(pow(rotation.x, 2) + pow(rotation.y, 2) + pow(rotation.z, 2)))
//                }
//            }
//        }
//    }
//
//    func stopMotionUpdates() {
//        motionManager.stopAccelerometerUpdates()
//        motionManager.stopGyroUpdates()
//
//    }
//}
//
//class SensorDataManager {
//
//    let motionManager = CMMotionManager()
//    var timer: Timer?
//    var csvText = "timestamp,orientation_x,orientation_y,orientation_z,orientation_w,rotation_rate_x,rotation_rate_y,rotation_rate_z,gravity_x,gravity_y,gravity_z,acceleration_x,acceleration_y,acceleration_z,magnetic_field_x,magnetic_field_y,magnetic_field_z\n"
//
//    func startLogging() {
//        if motionManager.isDeviceMotionAvailable {
//            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
//            motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical)
//            timer = Timer(fire: Date(), interval: (1.0/60.0), repeats: true, block: { (timer) in
//                if let data = self.motionManager.deviceMotion {
//                    let timestamp = String(format: "%f", data.timestamp)
//                    let orientationX = String(format: "%f", data.attitude.quaternion.x)
//                    let orientationY = String(format: "%f", data.attitude.quaternion.y)
//                    let orientationZ = String(format: "%f", data.attitude.quaternion.z)
//                    let orientationW = String(format: "%f", data.attitude.quaternion.w)
//                    let rotationRateX = String(format: "%f", data.rotationRate.x)
//                    let rotationRateY = String(format: "%f", data.rotationRate.y)
//                    let rotationRateZ = String(format: "%f", data.rotationRate.z)
//                    let gravityX = String(format: "%f", data.gravity.x)
//                    let gravityY = String(format: "%f", data.gravity.y)
//                    let gravityZ = String(format: "%f", data.gravity.z)
//                    let accelerationX = String(format: "%f", data.userAcceleration.x)
//                    let accelerationY = String(format: "%f", data.userAcceleration.y)
//                    let accelerationZ = String(format: "%f", data.userAcceleration.z)
//                    let magneticFieldX = String(format: "%f", data.magneticField.field.x)
//                    let magneticFieldY = String(format: "%f", data.magneticField.field.y)
//                    let magneticFieldZ = String(format: "%f", data.magneticField.field.z)
//                    self.csvText += "\(timestamp),\(orientationX),\(orientationY),\(orientationZ),\(orientationW),\(rotationRateX),\(rotationRateY),\(rotationRateZ),\(gravityX),\(gravityY),\(gravityZ),\(accelerationX),\(accelerationY),\(accelerationZ),\(magneticFieldX),\(magneticFieldY),\(magneticFieldZ)\n"
//                }
//            })
//            RunLoop.current.add(timer!, forMode: .default)
//        }
//    }
//
//    func stopLogging() {
//        timer?.invalidate()
//        motionManager.stopDeviceMotionUpdates()
//        let fileName = "sensor_data.csv"
//        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
//            let fileURL = dir.appendingPathComponent(fileName)
//            do {
//                try csvText.write(to: fileURL, atomically: false, encoding: .utf8)
//            } catch {
//                print("Error writing CSV file.")
//            }
//        }
//    }
//}
//
////struct GraphView_Previews: PreviewProvider {
////
////    static var previews: some View {
////        GraphView(listOfPath: updateListOfPath())
////    }
////}
