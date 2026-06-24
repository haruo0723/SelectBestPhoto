import assert from "node:assert/strict";
import { after, test } from "node:test";
import { readFileSync } from "node:fs";
import {
  assertFails,
  initializeTestEnvironment
} from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc } from "firebase/firestore";
import { ref, uploadString } from "firebase/storage";

const projectId = "demo-select-best-photo";

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

test("Firestore rules deny access until TASK-0010 defines pair-scoped rules", async () => {
  const db = testEnv.authenticatedContext("user-a").firestore();

  await assertFails(getDoc(doc(db, "pairs", "pair-a")));
  await assertFails(setDoc(doc(db, "pairs", "pair-a"), {
    memberIds: ["user-a"]
  }));
});

test("Storage rules deny access until TASK-0011 defines media-scoped rules", async () => {
  const storage = testEnv.authenticatedContext("user-a").storage();
  const fileRef = ref(storage, "pairs/pair-a/media/media-a/display.jpg");

  await assertFails(uploadString(fileRef, "test"));
});

test("Firebase Emulator Suite project id stays on the local demo project", () => {
  assert.equal(projectId, "demo-select-best-photo");
});
