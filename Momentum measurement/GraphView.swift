//
//  SwiftUIView.swift
//  Momentum measurement
//
//  Created by 滝瀬隆斗 on 2023/03/29.
//

import SwiftUI
import CoreMotion
import Charts

struct GraphView: View {
    @ObservedObject var sensorDataManager: SensorDataManager
    @State var isMeasuring = false
    @Binding var listOfPath: [URL]
    @State var selectedFolderIndex: Int = 0
    init(timeCounter: TimeCounter, listOfPath: Binding<[URL]>) {
        self.sensorDataManager = SensorDataManager(timeCounter: timeCounter)
        self._listOfPath = listOfPath
    }

    var body: some View {
        VStack {
//            Text("Graph View")
//                .font(.title)
            
            Text(sensorDataManager.timeCounter.elapsedTimeString)
                .font(.system(size: 40, design: .monospaced))
                .padding()
            Chart(sensorDataManager.sampledData) { data in
                LineMark(
                    x: .value("time", data.time),
                    y: .value("value", data.value)
                )
                .foregroundStyle(by: .value("Form", data.from))
                .lineStyle(StrokeStyle(lineWidth: 1))
                .interpolationMethod(.catmullRom)
            }
//                .background(Color.gray.opacity(0.3)) // グラフの背景色を変更
                .frame(height: 300)
                .padding()
                .chartXScale(domain: sensorDataManager.minTime...sensorDataManager.maxTime)
                .chartYScale(domain: sensorDataManager.minValue...sensorDataManager.maxValue)
        
            
            HStack {
                Spacer()
                Text("記録する動作")
                Image(systemName: "folder")
                Picker(selection: $selectedFolderIndex, label: Text("記録する動作")) {
                    ForEach(listOfPath.indices, id: \.self) { index in
                        if listOfPath[index].hasDirectoryPath {
                            Text(listOfPath[index].lastPathComponent)
                        }
                    }
                }
                    .pickerStyle(WheelPickerStyle())
                Spacer()
            }
//            Spacer()
            Button(isMeasuring ? "Stop Measuring" : "Start Measuring") {
                            isMeasuring.toggle()
                            if isMeasuring {
                                sensorDataManager.startLogging()
                            } else {
                                sensorDataManager.stopLogging(selectedURL: listOfPath[selectedFolderIndex])
                                sensorDataManager.timeCounter.resetTimer()
                            }
            }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
//                .background(Color.blue)
//                .foregroundColor(Color.white)
//                .cornerRadius(5)
               
            Spacer()
        }
        .onAppear(){
            listOfPath = updateListOfPath()
        }
        
    }
}

class SensorDataManager: ObservableObject {
    let timeOfView = 5 //表示秒数
     //1秒あたりのデータ取得
    let sampleCount = 3 //今回はaccereration.xyz
//    let maxSamples = timeArchive * 100 * 3// 10秒間分のサンプル数 (1秒あたり60サンプル)
    let maxSamples: Int
    @Published var sampledData: [SampledData] = []
    private let motionManager = CMMotionManager()
//    private var timer: Timer?
    private var csvText = "timestamp,elapsedTime,orientation_x,orientation_y,orientation_z,orientation_w,rotation_rate_x,rotation_rate_y,rotation_rate_z,gravity_x,gravity_y,gravity_z,acceleration_x,acceleration_y,acceleration_z,magnetic_field_x,magnetic_field_y,magnetic_field_z\n"
    @Published var timeCounter: TimeCounter

    init( timeCounter: TimeCounter) {
        self.timeCounter = timeCounter
        maxSamples = timeOfView * timeCounter.samplingRate * sampleCount// 5秒間分のサンプル数 (1秒あたり60サンプル)*データ種類3xyz
    }
    func startLogging() {
        print("カウントスタート時\(self.sampledData.count)")
        var count = 0
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / Double(timeCounter.samplingRate)
            motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical)
//            timer = Timer(fire: Date(), interval: (1.0 / 60.0), repeats: true) { [weak self] timer in
            timeCounter.startTimer { [weak self] timer in
                if let data = self?.motionManager.deviceMotion {
                    let timestamp = String(format: "%.2f", data.timestamp)
                    let elapsedTime = self?.timeCounter.elapsedTime ?? 0
                    let orientation = data.attitude.quaternion
                    let rotationRate = data.rotationRate
                    let gravity = data.gravity
                    let acceleration = data.userAcceleration
                    let magneticField = data.magneticField.field
                    let row = "\(timestamp),\(elapsedTime),\(orientation.x),\(orientation.y),\(orientation.z),\(orientation.w),\(rotationRate.x),\(rotationRate.y),\(rotationRate.z),\(gravity.x),\(gravity.y),\(gravity.z),\(acceleration.x),\(acceleration.y),\(acceleration.z),\(magneticField.x),\(magneticField.y),\(magneticField.z)\n"
                    self?.csvText.append(row)
//                    self?.sampledData.append(.init(name: timestamp,time: elapsedTime, value: acceleration.x, from: "acceleration.x"))
//                    self?.sampledData.append(.init(name: timestamp,time: elapsedTime, value: acceleration.y, from: "orientation.y"))
//                    self?.sampledData.append(.init(name: timestamp,time: elapsedTime, value: acceleration.z, from: "acceleration.z"))
                    self?.sampledData.append(contentsOf: [.init(name: timestamp,time: elapsedTime, value: acceleration.x, from: "acceleration.x"), .init(name: timestamp,time: elapsedTime, value: acceleration.y, from: "orientation.y"), .init(name: timestamp,time: elapsedTime, value: acceleration.z, from: "acceleration.z")])
                    // 最新の5秒分のデータのみを保持
                    print("カウント\(self?.sampledData.count ?? 0), 番号 \(count)")
                    if self?.sampledData.count ?? 0 >= self?.maxSamples ?? 0 {
                        self?.sampledData.removeFirst(3)
                       
                    }
                    count = count+1
                    
                }
            }
            
//            RunLoop.current.add(Loggingtimer!, forMode: .default)
        }
    }

    func stopLogging(selectedURL: URL) {
        print("カウントストップ時\(self.sampledData.count)")
        motionManager.stopDeviceMotionUpdates()
        writeDataToCSV(atURL: selectedURL)
        self.sampledData.removeAll()//記録が終わったら表示を止める
        print("カウントリセット時\(self.sampledData.count)")
    }

    func writeDataToCSV(atURL: URL) {
        let FileName = timeCounter.getFileName()
        guard let url = atURL.appendingPathComponent(FileName) as URL? else {
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
    // グラフのx軸の最小値と最大値を計算
    var minTime: Double {
        return max(0, timeCounter.elapsedTime - Double(timeOfView))
    }

    var maxTime: Double {
        return max(timeCounter.elapsedTime, 5)
    }
    
    var minValue: Double {
        return min(-2.5, sampledData.min { $0.value < $1.value }?.value ?? 0.0)
    }
    var maxValue: Double {
        return max(sampledData.max { $0.value < $1.value }?.value ?? 0.0, 2.5)
    }
}

struct GraphView_Previews: PreviewProvider {
    static var previews: some View {
        GraphView(timeCounter: ContentView().timeCounter, listOfPath: ContentView().$listOfPathOriginal)
    }
}

class TimeCounter: ObservableObject {
    let samplingRate = 60
    @Published var elapsedTimeString: String = "00:00:00.00"
    @Published var loggingTimer: Timer?
    var startTime: Date?
    var timer: Timer?
    @Published var elapsedTime: Double = 0
//    func startTimer() {
//       startTime = Date()
//        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
//           self.updateElapsedTime()
//       }
//    }
    func resetTimer() {
        timer?.invalidate()
        timer = nil
        startTime = nil
        elapsedTimeString = "00:00:00.00"
        elapsedTime = 0
    }

    func startTimer(action: @escaping (Timer) -> Void) {
        startTime = Date()
        timer = Timer(fire: Date(), interval: 1.0/Double(samplingRate), repeats: true) { timer in
            self.updateElapsedTime()
            action(timer)
        }
            
        RunLoop.current.add(timer!, forMode: .default)
    }

    private func updateElapsedTime() {
        guard let startTime = startTime else { return }
        let elapsedTime = Date().timeIntervalSince(startTime)
        let hours = Int(elapsedTime / 3600)
        let minutes = Int((elapsedTime.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(elapsedTime.truncatingRemainder(dividingBy: 60))
        let milliseconds = Int((elapsedTime.truncatingRemainder(dividingBy: 1)) * 100)
        let elapsedTimeString = String(format: "%02d:%02d:%02d.%02d", hours, minutes, seconds, milliseconds)
        self.elapsedTime = elapsedTime
        self.elapsedTimeString = elapsedTimeString
    }
    func getFileName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-HHmmss"
        let dateString = dateFormatter.string(from: startTime ?? Date())
        return "file-\(dateString).csv"
    }
}

struct SampledData: Identifiable {
    var id: String { name }
    let name: String
    let time: Double
    let value: Double
    let from: String
}
