//
//  RecordView.swift
//  Momentum measurement
//
//  Created by 滝瀬隆斗 on 2023/03/29.
//

import SwiftUI

struct Record: Identifiable {
    let id = UUID()
    let date: Date
    let filename: String
    var recordOfMotionData: [MotionData] = []
    }

struct MotionData {
    var accelerationX: Double
    var accelerationY: Double
    var accelerationZ: Double
    var gyroX: Double
    var gyroY: Double
    var gyroZ: Double
}


struct RecordView: View {
    @State private var records: [Record] = []
    @State private var activityFolderName: String = ""
    @Binding var listOfPath: [URL]
    @State private var showingAddFolderAlart = false
    @State private var showingDeleteAlert = false
    @State private var deleteCandidate: URL?
    var body: some View {
                NavigationView {
//                    List(records) { record in
//                        Text("\(record.date): \(record.filename)")
                    List{
                        ForEach(listOfPath, id: \.self) { url in
                            ItemCell(url:url)
                        }
                        .onDelete { (indexSet) in
                                            if let index = indexSet.first {
                                                deleteCandidate = listOfPath[index]
                                                showingDeleteAlert = true
                                            }
                                        }
                        .alert(isPresented: $showingDeleteAlert) {
                            Alert(title: Text("削除の確認"),
                                  message: Text("「\(deleteCandidate?.lastPathComponent ?? "")」を削除しますか？"),
                                  primaryButton: .cancel(Text("キャンセル")),
                                  secondaryButton: .destructive(Text("削除"), action: {
                                    if let candidate = deleteCandidate {
                                        removeItem(atPath: candidate)
                                        listOfPath = getFolder(url: URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]))
                                        deleteCandidate = nil
                                    }
                                  }))
                        }
                        
                    }
                    .navigationTitle("Activity")
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            Button(action: {showingAddFolderAlart = true},
                                   label: {
                                    Image(systemName: "folder.badge.plus")
                                })
                                TextFieldAlertView(
                                        text: $activityFolderName,
                                        isShowingAlert: $showingAddFolderAlart,
                                        placeholder: "",
                                        isSecureTextEntry: false,
                                        title: "新規フォルダ作成",
                                        message: "保存する動作名を入力してください",
                                        leftButtonTitle: "キャンセル",
                                        rightButtonTitle: "作成",
                                        leftButtonAction: {activityFolderName = ""},
                                        rightButtonAction: {
                                            createDirectory()
                                            activityFolderName = ""
                                            print("ファイルを作成したよ")
                                        }
                                    )
                        }
                    }
                }
            }

        
    func createDirectory() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        let directoryURL = documentsDirectory.appendingPathComponent(activityFolderName, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            listOfPath.append(directoryURL)
//            saveRecord(directory: directoryURL)
        } catch {
            print(error.localizedDescription)
        }
    }
    


    func saveRecord(directory: URL) {
        let date = Date()
        let filename = "record_\(date.timeIntervalSince1970).csv"
        let fileURL = directory.appendingPathComponent(filename)
        do {
            try "".write(to: fileURL, atomically: true, encoding: .utf8)
            records.append(Record(date: date, filename: filename))
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct ItemCell: View {
    let url: URL
    var body: some View {
        HStack {
            if url.hasDirectoryPath {
                /// フォルダ
                NavigationLink(destination: SubFolder(url: url)) {
                    Image(systemName: "folder")
                    Text(url.lastPathComponent)
                }
            } else {
                /// ファイル
                Image(systemName: "doc.text")
                Text(url.lastPathComponent)
            }
        }
        
//        .navigationBarTitle("ChildView", displayMode: .inline)
    }
}

struct SubFolder: View {
    @State private var showingDeleteAlert = false
    @State var listOfPath: [URL] = []
    @State private var showingDeleteAlertSub = false
    @State private var deleteCandidate: URL?
    let url: URL
    var body: some View {
        List {
            ForEach(getFolder(url: url), id: \.self) { url in
                ItemCell(url:url)
            }
            .onDelete { (indexSet) in
                                if let index = indexSet.first {
                                    deleteCandidate = listOfPath[index]
                                    showingDeleteAlertSub = true
                                }
                            }
            .alert(isPresented: $showingDeleteAlert) {
                Alert(title: Text("削除の確認"),
                      message: Text("「\(deleteCandidate?.lastPathComponent ?? "")」を削除しますか？"),
                      primaryButton: .cancel(Text("キャンセル")),
                      secondaryButton: .destructive(Text("削除"), action: {
                        if let candidate = deleteCandidate {
                            removeItem(atPath: candidate)
                            deleteCandidate = nil
                        }
                      }))
            }
        }
        .navigationBarTitle(url.lastPathComponent, displayMode: .inline)
    }
    
    func deleteFile(atPath path: URL) {
        removeItem(atPath: path)
        print("\(path)はデリートされた\n")
        self.showingDeleteAlert = false
    }
}


func getFolder(url: URL) -> [URL] {
    do {
        /// フォルダのURLからふくまれるURLを取得
        let fileAndFolderURLs = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        return fileAndFolderURLs
    } catch {
        print(error)
        return []
    }
}


func removeItem(atPath path: URL) {
    let fileManager = FileManager.default
    do {
        try fileManager.removeItem(at: path)
    } catch {
        fatalError("Failed to remove item at path \(path). Error: \(error.localizedDescription)")
    }
}

//func updateListOfPath(at path: URL = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])) -> [URL]{
//    let listOfPath = getFolder(url: path)
////        listOfPath.reverse()
//    return listOfPath
//}


//struct RecordView_Previews: PreviewProvider {
//    @State var listOfPath: [URL] = []
//    static var previews: some View {
//        RecordView(listOfPath: $listOfPath)
//    }
//}
