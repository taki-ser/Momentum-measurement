//
//  RecordView.swift
//  Momentum measurement
//
//  Created by 滝瀬隆斗 on 2023/03/29.
//

import SwiftUI

struct RecordView: View {
    
    @State private var newItem = ""
    @Binding var listOfPath: [URL]
    @State private var deleteCandidate: URL?
    @FocusState private var isEditing: Bool
    var body: some View {
        NavigationView {
            List{
                ForEach(listOfPath, id: \.self) { url in
                    ItemCell(url: url)
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
                HStack{
                    Image(systemName: "folder")
                    TextField("New Item", text: $newItem, onCommit: {
                        isEditing = false
                        if newItem != "" {
                            createDirectory()
                        }
                        DispatchQueue.main.async {
                            newItem = "" // テキストフィールドを空にする
                        }
                    })
                    .focused($isEditing)
                    .keyboardType(.default)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal)
                    .onTapGesture {
                        //                    isEditing = true
                        isEditing = !isEditing
                    }
                    .animation(.default, value: isEditing)
                    
                }
                .navigationTitle("Activity")
            }
            
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
        } catch {
            print(error.localizedDescription)
        }
        newItem = ""
    }
}
struct ItemCell: View {
    let url: URL
    @Environment(\.dismiss) var dismissKeyboard
    @FocusState private var isEditing: Bool
       
    var body: some View {
        HStack {
            if url.hasDirectoryPath {
                /// フォルダ
                NavigationLink(destination: SubFolder(url: url)) {
                    Image(systemName: "folder")
                    Text(url.lastPathComponent)
                    
                }
//                .onAppear() {
//                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//                }
            } else {
                /// ファイル
                Image(systemName: "doc.text")
                Text(url.lastPathComponent)
            }
        }
//        .onAppear() {
//            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//        }
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
                }
                if let candidate = deleteCandidate {
                    removeItem(atPath: candidate)
                    listOfPath = getFolder(url: URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]))
                    deleteCandidate = nil
                }
            }
        }
        .navigationBarTitle(url.lastPathComponent, displayMode: .inline)
        .onAppear() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
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
