//
//  RecordView.swift
//  Momentum measurement
//
//  Created by 滝瀬隆斗 on 2023/03/29.
//

import SwiftUI

struct RecordView: View {
    @Environment(\.dismiss) var dismissKeyboard
    @State private var isEditing = false
    @State private var newItem = ""
    @Binding var listOfPath: [URL]
    @State private var deleteCandidate: URL?
    var body: some View {
        NavigationView {
            List{
                ForEach(listOfPath, id: \.self) { url in
                    ItemCell(url:url)
                }
                .onDelete { (indexSet) in
                    if let index = indexSet.first {
                        deleteCandidate = listOfPath[index]
                    }
                    if let candidate = deleteCandidate {
                        removeItem(atPath: candidate)
                        listOfPath = getFolder(url: URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]))
                        deleteCandidate = nil
                    }
                }
                TextField("New Item", text: $newItem, onCommit: {
                    isEditing = false
                    createDirectory()
                })
                //                    .focused($isEditing)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.default)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(5)
                //                                    .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                //                                    .overlay(
                //                                        RoundedRectangle(cornerRadius: 8)
                //                                            .stroke(Color(.separator), lineWidth: 1)
                //                                    )
                .padding(.horizontal)
                .onTapGesture {
                    isEditing = true
                }
                .onAppear {
                    isEditing = true
                }
                .animation(.default, value: isEditing)
            }
            .onTapGesture {
                self.dismissKeyboard() // フォーカスを解除
            }
            .navigationBarItems(
                leading: EditButton(),
                trailing:
                    Button(action: {
                        isEditing = false
                        createDirectory()
                    }) {
                        Image(systemName: "plus")
                    }
                //                    .disabled(newItem.isEmpty)
            )
            .navigationTitle("Activity")
        }
    }
    private func delete(at offsets: IndexSet) {
        listOfPath.remove(atOffsets: offsets)
    }
    
    private func move(from source: IndexSet, to destination: Int) {
        listOfPath.move(fromOffsets: source, toOffset: destination)
    }
    
    func createDirectory() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        let directoryURL = documentsDirectory.appendingPathComponent(newItem, isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            listOfPath.append(directoryURL)
            self.newItem = ""
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
                                    deleteCandidate = getFolder(url: url)[index]
                                    showingDeleteAlertSub = true
                                }
                            }
        }
        .navigationBarTitle(url.lastPathComponent, displayMode: .inline)
    }
    
    func deleteFile(atPath path: URL) {
        removeItem(atPath: path)
        print("\(path)はデリートされた\n")
//        self.showingDeleteAlert = false
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



struct RecordView_Previews: PreviewProvider {
    @State var listOfPath: [URL] = []
    static var previews: some View {
        RecordView(listOfPath: ContentView().$listOfPathOriginal)
    }
}
