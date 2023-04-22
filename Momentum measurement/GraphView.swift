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
    @State private var isMeasuring = false
    @Binding var listOfPath: [URL]
    @State var selectedFolderIndex: Int = 0
    init(timeCounter: TimeCounter, listOfPath: Binding<[URL]>) {
        self.sensorDataManager = SensorDataManager(timeCounter: timeCounter)
        self._listOfPath = listOfPath
    }

    var body: some View {
        VStack {
            Text("Graph View")
                .font(.title)
            Text(sensorDataManager.timeCounter.elapsedTimeString)
                .font(.system(size: 40, design: .monospaced))
                .padding()
            Button(isMeasuring ? "Stop Measuring" : "Start Measuring") {
                            isMeasuring.toggle()
                            if isMeasuring {
                                sensorDataManager.startLogging()
                                sensorDataManager.timeCounter.startTimer()
                            } else {
                                sensorDataManager.stopLogging(selectedURL: listOfPath[selectedFolderIndex])
                                sensorDataManager.timeCounter.resetTimer()
                            }
                        }
                .background(Color.blue)
                .foregroundColor(Color.white)
                .cornerRadius(5)
            
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
            Chart(sensorDataManager.sampledData) { data in
                        LineMark(
                            x: .value("time", data.t),
                            y: .value("value", data.y)
                        )
                        .foregroundStyle(by: .value("Form", data.from))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                        .interpolationMethod(.catmullRom)
                    }
                    .frame(height: 300)
                    .padding()
            Spacer()
        }
        .onAppear(){
            listOfPath = updateListOfPath()
        }
    }
}

class SensorDataManager: ObservableObject {
    @Published var sampledData: [SampledData] = []
    private let motionManager = CMMotionManager()
//    private var timer: Timer?
    private var csvText = "timestamp,orientation_x,orientation_y,orientation_z,orientation_w,rotation_rate_x,rotation_rate_y,rotation_rate_z,gravity_x,gravity_y,gravity_z,acceleration_x,acceleration_y,acceleration_z,magnetic_field_x,magnetic_field_y,magnetic_field_z\n"
    @Published var timeCounter: TimeCounter

    init( timeCounter: TimeCounter) {
        self.timeCounter = timeCounter
    }
    func startLogging() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical)
            timeCounter.timer = Timer(fire: Date(), interval: (1.0 / 60.0), repeats: true) { [weak self] timer in
                if let data = self?.motionManager.deviceMotion {
                    let timestamp = String(format: "%.2f", data.timestamp)
                    let elapsedTime = self?.timeCounter.elapsedTime ?? 0
                    let orientation = data.attitude.quaternion
                    let rotationRate = data.rotationRate
                    let gravity = data.gravity
                    let acceleration = data.userAcceleration
                    let magneticField = data.magneticField.field
                    let row = "\(timestamp),\(orientation.x),\(orientation.y),\(orientation.z),\(orientation.w),\(rotationRate.x),\(rotationRate.y),\(rotationRate.z),\(gravity.x),\(gravity.y),\(gravity.z),\(acceleration.x),\(acceleration.y),\(acceleration.z),\(magneticField.x),\(magneticField.y),\(magneticField.z)\n"
                    self?.csvText.append(row)
                    self?.sampledData.append(.init(name: timestamp,t: elapsedTime, y: acceleration.x, from: "acceleration.x"))
                    self?.sampledData.append(.init(name: timestamp,t: elapsedTime, y: acceleration.x, from: "orientation.x"))
                }
            }
            
            RunLoop.current.add(timeCounter.timer!, forMode: .default)
        }
    }

    func stopLogging(selectedURL: URL) {
        motionManager.stopDeviceMotionUpdates()
        timeCounter.timer?.invalidate()
        writeDataToCSV(atURL: selectedURL)
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
}

struct GraphView_Previews: PreviewProvider {
    static var previews: some View {
        GraphView(timeCounter: ContentView().timeCounter, listOfPath: ContentView().$listOfPathOriginal)
    }
}

class TimeCounter: ObservableObject {
    @Published var elapsedTimeString: String = "00:00:00.00"
    var startTime: Date?
    var timer: Timer?
    @Published var elapsedTime: Double = 0
    func startTimer() {
       startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
           self.updateElapsedTime()
       }
    }
    func resetTimer() {
        timer?.invalidate()
        timer = nil
        startTime = nil
        elapsedTimeString = "00:00:00.00"
    }

    private func updateElapsedTime() {
//        guard let startTime = startTime else { return }
//        elapsedTime = Int(Date().timeIntervalSince(startTime))
//        let hours = elapsedTime / 3600
//        let minutes = (elapsedTime % 3600) / 60
//        let seconds = elapsedTime % 60
//        elapsedTimeString = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
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
//    let accelerationData: Double
    let t: Double
//    let x: Double
    let y: Double
    let from: String
}

//struct SampleData: Identifiable {
//    var id: String { name }
//    let name: String
//    let amount: Double
//    let from: String
//    let accelerationData: Double = 0
//    let x: Double = 0
//    let y: Double = 0
//}
//let sampleData: [SampleData] = [
//    .init(name: "NameA", amount: 2500, from: "PlaceA"),
//    .init(name: "NameB", amount: 3500, from: "PlaceA"),
//    .init(name: "NameC", amount: 2000, from: "PlaceA"),
//    .init(name: "NameD", amount: 4000, from: "PlaceA"),
//    .init(name: "NameE", amount: 500,from: "PlaceA"),
//    .init(name: "NameF", amount: 5500,from: "PlaceA"),
//    .init(name: "NameA", amount: 360, from: "PlaceB"),
//    .init(name: "NameB", amount: 640, from: "PlaceB"),
//    .init(name: "NameC", amount: 680, from: "PlaceB"),
//    .init(name: "NameD", amount: 760, from: "PlaceB"),
//    .init(name: "NameE", amount: 780, from: "PlaceB"),
//    .init(name: "NameF", amount: 800, from: "PlaceB")
//]
//struct LineMarkView: View {
//    var body: some View {
//        Chart(sampleData) { data in
//            LineMark(
//                x: .value("Name", data.name),
//                y: .value("Amount", data.amount)
//            )
//            .foregroundStyle(by: .value("Form", data.from))
//            .lineStyle(StrokeStyle(lineWidth: 1))
//            .interpolationMethod(.catmullRom)
//        }
//        .frame(height: 300)
//        .padding()
//    }
//}
//
//struct CoontentView: View {
//    var body: some View {
//        LineMarkView()
//    }
//}
//struct GraphView2_Previews: PreviewProvider {
//
//    static var previews: some View {
//        LineMarkView()
//    }
//}
