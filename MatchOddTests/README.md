# MatchOdd Unit Tests

## 測試結構

```
MatchOddTests/
├── Mocks/
│   ├── MockMatchRepository.swift        # Repository 的 Mock 實作
│   └── MockOddsStreamManager.swift      # OddsStreamManager 的 Mock 實作
├── ViewModels/
│   └── MatchListViewModelTests.swift    # ViewModel 測試用例
└── README.md                             # 本文件
```

## Mock 對象說明

### MockMatchRepository

模擬 `MatchRepositoryProtocol` 的實作，用於測試 ViewModel 的數據加載邏輯。

**功能**：
- 可配置返回的 matches 和 odds 數據
- 可配置拋出的錯誤
- 可模擬網路延遲
- 追蹤方法調用次數

**使用範例**：
```swift
let mockRepo = MockMatchRepository()
mockRepo.matchesToReturn = MockMatchRepository.createSampleMatches()
mockRepo.oddsToReturn = MockMatchRepository.createSampleOdds()
mockRepo.delay = 0.1  // 模擬 100ms 延遲
```

### MockOddsStreamManager

模擬 `OddsStreamManagerProtocol` 的實作，用於測試實時賠率更新。

**功能**：
- 手動控制賠率更新的發送
- 追蹤 streaming 狀態
- 追蹤方法調用次數

**使用範例**：
```swift
let mockStream = MockOddsStreamManager()
let update = MockOddsStreamManager.createSampleUpdate(
    matchID: 1,
    teamAOdds: 1.8
)
mockStream.emitUpdate(update)
```

## MatchListViewModel 測試用例

### 數據加載測試
- ✅ `testLoadInitialDataSuccess` - 成功加載初始數據
- ✅ `testLoadInitialDataFetchMatchesError` - 處理 matches 加載錯誤
- ✅ `testLoadInitialDataFetchOddsError` - 處理 odds 加載錯誤
- ✅ `testLoadingStateChanges` - 驗證 loading 狀態變化

### 賠率更新測試
- ✅ `testHandleOddsUpdate` - 處理實時賠率更新
- ✅ `testOddsChangeFlags` - 驗證賠率變化標記
- ✅ `testOddsChangeFlagsReset` - 驗證變化標記自動重置
- ✅ `testMultipleOddsUpdates` - 處理多個賠率更新

### 排序測試
- ✅ `testLiveMatchesSortedFirst` - LIVE 比賽優先排序

### 錯誤處理測試
- ✅ `testErrorClearedOnSuccess` - 錯誤狀態在成功後清除

### 邊界情況測試
- ✅ `testEmptyDataHandling` - 處理空數據


## 測試覆蓋率

測試覆蓋了 MatchListViewModel 的核心功能：
- ✅ 數據加載流程
- ✅ 錯誤處理
- ✅ Loading 狀態管理
- ✅ 實時賠率更新
- ✅ 賠率變化動畫標記
- ✅ 數據排序邏輯
- ✅ 邊界情況處理



