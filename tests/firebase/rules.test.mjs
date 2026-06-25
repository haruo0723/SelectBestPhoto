import assert from "node:assert/strict";
import { after, beforeEach, test } from "node:test";
import { readFileSync } from "node:fs";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment
} from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc, Timestamp } from "firebase/firestore";
import { ref, uploadString } from "firebase/storage";

const projectId = "demo-select-best-photo";
const pairId = "pair-a";
const year = 2026;
const categoryId = "category-a";
const resultId = "category-a-generation-0";

const testEnv = await initializeTestEnvironment({
  projectId,
  firestore: {
    rules: readFileSync("firestore.rules", "utf8"),
    host: "127.0.0.1",
    port: 8080
  },
  storage: {
    rules: readFileSync("storage.rules", "utf8"),
    host: "127.0.0.1",
    port: 9199
  }
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await seedCategory();
});

test("Firestore rules allow pair members to read categories and deny outsiders", async () => {
  const memberDb = testEnv.authenticatedContext("user-a").firestore();
  const outsiderDb = testEnv.authenticatedContext("user-x").firestore();

  await assertSucceeds(getDoc(categoryRef(memberDb)));
  await assertFails(getDoc(categoryRef(outsiderDb)));
  await assertFails(setDoc(categoryRef(outsiderDb), categoryData()));
});

test("Firestore rules allow candidate writes only while the category is draft", async () => {
  const memberDb = testEnv.authenticatedContext("user-a").firestore();

  await assertSucceeds(setDoc(candidateRef(memberDb, "candidate-a"), candidateData("candidate-a")));
  await seedConfirmedCategory();
  await assertFails(setDoc(candidateRef(memberDb, "candidate-b"), candidateData("candidate-b")));
});

test("Firestore rules allow users to write only their own input", async () => {
  const userADb = testEnv.authenticatedContext("user-a").firestore();

  await assertSucceeds(setDoc(inputRef(userADb, "user-a"), inputData("user-a", "candidate-a", "inProgress")));
  await assertFails(setDoc(inputRef(userADb, "user-b"), inputData("user-b", "candidate-a", "inProgress")));
});

test("Firestore rules hide partner input and results until both inputs are completed", async () => {
  await seedCandidate("candidate-a");
  await seedInput("user-a", "candidate-a", "completed");
  await seedInput("user-b", "candidate-a", "inProgress");
  await seedResult();
  const userADb = testEnv.authenticatedContext("user-a").firestore();

  await assertSucceeds(getDoc(inputRef(userADb, "user-a")));
  await assertFails(getDoc(inputRef(userADb, "user-b")));
  await assertFails(getDoc(resultRef(userADb)));

  await seedInput("user-b", "candidate-a", "completed");

  await assertSucceeds(getDoc(inputRef(userADb, "user-b")));
  await assertSucceeds(getDoc(resultRef(userADb)));
});

test("Storage rules keep MVP media access fully denied", async () => {
  const storage = testEnv.authenticatedContext("user-a").storage();
  const fileRef = ref(storage, "pairs/pair-a/media/media-a/display.jpg");

  await assertFails(uploadString(fileRef, "test"));
});

test("Firebase Emulator Suite project id stays on the local demo project", () => {
  assert.equal(projectId, "demo-select-best-photo");
});

async function seedCategory() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "pairs", pairId), { memberIds: ["user-a", "user-b"] });
    await setDoc(categoryRef(db), categoryData());
  });
}

async function seedConfirmedCategory() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(categoryRef(context.firestore()), {
      ...categoryData(),
      status: "confirmed",
      confirmedAt: now()
    });
  });
}

async function seedCandidate(candidateId) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(candidateRef(context.firestore(), candidateId), candidateData(candidateId));
  });
}

async function seedInput(userId, candidateId, status) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(inputRef(context.firestore(), userId), inputData(userId, candidateId, status));
  });
}

async function seedResult() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(resultRef(context.firestore()), resultData());
  });
}

function categoryRef(db) {
  return doc(db, "pairs", pairId, "years", String(year), "textCategories", categoryId);
}

function candidateRef(db, candidateId) {
  return doc(db, "pairs", pairId, "years", String(year), "textCategories", categoryId, "candidates", candidateId);
}

function inputRef(db, userId) {
  return doc(db, "pairs", pairId, "years", String(year), "textCategories", categoryId, "inputs", userId);
}

function resultRef(db) {
  return doc(db, "pairs", pairId, "years", String(year), "textCategories", categoryId, "results", resultId);
}

function now() {
  return Timestamp.fromMillis(1_800_000_000_000);
}

function categoryData() {
  return {
    pairId,
    year,
    name: "今年の名言",
    status: "draft",
    inputRankLimit: 1,
    revealRankLimit: 1,
    pointsByRank: [{ rank: 1, points: 10 }],
    generation: 0,
    createdByUserId: "user-a",
    createdAt: now(),
    updatedAt: now()
  };
}

function candidateData(candidateId) {
  return {
    pairId,
    year,
    categoryId,
    name: `候補 ${candidateId}`,
    imagePlaceholderKind: "none",
    createdByUserId: "user-a",
    createdAt: now(),
    updatedAt: now()
  };
}

function inputData(userId, candidateId, status) {
  const data = {
    pairId,
    year,
    categoryId,
    userId,
    generation: 0,
    status,
    selections: [{ rank: 1, candidateId }],
    updatedAt: now()
  };
  if (status === "completed") {
    data.completedAt = now();
  }
  return data;
}

function resultData() {
  return {
    pairId,
    year,
    categoryId,
    generation: 0,
    entries: [{
      rank: 1,
      candidateId: "candidate-a",
      candidateName: "候補 candidate-a",
      totalPoints: 20,
      userBreakdowns: [
        { userId: "user-a", selectedRank: 1, points: 10 },
        { userId: "user-b", selectedRank: 1, points: 10 }
      ],
      imagePlaceholderKind: "none"
    }],
    sourceUserIds: ["user-a", "user-b"],
    createdAt: now()
  };
}
