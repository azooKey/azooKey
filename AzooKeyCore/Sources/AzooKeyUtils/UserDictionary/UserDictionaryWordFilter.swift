public enum UserDictionaryWordFilter {
    /// denylistに含まれない場合、Variation Selectorを含む元の表記を返す。
    public static func filter(_ word: String, denylist: Set<String>) -> String? {
        // Variation Selectorの有無にかかわらず同じ文字をdenylistで除外する
        let denylistCheckTarget = String(word.unicodeScalars.filter { $0.value != 0xFE0F })
        guard denylistCheckTarget.allSatisfy({ !denylist.contains(String($0)) }) else {
            return nil
        }
        return word
    }
}
