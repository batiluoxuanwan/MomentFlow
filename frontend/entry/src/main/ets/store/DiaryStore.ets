import { Diary } from '../model/Diary'


class DiaryStore {
  diaries: Diary[] = []

  addDiary(diary: Diary) {
    this.diaries.unshift(diary)
    // 关键：存入全局存储，触发 UI 自动刷新
    AppStorage.setOrCreate('diaries', [...this.diaries])
  }

  updateDiary(updated: Diary) {
    const index = this.diaries.findIndex(d => d.id === updated.id)
    if (index !== -1) {
      this.diaries[index] = updated
    }
    // 关键：同步更新
    AppStorage.setOrCreate('diaries', [...this.diaries])
  }

  deleteDiary(id: number) {
    this.diaries = this.diaries.filter(d => d.id !== id)
    // 关键：同步更新
    AppStorage.setOrCreate('diaries', [...this.diaries])
  }

  getDiaryById(id: number): Diary | undefined {
    return this.diaries.find(d => d.id === id)
  }
}

export const diaryStore = new DiaryStore()
