//
//  RecordView.swift
//  Momentum measurement
//
//  Created by 滝瀬隆斗 on 2023/03/29.
//
import UIKit
import SwiftUI

struct RecordView: View {
    @State private var newItem = ""
    @Binding var listOfPath: [URL]
    @State private var isEditingNewName: Bool = false
    @State private var isEditingMode = false
    @State private var selectedItems: Set<URL> = Set<URL>()
    @State private var showingDeleteAlert = false
    @State private var isSharing = false
    var body: some View {
        NavigationView {
            List(selection: $selectedItems){
                ForEach(listOfPath, id: \.self) { url in
                    ItemCell(url: url)
                }
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
//                       .focused($isEditingNewName)
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
                .animation(.default, value: isEditingMode)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        if isEditingMode {
                            Button(action: {
                                if selectedItems.isEmpty {
                                    selectedItems = Set(listOfPath)
                                }
                                else {
                                    selectedItems = Set<URL>()
                                }
                            }, label: {
                                if selectedItems.isEmpty {
                                    Text("All Select")
                                }
                                else {
                                    Text("All Deselect")
                                }
                            })
                            .disabled(listOfPath.isEmpty)
                        }
                    }
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button(action: {
                            isEditingMode = !isEditingMode
                            selectedItems.removeAll()
                        }, label: {
                            if isEditingMode {
                                Text("Done")
                            } else {
                                Text("Edit")
                            }
                        })
                    }
                    ToolbarItemGroup(placement: .bottomBar) {
                        if isEditingMode {
                            Button(action: {
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
                            Button(action: {
                                shareSelectedItems()
                            }, label: {
                                Text("Share")
                            })
                            .disabled(selectedItems.isEmpty)
                            
                        }
                    }
                }
            }
                .sheet(isPresented: $isSharing) {
                    ShareSheet(items: selectedItems.map { $0 as Any })
                }
    }


    func shareSelectedItems() {
           var itemsToShare = [Any]()

           for item in selectedItems {
               if let files = getAllFiles(from: item) {
                   itemsToShare.append(contentsOf: files)
               } else {
                   itemsToShare.append(item)
               }
           }

           isSharing = true
       }

       func getAllFiles(from directory: URL) -> [URL]? {
           do {
               let fileURLs = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
               var allFiles = [URL]()
               
               for fileURL in fileURLs {
                   if fileURL.hasDirectoryPath {
                       if let files = getAllFiles(from: fileURL) {
                           allFiles.append(contentsOf: files)
                       }
                   } else {
                       allFiles.append(fileURL)
                   }
               }
               
               return allFiles
           } catch {
               print("Error getting files from directory: \(error.localizedDescription)")
               return nil
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
                removeItem(atPath: item)
                listOfPath = updateListOfPath()
            }
            selectedItems.removeAll()
    }

}


struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.excludedActivityTypes = [.postToFacebook, .postToTwitter, .addToReadingList, .postToVimeo]
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
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
//                        .onLongPressGesture {
//                            showContextMenu = true
//                        }

                }
            } else {
                /// ファイル
                Image(systemName: "doc.text")
                Text(url.lastPathComponent)
//                    .contextMenu(menuItems: {
//                        Button("Copy", action: {
//                            UIPasteboard.general.string = url.lastPathComponent
//                        })
//                    })
//                    .onLongPressGesture {
//                        showContextMenu = true
//                    }
            }
        }
    }

}

struct SubFolder: View {
    @State private var showingDeleteAlert = false
    @State var listOfPath: [URL] = []
    @State private var showingDeleteAlertSub = false
    let url: URL
    var body: some View {
        List {
            ForEach(getFolder(url: url), id: \.self) { url in
                ItemCell(url: url)
            }
            .onDelete { (indexSet) in
                let folderItems = getFolder(url: url)
                if let index = indexSet.first {
                    let candidate = folderItems[index]
                    removeItem(atPath: candidate)
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

func updateListOfPath() -> [URL] {
    return getFolder(url: URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]))
}


struct RecordView_Previews: PreviewProvider {
    @State var listOfPath: [URL] = []
    static var previews: some View {
        RecordView(listOfPath: ContentView().$listOfPathOriginal)
    }
}
