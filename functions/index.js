const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// クイズの解答履歴(quizAttempts)に新しいデータが作成されたら、この関数が自動的に実行されます
exports.aggregateQuizResults = functions.firestore
  .document("quizAttempts/{attemptId}")
  .onCreate(async (snap, context) => {
    const quizResult = snap.data();
    const results = quizResult.results; // 個別の解答リスト

    const db = admin.firestore();
    // questionStatsという場所に、問題ごとの成績を保存します
    const statsRef = db.collection("questionStats");
    const batch = db.batch();

    // 各問題の正解・不正解をループで処理
    for (const result of results) {
      const questionId = result.questionId;
      const isCorrect = result.isCorrect;

      const questionStatRef = statsRef.doc(questionId);
      const increment = admin.firestore.FieldValue.increment(1);
      const correctIncrement = isCorrect ? increment : admin.firestore.FieldValue.increment(0);
      
      // totalAttempts（総解答回数）と correctAttempts（正解数）を更新
      batch.set(
        questionStatRef,
        {
          totalAttempts: increment,
          correctAttempts: correctIncrement,
          questionId: questionId, // 後で使いやすいようにIDも保存
        },
        { merge: true }
      );
    }
    // 処理をまとめて実行
    return batch.commit();
  });