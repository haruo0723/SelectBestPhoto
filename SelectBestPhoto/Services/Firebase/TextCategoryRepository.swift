@preconcurrency import FirebaseFirestore
import Foundation

struct PairContext: Equatable {
    var pairId: String
    var userId: String
}

protocol PairContextProviding: Sendable {
    func currentContext() async throws -> PairContext
}

protocol TextCategoryRepository: Sendable {
    func observeCategories(pairId: String, year: Int) -> AsyncThrowingStream<[TextCategory], Error>
    func createCategory(_ category: TextCategory) async throws
    func updateDraftCategory(_ category: TextCategory) async throws
    func confirmCategory(pairId: String, year: Int, categoryId: String) async throws
    func resetCategory(pairId: String, year: Int, categoryId: String) async throws

    func observeCandidates(pairId: String, year: Int, categoryId: String) -> AsyncThrowingStream<[TextCandidate], Error>
    func addCandidate(_ candidate: TextCandidate) async throws
    func updateCandidate(_ candidate: TextCandidate) async throws
    func deleteCandidate(pairId: String, year: Int, categoryId: String, candidateId: String) async throws

    func saveInput(_ input: TextCategoryInput) async throws
    func completeInput(_ input: TextCategoryInput) async throws
    func loadResultContext(pairId: String, year: Int, categoryId: String) async throws -> TextCategoryResultContext
    func saveResultIfNeeded(_ result: TextCategoryResult) async throws
}

struct TextCategoryResultContext: Equatable {
    var category: TextCategory
    var candidates: [TextCandidate]
    var inputs: [TextCategoryInput]
}

enum TextCategoryRepositoryError: Error, Equatable {
    case categoryNotFound
    case pairMembersNotFound
    case cannotModifyConfirmedCategory
    case insufficientCandidates(expected: Int, actual: Int)
    case inputsNotCompleted
    case invalidDocument(String)
}

enum TextCategoryRepositoryPolicy {
    static func validateDraftMutation(category: TextCategory) throws {
        guard category.status == .draft else {
            throw TextCategoryRepositoryError.cannotModifyConfirmedCategory
        }
    }

    static func validateConfirmation(category: TextCategory, candidates: [TextCandidate]) throws {
        try TextCategoryValidator.validate(category: category)
        try TextCategoryValidator.validate(candidates: candidates)
        guard category.status == .draft else {
            throw TextCategoryRepositoryError.cannotModifyConfirmedCategory
        }
        guard candidates.count >= category.settings.inputRankLimit else {
            throw TextCategoryRepositoryError.insufficientCandidates(
                expected: category.settings.inputRankLimit,
                actual: candidates.count
            )
        }
    }

    static func validateCompletedInputs(
        category: TextCategory,
        candidates: [TextCandidate],
        inputs: [TextCategoryInput],
        memberIds: [String]
    ) throws {
        let candidateIds = Set(candidates.map(\.id))
        let inputsByUserId = Dictionary(uniqueKeysWithValues: inputs.map { ($0.userId, $0) })
        for memberId in memberIds {
            guard let input = inputsByUserId[memberId], input.status == .completed else {
                throw TextCategoryRepositoryError.inputsNotCompleted
            }
            try TextCategoryValidator.validate(
                input: input,
                settings: category.settings,
                categoryGeneration: category.generation,
                candidateIds: candidateIds
            )
        }
    }
}

enum TextCategoryFirestorePath {
    static func year(pairId: String, year: Int) -> String {
        "pairs/\(pairId)/years/\(year)"
    }

    static func category(pairId: String, year: Int, categoryId: String) -> String {
        "\(categories(pairId: pairId, year: year))/\(categoryId)"
    }

    static func categories(pairId: String, year: Int) -> String {
        "\(Self.year(pairId: pairId, year: year))/textCategories"
    }

    static func candidates(pairId: String, year: Int, categoryId: String) -> String {
        "\(category(pairId: pairId, year: year, categoryId: categoryId))/candidates"
    }

    static func candidate(pairId: String, year: Int, categoryId: String, candidateId: String) -> String {
        "\(candidates(pairId: pairId, year: year, categoryId: categoryId))/\(candidateId)"
    }

    static func inputs(pairId: String, year: Int, categoryId: String) -> String {
        "\(category(pairId: pairId, year: year, categoryId: categoryId))/inputs"
    }

    static func input(pairId: String, year: Int, categoryId: String, userId: String) -> String {
        "\(inputs(pairId: pairId, year: year, categoryId: categoryId))/\(userId)"
    }

    static func results(pairId: String, year: Int, categoryId: String) -> String {
        "\(category(pairId: pairId, year: year, categoryId: categoryId))/results"
    }

    static func result(pairId: String, year: Int, categoryId: String, resultId: String) -> String {
        "\(results(pairId: pairId, year: year, categoryId: categoryId))/\(resultId)"
    }
}

final class FirestoreTextCategoryRepository: TextCategoryRepository, @unchecked Sendable {
    private let db: Firestore
    private let now: @Sendable () -> Date

    init(db: Firestore = Firestore.firestore(), now: @escaping @Sendable () -> Date = Date.init) {
        self.db = db
        self.now = now
    }

    func observeCategories(pairId: String, year: Int) -> AsyncThrowingStream<[TextCategory], Error> {
        AsyncThrowingStream { continuation in
            let registration = categoriesRef(pairId: pairId, year: year)
                .order(by: "updatedAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    do {
                        let categories = try snapshot?.documents.map(Self.decodeCategory) ?? []
                        continuation.yield(categories)
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            continuation.onTermination = { _ in registration.remove() }
        }
    }

    func createCategory(_ category: TextCategory) async throws {
        try TextCategoryValidator.validate(category: category)
        try await categoryRef(pairId: category.pairId, year: category.year, categoryId: category.id)
            .setData(Self.encodeCategory(category))
    }

    func updateDraftCategory(_ category: TextCategory) async throws {
        try TextCategoryValidator.validate(category: category)
        let current = try await loadCategory(pairId: category.pairId, year: category.year, categoryId: category.id)
        try TextCategoryRepositoryPolicy.validateDraftMutation(category: current)
        try await categoryRef(pairId: category.pairId, year: category.year, categoryId: category.id)
            .setData(Self.encodeCategory(category), merge: true)
    }

    func confirmCategory(pairId: String, year: Int, categoryId: String) async throws {
        let category = try await loadCategory(pairId: pairId, year: year, categoryId: categoryId)
        let candidates = try await loadCandidates(pairId: pairId, year: year, categoryId: categoryId)
        try TextCategoryRepositoryPolicy.validateConfirmation(category: category, candidates: candidates)
        try await categoryRef(pairId: pairId, year: year, categoryId: categoryId).updateData([
            "status": TextCategoryStatus.confirmed.rawValue,
            "confirmedAt": now(),
            "updatedAt": now(),
        ])
    }

    func resetCategory(pairId: String, year: Int, categoryId: String) async throws {
        let category = try await loadCategory(pairId: pairId, year: year, categoryId: categoryId)
        let batch = db.batch()
        let categoryReference = categoryRef(pairId: pairId, year: year, categoryId: categoryId)

        let inputs = try await inputsRef(pairId: pairId, year: year, categoryId: categoryId).getDocuments()
        for document in inputs.documents {
            batch.deleteDocument(document.reference)
        }

        let results = try await resultsRef(pairId: pairId, year: year, categoryId: categoryId).getDocuments()
        for document in results.documents {
            batch.deleteDocument(document.reference)
        }

        batch.updateData([
            "status": TextCategoryStatus.draft.rawValue,
            "generation": category.generation + 1,
            "confirmedAt": FieldValue.delete(),
            "updatedAt": now(),
        ], forDocument: categoryReference)
        try await batch.commit()
    }

    func observeCandidates(pairId: String, year: Int, categoryId: String) -> AsyncThrowingStream<[TextCandidate], Error> {
        AsyncThrowingStream { continuation in
            let registration = candidatesRef(pairId: pairId, year: year, categoryId: categoryId)
                .order(by: "createdAt")
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    do {
                        let candidates = try snapshot?.documents.map(Self.decodeCandidate) ?? []
                        continuation.yield(candidates)
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            continuation.onTermination = { _ in registration.remove() }
        }
    }

    func addCandidate(_ candidate: TextCandidate) async throws {
        try TextCategoryValidator.validate(candidate: candidate)
        let category = try await loadCategory(
            pairId: candidate.pairId,
            year: candidate.year,
            categoryId: candidate.categoryId
        )
        try TextCategoryRepositoryPolicy.validateDraftMutation(category: category)
        let reference = candidate.id.isEmpty
            ? candidatesRef(pairId: candidate.pairId, year: candidate.year, categoryId: candidate.categoryId).document()
            : candidateRef(
                pairId: candidate.pairId,
                year: candidate.year,
                categoryId: candidate.categoryId,
                candidateId: candidate.id
            )
        var storedCandidate = candidate
        storedCandidate.id = reference.documentID
        try await reference.setData(Self.encodeCandidate(storedCandidate))
    }

    func updateCandidate(_ candidate: TextCandidate) async throws {
        try TextCategoryValidator.validate(candidate: candidate)
        let category = try await loadCategory(
            pairId: candidate.pairId,
            year: candidate.year,
            categoryId: candidate.categoryId
        )
        try TextCategoryRepositoryPolicy.validateDraftMutation(category: category)
        try await candidateRef(
            pairId: candidate.pairId,
            year: candidate.year,
            categoryId: candidate.categoryId,
            candidateId: candidate.id
        ).setData(Self.encodeCandidate(candidate), merge: true)
    }

    func deleteCandidate(pairId: String, year: Int, categoryId: String, candidateId: String) async throws {
        let category = try await loadCategory(pairId: pairId, year: year, categoryId: categoryId)
        try TextCategoryRepositoryPolicy.validateDraftMutation(category: category)
        try await candidateRef(pairId: pairId, year: year, categoryId: categoryId, candidateId: candidateId).delete()
    }

    func saveInput(_ input: TextCategoryInput) async throws {
        let category = try await loadCategory(pairId: input.pairId, year: input.year, categoryId: input.categoryId)
        let candidates = try await loadCandidates(pairId: input.pairId, year: input.year, categoryId: input.categoryId)
        try TextCategoryValidator.validate(
            input: input,
            settings: category.settings,
            categoryGeneration: category.generation,
            candidateIds: Set(candidates.map(\.id))
        )
        var savedInput = input
        savedInput.status = input.status == .completed ? .completed : .inProgress
        savedInput.completedAt = input.status == .completed ? (input.completedAt ?? now()) : nil
        savedInput.updatedAt = now()
        try await inputRef(pairId: input.pairId, year: input.year, categoryId: input.categoryId, userId: input.userId)
            .setData(Self.encodeInput(savedInput), merge: true)
    }

    func completeInput(_ input: TextCategoryInput) async throws {
        var completedInput = input
        completedInput.status = .completed
        completedInput.completedAt = input.completedAt ?? now()
        completedInput.updatedAt = now()
        try await saveInput(completedInput)
    }

    func loadResultContext(pairId: String, year: Int, categoryId: String) async throws -> TextCategoryResultContext {
        let category = try await loadCategory(pairId: pairId, year: year, categoryId: categoryId)
        let candidates = try await loadCandidates(pairId: pairId, year: year, categoryId: categoryId)
        let inputs = try await loadInputs(pairId: pairId, year: year, categoryId: categoryId)
        let memberIds = try await loadMemberIds(pairId: pairId)
        try TextCategoryRepositoryPolicy.validateCompletedInputs(
            category: category,
            candidates: candidates,
            inputs: inputs,
            memberIds: memberIds
        )
        return TextCategoryResultContext(category: category, candidates: candidates, inputs: inputs)
    }

    func saveResultIfNeeded(_ result: TextCategoryResult) async throws {
        let reference = resultRef(
            pairId: result.pairId,
            year: result.year,
            categoryId: result.categoryId,
            resultId: result.id
        )
        let existing = try await reference.getDocument()
        if existing.exists {
            let savedResult = try Self.decodeResult(existing)
            if savedResult.generation == result.generation {
                return
            }
        }
        try await reference.setData(Self.encodeResult(result))
        try await categoryRef(pairId: result.pairId, year: result.year, categoryId: result.categoryId).updateData([
            "status": TextCategoryStatus.resultAvailable.rawValue,
            "updatedAt": now(),
        ])
    }

    private func loadMemberIds(pairId: String) async throws -> [String] {
        let document = try await db.document("pairs/\(pairId)").getDocument()
        guard let memberIds = document.data()?["memberIds"] as? [String], !memberIds.isEmpty else {
            throw TextCategoryRepositoryError.pairMembersNotFound
        }
        return memberIds
    }

    private func loadCategory(pairId: String, year: Int, categoryId: String) async throws -> TextCategory {
        let document = try await categoryRef(pairId: pairId, year: year, categoryId: categoryId).getDocument()
        guard document.exists else {
            throw TextCategoryRepositoryError.categoryNotFound
        }
        return try Self.decodeCategory(document)
    }

    private func loadCandidates(pairId: String, year: Int, categoryId: String) async throws -> [TextCandidate] {
        let snapshot = try await candidatesRef(pairId: pairId, year: year, categoryId: categoryId)
            .order(by: "createdAt")
            .getDocuments()
        return try snapshot.documents.map(Self.decodeCandidate)
    }

    private func loadInputs(pairId: String, year: Int, categoryId: String) async throws -> [TextCategoryInput] {
        let snapshot = try await inputsRef(pairId: pairId, year: year, categoryId: categoryId).getDocuments()
        return try snapshot.documents.map(Self.decodeInput)
    }

    private func categoriesRef(pairId: String, year: Int) -> CollectionReference {
        db.collection(TextCategoryFirestorePath.categories(pairId: pairId, year: year))
    }

    private func categoryRef(pairId: String, year: Int, categoryId: String) -> DocumentReference {
        db.document(TextCategoryFirestorePath.category(pairId: pairId, year: year, categoryId: categoryId))
    }

    private func candidatesRef(pairId: String, year: Int, categoryId: String) -> CollectionReference {
        db.collection(TextCategoryFirestorePath.candidates(pairId: pairId, year: year, categoryId: categoryId))
    }

    private func candidateRef(pairId: String, year: Int, categoryId: String, candidateId: String) -> DocumentReference {
        db.document(TextCategoryFirestorePath.candidate(
            pairId: pairId,
            year: year,
            categoryId: categoryId,
            candidateId: candidateId
        ))
    }

    private func inputsRef(pairId: String, year: Int, categoryId: String) -> CollectionReference {
        db.collection(TextCategoryFirestorePath.inputs(pairId: pairId, year: year, categoryId: categoryId))
    }

    private func inputRef(pairId: String, year: Int, categoryId: String, userId: String) -> DocumentReference {
        db.document(TextCategoryFirestorePath.input(pairId: pairId, year: year, categoryId: categoryId, userId: userId))
    }

    private func resultsRef(pairId: String, year: Int, categoryId: String) -> CollectionReference {
        db.collection(TextCategoryFirestorePath.results(pairId: pairId, year: year, categoryId: categoryId))
    }

    private func resultRef(pairId: String, year: Int, categoryId: String, resultId: String) -> DocumentReference {
        db.document(TextCategoryFirestorePath.result(
            pairId: pairId,
            year: year,
            categoryId: categoryId,
            resultId: resultId
        ))
    }
}

private extension FirestoreTextCategoryRepository {
    static func encodeCategory(_ category: TextCategory) -> [String: Any] {
        var data: [String: Any] = [
            "pairId": category.pairId,
            "year": category.year,
            "name": category.name,
            "status": category.status.rawValue,
            "inputRankLimit": category.settings.inputRankLimit,
            "revealRankLimit": category.settings.revealRankLimit,
            "pointsByRank": category.settings.pointsByRank.map(encodeRankPoint),
            "generation": category.generation,
            "createdByUserId": category.createdByUserId,
            "createdAt": category.createdAt,
            "updatedAt": category.updatedAt,
        ]
        if let confirmedAt = category.confirmedAt {
            data["confirmedAt"] = confirmedAt
        }
        return data
    }

    static func decodeCategory(_ document: DocumentSnapshot) throws -> TextCategory {
        let data = try documentData(document)
        guard
            let pairId = data["pairId"] as? String,
            let year = data["year"] as? Int,
            let name = data["name"] as? String,
            let statusValue = data["status"] as? String,
            let status = TextCategoryStatus(rawValue: statusValue),
            let inputRankLimit = data["inputRankLimit"] as? Int,
            let revealRankLimit = data["revealRankLimit"] as? Int,
            let pointsData = data["pointsByRank"] as? [[String: Any]],
            let generation = data["generation"] as? Int,
            let createdByUserId = data["createdByUserId"] as? String
        else {
            throw TextCategoryRepositoryError.invalidDocument(document.reference.path)
        }

        return try TextCategory(
            id: document.documentID,
            pairId: pairId,
            year: year,
            name: name,
            status: status,
            settings: TextCategorySettings(
                inputRankLimit: inputRankLimit,
                revealRankLimit: revealRankLimit,
                pointsByRank: pointsData.map(decodeRankPoint)
            ),
            generation: generation,
            createdByUserId: createdByUserId,
            confirmedAt: optionalDate(data["confirmedAt"], path: document.reference.path),
            createdAt: requiredDate(data["createdAt"], path: document.reference.path),
            updatedAt: requiredDate(data["updatedAt"], path: document.reference.path)
        )
    }

    static func encodeCandidate(_ candidate: TextCandidate) -> [String: Any] {
        [
            "pairId": candidate.pairId,
            "year": candidate.year,
            "categoryId": candidate.categoryId,
            "name": candidate.name,
            "imagePlaceholderKind": candidate.imagePlaceholderKind.rawValue,
            "createdByUserId": candidate.createdByUserId,
            "createdAt": candidate.createdAt,
            "updatedAt": candidate.updatedAt,
        ]
    }

    static func decodeCandidate(_ document: DocumentSnapshot) throws -> TextCandidate {
        let data = try documentData(document)
        guard
            let pairId = data["pairId"] as? String,
            let year = data["year"] as? Int,
            let categoryId = data["categoryId"] as? String,
            let name = data["name"] as? String,
            let imagePlaceholderValue = data["imagePlaceholderKind"] as? String,
            let imagePlaceholderKind = TextCandidateImagePlaceholderKind(rawValue: imagePlaceholderValue),
            let createdByUserId = data["createdByUserId"] as? String
        else {
            throw TextCategoryRepositoryError.invalidDocument(document.reference.path)
        }

        return try TextCandidate(
            id: document.documentID,
            pairId: pairId,
            year: year,
            categoryId: categoryId,
            name: name,
            imagePlaceholderKind: imagePlaceholderKind,
            createdByUserId: createdByUserId,
            createdAt: requiredDate(data["createdAt"], path: document.reference.path),
            updatedAt: requiredDate(data["updatedAt"], path: document.reference.path)
        )
    }

    static func encodeInput(_ input: TextCategoryInput) -> [String: Any] {
        var data: [String: Any] = [
            "pairId": input.pairId,
            "year": input.year,
            "categoryId": input.categoryId,
            "userId": input.userId,
            "generation": input.generation,
            "status": input.status.rawValue,
            "selections": input.selections.map(encodeSelection),
            "updatedAt": input.updatedAt,
        ]
        if let completedAt = input.completedAt {
            data["completedAt"] = completedAt
        }
        return data
    }

    static func decodeInput(_ document: DocumentSnapshot) throws -> TextCategoryInput {
        let data = try documentData(document)
        guard
            let pairId = data["pairId"] as? String,
            let year = data["year"] as? Int,
            let categoryId = data["categoryId"] as? String,
            let userId = data["userId"] as? String,
            let generation = data["generation"] as? Int,
            let statusValue = data["status"] as? String,
            let status = InputStatus(rawValue: statusValue),
            let selectionsData = data["selections"] as? [[String: Any]]
        else {
            throw TextCategoryRepositoryError.invalidDocument(document.reference.path)
        }

        return try TextCategoryInput(
            id: document.documentID,
            pairId: pairId,
            year: year,
            categoryId: categoryId,
            userId: userId,
            generation: generation,
            status: status,
            selections: selectionsData.map(decodeSelection),
            completedAt: optionalDate(data["completedAt"], path: document.reference.path),
            updatedAt: requiredDate(data["updatedAt"], path: document.reference.path)
        )
    }

    static func encodeResult(_ result: TextCategoryResult) -> [String: Any] {
        [
            "pairId": result.pairId,
            "year": result.year,
            "categoryId": result.categoryId,
            "generation": result.generation,
            "entries": result.entries.map(encodeResultEntry),
            "sourceUserIds": result.sourceUserIds,
            "createdAt": result.createdAt,
        ]
    }

    static func decodeResult(_ document: DocumentSnapshot) throws -> TextCategoryResult {
        let data = try documentData(document)
        guard
            let pairId = data["pairId"] as? String,
            let year = data["year"] as? Int,
            let categoryId = data["categoryId"] as? String,
            let generation = data["generation"] as? Int,
            let entriesData = data["entries"] as? [[String: Any]],
            let sourceUserIds = data["sourceUserIds"] as? [String]
        else {
            throw TextCategoryRepositoryError.invalidDocument(document.reference.path)
        }

        return try TextCategoryResult(
            id: document.documentID,
            pairId: pairId,
            year: year,
            categoryId: categoryId,
            generation: generation,
            entries: entriesData.map(decodeResultEntry),
            sourceUserIds: sourceUserIds,
            createdAt: requiredDate(data["createdAt"], path: document.reference.path)
        )
    }

    static func encodeRankPoint(_ point: RankPoint) -> [String: Any] {
        ["rank": point.rank, "points": point.points]
    }

    static func decodeRankPoint(_ data: [String: Any]) throws -> RankPoint {
        guard let rank = data["rank"] as? Int, let points = data["points"] as? Int else {
            throw TextCategoryRepositoryError.invalidDocument("pointsByRank")
        }
        return RankPoint(rank: rank, points: points)
    }

    static func encodeSelection(_ selection: RankedTextSelection) -> [String: Any] {
        ["rank": selection.rank, "candidateId": selection.candidateId]
    }

    static func decodeSelection(_ data: [String: Any]) throws -> RankedTextSelection {
        guard let rank = data["rank"] as? Int, let candidateId = data["candidateId"] as? String else {
            throw TextCategoryRepositoryError.invalidDocument("selections")
        }
        return RankedTextSelection(rank: rank, candidateId: candidateId)
    }

    static func encodeResultEntry(_ entry: TextCategoryResultEntry) -> [String: Any] {
        [
            "rank": entry.rank,
            "candidateId": entry.candidateId,
            "candidateName": entry.candidateName,
            "totalPoints": entry.totalPoints,
            "userBreakdowns": entry.userBreakdowns.map(encodeUserBreakdown),
            "imagePlaceholderKind": entry.imagePlaceholderKind.rawValue,
        ]
    }

    static func decodeResultEntry(_ data: [String: Any]) throws -> TextCategoryResultEntry {
        guard
            let rank = data["rank"] as? Int,
            let candidateId = data["candidateId"] as? String,
            let candidateName = data["candidateName"] as? String,
            let totalPoints = data["totalPoints"] as? Int,
            let userBreakdownsData = data["userBreakdowns"] as? [[String: Any]],
            let imagePlaceholderValue = data["imagePlaceholderKind"] as? String,
            let imagePlaceholderKind = TextCandidateImagePlaceholderKind(rawValue: imagePlaceholderValue)
        else {
            throw TextCategoryRepositoryError.invalidDocument("entries")
        }
        return try TextCategoryResultEntry(
            id: candidateId,
            rank: rank,
            candidateId: candidateId,
            candidateName: candidateName,
            totalPoints: totalPoints,
            userBreakdowns: userBreakdownsData.map(decodeUserBreakdown),
            imagePlaceholderKind: imagePlaceholderKind
        )
    }

    static func encodeUserBreakdown(_ breakdown: TextCategoryUserPointBreakdown) -> [String: Any] {
        var data: [String: Any] = [
            "userId": breakdown.userId,
            "points": breakdown.points,
        ]
        if let selectedRank = breakdown.selectedRank {
            data["selectedRank"] = selectedRank
        }
        return data
    }

    static func decodeUserBreakdown(_ data: [String: Any]) throws -> TextCategoryUserPointBreakdown {
        guard let userId = data["userId"] as? String, let points = data["points"] as? Int else {
            throw TextCategoryRepositoryError.invalidDocument("userBreakdowns")
        }
        return TextCategoryUserPointBreakdown(
            userId: userId,
            selectedRank: data["selectedRank"] as? Int,
            points: points
        )
    }

    static func documentData(_ document: DocumentSnapshot) throws -> [String: Any] {
        guard let data = document.data() else {
            throw TextCategoryRepositoryError.invalidDocument(document.reference.path)
        }
        return data
    }

    static func requiredDate(_ value: Any?, path: String) throws -> Date {
        if let date = value as? Date {
            return date
        }
        if let timestamp = value as? Timestamp {
            return timestamp.dateValue()
        }
        throw TextCategoryRepositoryError.invalidDocument(path)
    }

    static func optionalDate(_ value: Any?, path: String) throws -> Date? {
        guard let value else {
            return nil
        }
        return try requiredDate(value, path: path)
    }
}
