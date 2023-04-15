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
    @State private var isEditingNewName: Bool = false
    @State private var isEditingMode = false
    @State private var selectedItems: Set<URL> = Set<URL>()
    @State private var showingDeleteAlert = false
    var body: some View {
        NavigationView {
            List(selection: $selectedItems){
                ForEach(listOfPath, id: \.self) { url in
                    ItemCell(url: url)
                }
//                    .onDelete { (indexSet) in
//                        if let index = indexSet.first {
//                            let candidate = listOfPath[index]
//                            removeItem(atPath: candidate)
//                            listOfPath = getFolder(url: URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]))
//                        }
//                    }
//                }
                
        
                HStack{
                    Image(systemName: "folder")
                    TextField("New Item", text: $newItem, onCommit: {
                        isEditingNewName = false
                        if newItem != "" {
                            createDirectory()
                        }
                        DispatchQueue.main.async {
                            newItem = "" // テキストフィールドを空にする
                        }
                    })
//                    .focused($isEditingNewName)
                    .keyboardType(.default)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal)
                    .onTapGesture {
                        //                    isEditing = true
                        isEditingNewName = !isEditingNewName
                    }
                    .animation(.default, value: isEditingNewName)

                }
                .navigationTitle("Activity")
            }
            .environment(\.editMode, isEditingMode ? .constant(.active) : .constant(.inactive))
//            .selectionMode(.multiple)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        isEditingMode = !isEditingMode
//                        if !isEditingMode {
//                            selectedItems.removeAll()
//                        }
                        selectedItems.removeAll()
                    }, label: {
                        if isEditingMode {
                            Text("Done")
                        } else {
                            Text("Edit")
                        }
                    })
                
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    if isEditingMode {
                        Button(action: {
//                                        deleteItems()
//                            deleteSelectedItems()
                            showingDeleteAlert = !showingDeleteAlert
                        }, label: {
                            Text("Delete (\(selectedItems.count))")
                        })
                        .alert(isPresented: $showingDeleteAlert) {
                            Alert(title: Text("警告"),
                                  message: Text("\"\("Are you sure you want to delete \(selectedItems.count) items?")\"は削除されます。"),
                                  primaryButton: .cancel(Text("キャンセル")),    // キャンセル用
                                  secondaryButton: .destructive(Text("削除"), action: {deleteSelectedItems()})
                            )   // 破壊的変更用
                        }
                        .disabled(selectedItems.isEmpty)
                        Spacer()
                    }
                    if isEditingMode {
                        Spacer()
                        Button(action: {
//                                        shareSelectedItems()
                        }, label: {
                            Text("Share")
                        })
                        .disabled(selectedItems.isEmpty)
                    }
                }
            }
        }
    }
    func createDirectory() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let directoryURL = documentsDirectory?.appendingPathComponent(newItem, isDirectory: true) else {
            return
        }
        
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            listOfPath.append(directoryURL)
        } catch {
            print("Failed to create directory: \(error.localizedDescription)")
        }
        
        newItem = ""
    }
    func deleteSelectedItems() {
            for item in selectedItems {
//                    do {
//                        try FileManager.default.removeItem(at: item)
//                        listOfPath.removeAll(where: { $0 == item })
//                    } catch {
//                        print("Error deleting item: \(error.localizedDescription)")
//                    }
                removeItem(atPath: item)
                listOfPath = getFolder(url: URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]))
            }
            selectedItems.removeAll()
    }

}
struct ItemCell: View {
    let url: URL
    @Environment(\.dismiss) var dismissKeyboard
    @FocusState private var isEditing: Bool
    @State private var showContextMenu = false
    @State private var rename = ""
    var body: some View {
        HStack {
            if url.hasDirectoryPath {
                /// フォルダ
//                if
                NavigationLink(destination: SubFolder(url: url)) {
                    Image(systemName: "folder")
                    Text(url.lastPathComponent)
                        .contextMenu(menuItems: {
                            Button("Copy", action: {
                                UIPasteboard.general.string = url.lastPathComponent
                            })
//                            Button("Rename", action:{
//                                TextField("New Item", text: $rename, onCommit: {
//                                    isEditing = false
//                                    if rename != "" {
//
//                                    }
//                                    DispatchQueue.main.async {
//                                        rename = "" // テキストフィールドを空にする
//                                    }
//                                })
//                            })
                        })
                        .onLongPressGesture {
                            showContextMenu = true
                        }

                }
            } else {
                /// ファイル
                Image(systemName: "doc.text")
                Text(url.lastPathComponent)
                    .contextMenu(menuItems: {
                        Button("Copy", action: {
                            UIPasteboard.general.string = url.lastPathComponent
                        })
                    })
                    .onLongPressGesture {
                        showContextMenu = true
                    }
            }
        }
    }

}

struct SubFolder: View {
    @State private var showingDeleteAlert = false
    @State var listOfPath: [URL] = []
    @State private var showingDeleteAlertSub = false
//    @State private var deleteCandidate: URL?
    let url: URL
    var body: some View {
        List {
            ForEach(getFolder(url: url), id: \.self) { url in
                ItemCell(url:url)
            }
            .onDelete { (indexSet) in
                if let index = indexSet.first {
                    let candidate = listOfPath[index]
                    removeItem(atPath: candidate)
                    listOfPath = getFolder(url: URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]))
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
        print("\"\(path.lastPathComponent)\"を削除しました")
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
