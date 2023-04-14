//
//  SwiftUIView.swift
//  Momentum measurement
//
//  Created by 滝瀬隆斗 on 2023/03/29.
//

import SwiftUI
import CoreMotion
import SwiftUICharts
import Charts

struct GraphView: View {
    @State private var isMeasuring = false
    @ObservedObject var sensorDataManager: SensorDataManager
//    @Binding var listOfPath: [URL]
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
////            LineView(data: sensorDataManager.accelerationData, title: "Acceleration")
////            LineView(data: sensorDataManager.gyroData, title: "Gyro")
////            MultiLineChartView(data: [(sensorDataManager.accelerationData, GradientColors.green), (sensorDataManager.gyroData, GradientColors.purple)],  title: "Momentum", form: ChartForm.extraLarge, dropShadow: true, valueSpecifier:"%.2f")
//            LineChartView(data: sensorDataManager.accelerationData)
//                .frame(height: 200)
//            VStack {
//                HStack {
//                    Text("Time (s)")
//                        .font(.caption)
//                        .opacity(0.5)
//                    Spacer()
//                }
//                MultiLineChartView(
//                    data: [
//                        (sensorDataManager.accelerationData, GradientColors.green),
////                        (sensorDataManager.gyroData, GradientColors.purple),
////                        (sensorDataManager.magneticData, GradientColors.blue) // SensorDataManagerでmagneticDataも定義する必要があります
//                    ],
//                    title: "Sensor Data",
//                    form: ChartForm.extraLarge,
//                    dropShadow: true,
//                    valueSpecifier: "%.2f"
//                )
//                .frame(height: 200)
//                HStack {
//                    Text("0")
//                        .font(.caption)
//                        .opacity(0.5)
//                    Spacer()
//                    Text("Max Time")
//                        .font(.caption)
//                        .opacity(0.5)
//                }
//            }
            SensorDataChartView(
                data: [
                      (data: sensorDataManager.accelerationData, color: GradientColors.green),
                      (data: sensorDataManager.gyroData, color: GradientColors.purple),
//                      (data: sensorDataManager.magneticData, color: GradientColors.blue) // SensorDataManagerでmagneticDataも定義する必要があります
                  ]
            )
            .frame(height: 200)
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

struct GraphView_Previews: PreviewProvider {

    static var previews: some View {
        GraphView(sensorDataManager: SensorDataManager(listOfPath1: ContentView().listOfPathOriginal))
    }
}


struct LineChartView: View {
    
    let data: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            let maxData = data.max() ?? 1
            let stepSize = geometry.size.height / CGFloat(maxData)
            
            Path { path in
                path.move(to: CGPoint(x: 0, y: geometry.size.height))
                for i in 0..<data.count {
                    let x = geometry.size.width / CGFloat(data.count) * CGFloat(i)
                    let y = geometry.size.height - CGFloat(data[i]) * stepSize
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(lineWidth: 2)
            .foregroundColor(.blue)
        }
    }
}

struct lineView: View {
    
    let data: [Double] = [0.0, 1.0, 0.0, 3.0, 4.0, 5.0, 5.5, 3.0, 2.0, 1.0, 0.0]
    
    var body: some View {
        VStack {
            Text("Line Chart Example")
            LineChartView(data: data)
                .frame(height: 200)
        }
    }
}

struct SensorDataChartView: View {
    let data: [(data: [Double], color: GradientColor)]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                MultiLineChartView(
                    data: data.map { (data: $0.data, color: $0.color) },
                    title: "Sensor Data",
                    form: ChartForm.extraLarge,
                    dropShadow: false,
                    valueSpecifier: "%.2f"
                )
                
                // 縦軸ラベル
                VStack {
                    Text("Value")
                        .font(.caption)
                        .opacity(0.5)
                        .padding(.bottom, -8)
                    Spacer()
                    Text("0")
                        .font(.caption)
                        .opacity(0.5)
                }
                .padding(.leading, 8)
                
                // 横軸ラベル
                HStack {
                    Text("0")
                        .font(.caption)
                        .opacity(0.5)
                    Spacer()
                    Text("Time (s)")
                        .font(.caption)
                        .opacity(0.5)
                }
                .padding(.bottom, 8)
            }
            .frame(height: geometry.size.height)
        }
    }
}

struct LineView_Previews: PreviewProvider {
    static var previews: some View {
        lineView()
    }
}
