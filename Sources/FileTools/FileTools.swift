import Foundation
import Alamofire

public struct FileTools {
    public static let defaultUrl = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL).appendingPathComponent("FileTools")
    
    private static let manager = FileManager.default
    private static let queue = DispatchQueue(label: "com.file.tools")
    
    /// get file list
    /// - Parameters:
    ///   - url: url
    ///   - completed: call back
    public static func getFiles(url: URL = Self.defaultUrl, completed: @escaping ([FileBase]) -> Void) {
        if self.isExist(path: url.path) {
            self.create(name: "", baseUrl: url)
        }
        self.queue.async {
            var contents = [String]()
            do {
                let cont = try? manager.contentsOfDirectory(atPath: url.path)
                if let cont {
                    contents.append(contentsOf: cont)
                }
            }
            
            var files = contents.map { name in
                return getFileModel(url: url, name: name)
            }
            
            files = files.sorted(by: {
                $0.date > $1.date
            })
            completed(files)
        }
    }
    
    static func getFileModel(url: URL, name: String) -> FileBase {
        let childUrl = url.appendingPathComponent(name)
        let att = getFileInfo(url: url, name: name)
        return FileBase(url: childUrl, size: att.size, date: att.date)
    }
    
    static func getFileInfo(url: URL, name: String) -> (date: TimeInterval, size: Double) {
        let fileUrl = url.appendingPathComponent(name)
        do {
            let attributes = try? manager.attributesOfItem(atPath: fileUrl.path)
            let date = attributes![FileAttributeKey.creationDate] as! Date
            let size = attributes![FileAttributeKey.size] as! Double
            return (date.timeIntervalSince1970, size)
        }
    }
    
    /// Determine whether the path exists
    /// - Parameter path: path
    /// - Returns: is exists
    public static func isExist(path: String) -> Bool {
        return manager.fileExists(atPath: path)
    }
    
    /// Determine whether the path is a folder
    /// - Parameter path: path
    /// - Returns: is folder
    public static func isFolder(path: String) -> Bool {
        var directoryExist = ObjCBool.init(false)
        let fileExist = manager.fileExists(atPath: path, isDirectory: &directoryExist)
        return fileExist && directoryExist.boolValue
    }
    
    @discardableResult
    /// Create file/folder
    /// - Parameters:
    ///   - name: file/folder name
    ///   - baseUrl: url
    ///   - isAutoName: is auto name
    /// - Returns: is success
    public static func create(name: String, baseUrl: URL, isAutoName: Bool = false) -> Bool {
        let folder = baseUrl.appendingPathComponent(name, isDirectory: true)
        let exist = manager.fileExists(atPath: folder.path)
        if !exist {
            do {
                try manager.createDirectory(at: folder, withIntermediateDirectories: true)
                return true
            } catch {
                
            }
        } else if exist && isAutoName {
            var i = 1
            var folderName = name + "(\(i))"
            while self.isExist(path: baseUrl.appendingPathComponent(folderName).path) {
                i += 1
                folderName = name + "(\(i))"
            }
            do {
                try manager.createDirectory(at: baseUrl.appendingPathComponent(folderName), withIntermediateDirectories: true)
                return true
            } catch {}
        }
        return false
    }
    
    @discardableResult
    /// delete file/folder
    /// - Parameters:
    ///   - name: file/folder name
    ///   - baseUrl: base url
    /// - Returns: is success
    public static func delete(name: String, baseUrl: URL = Self.defaultUrl) -> Bool {
        let path = baseUrl.appendingPathComponent(name)
        guard self.isExist(path: path.path) else {
            return false
        }
        do {
            try manager.removeItem(at: path)
            return true
        } catch {
            return false
        }
    }
    
    @discardableResult
    /// move file/folder
    /// - Parameters:
    ///   - oldPath: old url
    ///   - newPath: old url
    /// - Returns: is success
    public static func move(oldUrl: URL, newUrl: URL) -> Bool {
        if self.isExist(path: newUrl.path) {
            self.delete(name: "", baseUrl: newUrl)
        }
        do {
            try manager.copyItem(at: oldUrl, to: newUrl)
            try manager.removeItem(at: oldUrl)
            return true
        } catch {
            return false
        }
    }
    
    @discardableResult
    /// rename file/folder name
    /// - Parameters:
    ///   - oldName: old name
    ///   - newName: new name
    ///   - baseUrl: base url
    /// - Returns: is success
    public static func rename(oldName: String, newName: String, baseUrl: URL) -> Bool {
        let old = baseUrl.appendingPathComponent(oldName)
        let new = baseUrl.appendingPathComponent(newName)
        if self.isFolder(path: old.path) {
            do {
                try manager.createDirectory(at: new, withIntermediateDirectories: true)
                let dirEnum = manager.enumerator(atPath: old.path)
                while let path = dirEnum?.nextObject() as? String {
                    try manager.moveItem(at: old.appendingPathComponent(path), to: new.appendingPathComponent(path))
                }
                try manager.removeItem(at: old)
                return true
            } catch {
                return false
            }
        } else {
            do {
                try manager.moveItem(at: old, to: new)
                return true
            } catch {
                return false
            }
        }
    }
    
    
    /// download file
    /// - Parameters:
    ///   - netUrl: net url
    ///   - localUrl: local url
    ///   - fileName: file name
    ///   - isAutoName: is auto name
    ///   - success: success call back
    ///   - failure: failure call back
    public static func download(netUrl: URL?, localUrl: URL, fileName: String, isAutoName: Bool = false, success: @escaping (Bool) -> Void, failure: @escaping (Error?) -> Void) {
        guard netUrl != nil else {
            failure(nil)
            return
        }
        var path = localUrl.appendingPathComponent(fileName)
        let pathExtension = fileName.pathExtension
        let name = fileName.deletePathExtension
        if isAutoName {
            var number = 0
            while self.isExist(path: path.path) {
                number += 1
                path = localUrl.appendingPathComponent(name + "(\(number))").appendingPathExtension(pathExtension)
            }
        } else {
            if self.isExist(path: path.path) {
                self.delete(name: "", baseUrl: path)
            }
        }
        
        let destination: DownloadRequest.Destination = { _, _ in
            return (path, [.removePreviousFile, .createIntermediateDirectories])
        }
        let request = URLRequest(url: netUrl!)
        AF.download(request, to: destination).response { response in
            if response.error != nil {
                failure(response.error)
            } else {
                success(true)
            }
        }
    }
}

@available(iOS 13.0, *)
extension FileTools {
    
    /// get file list
    /// - Parameter url: url
    /// - Returns: FileBase list
    public static func getFiles(url: URL = Self.defaultUrl) async -> [FileBase] {
        await withCheckedContinuation({ result in
            self.getFiles(url: url) { models in
                result.resume(returning: models)
            }
        })
    }
    
    /// download url file
    /// - Parameters:
    ///   - netUrl: net file
    ///   - localUrl: local url
    ///   - fileName: file name
    ///   - isAutoName: is auto name
    /// - Returns: result
    public static func download(netUrl: URL?, localUrl: URL, fileName: String, isAutoName: Bool = false) async -> (success: Bool, error: Error?) {
        await withCheckedContinuation({ result in
            download(netUrl: netUrl, localUrl: localUrl, fileName: fileName, isAutoName: isAutoName) { isSuccess in
                result.resume(returning: (isSuccess, nil))
            } failure: { error in
                result.resume(returning: (false, error))
            }
        })
    }
}
