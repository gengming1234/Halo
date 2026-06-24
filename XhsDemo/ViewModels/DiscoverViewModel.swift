import Foundation
import Combine

final class DiscoverViewModel {

    // MARK: - 数据状态
    @Published private(set) var notes: [Note] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String? = nil

    let categories: [String] = ["推荐", "穿搭", "美食", "彩妆", "影视", "职场", "运动", "游戏"]
    private(set) var currentCategoryIndex: Int = 0

    // MARK: - 输入
    func loadNotes(for categoryIndex: Int = 0) {
        guard !isLoading else { return }
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            do {
                let allNotes = try NoteService.loadNotesFromBundle(jsonName: "xiaohongshu")
                let filtered = self.filterNotes(allNotes, for: categoryIndex)
                DispatchQueue.main.async {
                    self.notes = filtered
                    self.isLoading = false
                    self.errorMessage = nil
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func selectCategory(at index: Int) {
        guard index != currentCategoryIndex else { return }
        currentCategoryIndex = index
        loadNotes(for: index)
    }

    func moveNote(from sourceIndex: Int, to destinationIndex: Int) {
        var mutable = notes
        let moved = mutable.remove(at: sourceIndex)
        mutable.insert(moved, at: destinationIndex)
        notes = mutable
    }

    func note(at index: Int) -> Note {
        return notes[index]
    }

    // MARK: - 私有
    private func filterNotes(_ notes: [Note], for categoryIndex: Int) -> [Note] {
        switch categoryIndex {
        case 0:  return notes
        case 1:  return notes.filter { $0.title.contains("穿搭") || $0.title.contains("搭配") }
        case 2:  return notes.filter { $0.title.contains("美食") || $0.title.contains("好吃") }
        case 3:  return notes.filter { $0.title.contains("彩妆") || $0.title.contains("化妆") }
        default: return notes
        }
    }
}
