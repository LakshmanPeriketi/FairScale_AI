# Member 1: The Machine Learning Architect (Submission Documents)

## 🧠 Technical Architecture Narrative (Vertex AI Pipeline)

**Introduction:**
As the Machine Learning Engineer for FairScale AI, the primary challenge was not simply building a model that issues loans, but engineering a system that natively detects and neutralizes underlying systemic biases. Financial data is notoriously riddled with historical prejudices—often manifesting as 'proxies' (e.g., zip codes accidentally conveying racial demographics). 

To solve this, I designed a **Tripartite Adversarial Shield Architecture**, theoretically powered by Google Cloud's Vertex AI framework. 

### The Tripartite Vertex AI System

1. **Model A (The Legacy Baseline):**
   Model A is trained on vast arrays of historical data without specific constraints. It represents the inherent danger of modern black-box AI. In our testing, Model A rapidly "learns" to use Zipcode as a primary decision weight, aggressively rejecting marginalized applications simply because historical data did the same. Model A achieves high perceived accuracy, but drastically fails the fairness test.

2. **Model B (The Adversarial Detective):**
   Innovation is not just training a model to approve loans; it is training a model to audit *other* models. I implemented an adversarial neural concept as "Model B." Model B's sole objective is to observe Model A's output (approvals/rejections) and attempt to guess the applicant's demographic proxies (like Zipcode). If Model B can predict your Zip Code just by looking at whether Model A approved you, it mathematically proves that Model A is discriminating. Model B acts as our real-time alarm system.

3. **Model C (The Fair Mirror):**
   When Model B flags bias, the pipeline falls back to Model C. Model C relies on strict Causal Inference architecture. We intentionally "drop" protected attributes and known proxy correlations (via dataset manipulation techniques) during its Vertex AI training phase. Model C evaluates purely on independent financial merit indicators, mathematically enforcing equal-opportunity distribution across demographics without sacrificing underlying mathematical accuracy.

**Conclusion:**
By separating the AI flow into three distinct pipelines (The Baseline, The Detective, and The Fair Mirror), we ensure that an unfair decision never reaches the end-user undetected. This framework represents a major leap in Human-in-the-Loop engineering and positions FairScale AI as an enterprise-grade ethical compliance tool.
