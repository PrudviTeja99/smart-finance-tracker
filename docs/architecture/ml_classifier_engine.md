# Machine Learning Classifier Engine Specification

## 1. Overview
The Machine Learning engine auto-classifies transactions into categories and accounts using an on-device **2-Gram BIO Structured Perceptron Tagger** and **Multiclass Category Classifier**.

---

## 2. Feature Extraction & Parsing
1. **Tokenization**: Input notification text is tokenized into word N-grams (unigrams and bigrams).
2. **BIO Tagger (`bio_tagger.dart`)**: Tags tokens with BIO annotations (`B-AMT`, `I-AMT`, `B-MERCHANT`, `I-MERCHANT`, `B-ACC`, `O`).
3. **Feature Vectors**: Generates numerical sparse feature representations combining token text, character case, surrounding context words, and regex match signals.

---

## 3. Online Learning & Weight Updates
- When a user confirms or edits a draft transaction in the Inbox tab, the classifier triggers an online Perceptron weight update:
  $$\mathbf{W} \leftarrow \mathbf{W} + \eta (\mathbf{f}(x, y_{\text{true}}) - \mathbf{f}(x, y_{\text{pred}}))$$
- **Isolate Offloading**: Weight serialization (`_encodeWeightsIsolateTask`) and deserialization (`_decodeWeightsIsolateTask`) run in background isolates via Flutter's `compute()` helper to ensure zero main-thread jank.

