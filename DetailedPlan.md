# JobMatchAI — Detailed 6-Week Plan (with Language Front-Load)

> Personal portfolio + upskilling plan for **Renjith T** (17+ yrs QA/SDET, ex-Cisco, ex-N-able/Adlumin).
> Goal: rebuild hands-on coding fluency and ship **one** portfolio artifact demonstrating
> Automation, CI/CD, Performance, Observability, Cloud/K8s, and AI-agentic testing —
> while interviewing for **Staff SDET / QA Automation Architect** roles.
>
> **Coaching rule:** Claude does NOT write the project code. It interviews, grades, reviews
> code *you* wrote, and quizzes fundamentals. You do the work.

---

## 0. The one-line idea
A web app that **autonomously searches job portals, ingests jobs into a data pipeline, matches
each job description against my resume with AI, scores the fit, suggests resume improvements,
and lists the best matches** — mirroring the production ingestion pipeline I engineered at Adlumin.

---

## 1. Tech stack
| Layer | Choice |
|---|---|
| Frontend | Vue 3 + Vite |
| Backend/API | Python + FastAPI |
| Workers | Python (scheduled ingest worker → LLM agent in W6) |
| Queue | SQS (LocalStack locally) or Redis |
| DB / index | Postgres + pgvector (semantic search); OpenSearch optional |
| AI | Embeddings (`sentence-transformers`, local & free) + Claude API for reasoning/insights |
| IaC | Terraform |
| CI/CD | Jenkins (+ GitHub Actions optional) |
| Deploy | AWS ECS Fargate (simple) *or* EKS (if K8s is a study goal) |
| Local AWS | LocalStack |
| Tests | PyTest (backend) + Playwright in TypeScript (frontend) |

> Languages: **Python** (primary, deep) · **TypeScript** (Playwright suite) · **Java** (separate kata only if a target job needs it). Don't claim "expert in all three."

---

## 2. Architecture
```
                 ┌──────────────────────────────────────────────┐
   Job Sources   │  (1) Search Worker (periodic; agent in W6)    │
  (APIs/feeds) ─▶│      query-expand → fetch → extract → dedupe  │
                 └───────────────────┬──────────────────────────┘
                                     │ push
                                     ▼
                        (2) Queue  (SQS / Redis)  + DLQ
                                     │ pull
                                     ▼
                 ┌──────────────────────────────────────────────┐
                 │  (3) Backend / Ingest (FastAPI)               │
                 │      normalize → store                        │
                 └───────────────────┬──────────────────────────┘
                                     ▼
                     (4) Postgres + pgvector  (jobs, resume, matches)
                                     │
              ┌──────────────────────┼───────────────────────────┐
              ▼                                                   ▼
   (5) Matching / Insight Engine                        (6) Web App (Vue)
   resume ⇄ JD: embeddings + Claude                     list matches · scores ·
   score · gaps · resume tips                           resume insights
```

---

## 3. Testing strategy per layer (the QE showcase)
| Layer | What to test | Tooling |
|---|---|---|
| Job-source clients | schema/normalization, pagination, rate-limit handling | PyTest + recorded fixtures (VCR) |
| Pipeline/queue | idempotency, retries, dead-letter, dedup, schema drift | PyTest + LocalStack |
| Matching engine | **non-deterministic AI** → invariants/shape, metamorphic relations, golden-set ranking, LLM-as-judge, drift-as-metric | PyTest + eval harness |
| API | contract, auth, error paths | PyTest + FastAPI TestClient |
| UI | list/filter/detail flows | Playwright (TS) |
| Agents (W6) | tool-call correctness, guardrails, cost/latency budget, deterministic mocks | PyTest + eval harness |
| Non-functional | throughput, p95/p99, LLM latency & cost | K6/JMeter + Grafana/CloudWatch |

**Deliberately NOT automated:** exploratory resume-quality judgment; one-off portal onboarding;
early-stage UI visuals that churn too fast for stable E2E; subjective match "correctness"
(soft-skills / career-change / career-gap calls) — gate those with human review.

### Testing non-deterministic AI — the 5 assertion layers (memorize this)
1. **Shape / bounds invariants** — `score ∈ [0,100]`, JSON parses, arrays present. Always-on, cheap.
2. **Metamorphic relations** — add a *relevant* skill → score ↑; add an *irrelevant* skill → score ≈ (tolerance derived empirically, not a magic number); remove all relevant skills → score ↓.
3. **Golden set + ranking** — labeled resume↔JD corpus; assert *ordering* (strong > weak), not absolute scores.
4. **LLM-as-judge** — a second model call scores the free-text "resume tips" against a rubric (relevant? specific? actionable?).
5. **Eval harness / drift** — run the golden set on a schedule, track score distribution/variance as a metric, alarm on drift when model/prompt changes. Pin `temperature=0` + model version to shrink variance at the source.

> One-liner: *"For non-deterministic AI I don't assert equality — I assert invariants, relations, rankings, and rubric-judged quality, and I track quality as a metric over time rather than as a pass/fail gate."*

---

## 4. Daily engine (repeat every working day, ~6 focused hrs)
| Block | Time | What |
|---|---|---|
| 1 | 90 min | Language fluency — hand-write code, **no AI**. Language of the week. |
| 2 | 120 min | JobMatchAI — the week's slice + its tests. |
| 3 | 60 min | Design/theory — week's concept + one framework/system-design prompt. |
| 4 | 45 min | DSA-light — 2 problems, pattern of the day. |
| 5 | 30 min | Applications + STAR stories + LinkedIn. |

From Week 3: 2 days/week swap blocks 3–4 for a full mock interview.

---

## 5. The language front-load (agreed change)
No separate "Week 0." Instead, a **compressed front-load** — ~2 extra days total, every rep in a
kata or in the project, never in a vacuum:

- **Week 1, Days 1–3** — Python + PyTest fluency sprint (hand-write, no AI) *before* scaffolding.
- **Week 1, Day 4 onward** — start the project; keep the daily 90-min fluency block.
- **Week 2, Days 1–2** — TS + Playwright constructs sprint, then straight into the FE suite.

**Escalation condition:** if after Week 1 Day 3 you *cannot* hand-write a PyTest fixture + a
comprehension without looking them up, add 2 more days — earned by evidence, not booked in advance.
Rule: cut app scope before you cut prep, but don't pad prep on a hunch.

---

## 6. Six-week calendar
| Wk | Language | Project milestone | Interview-prep focus | Apply |
|---|---|---|---|---|
| 1 | Python deep | Language sprint (D1–3) → scaffold Vue+FastAPI+Postgres; 1 job API→store→list; PyTest + basic Playwright | Framework-design fundamentals; DSA arrays/strings/hashmap; 3 STAR | Profiles + resume variants (soft-launch end) |
| 2 | TypeScript | TS/Playwright sprint (D1–2) → matching endpoint (embeddings + 1 Claude call); data-driven tests; Dockerize; first Jenkins green | POM/fixtures/parallel/flakiness; DSA two-pointer/sliding-window/stack; +3 STAR | START 5–8 apps; Open-to-Work; ping 5 referrals |
| 3 | Java kata | Full pipeline lint→test→report→notify; Terraform→AWS (LocalStack first); Jenkins deploys | 2 mocks (framework+coding); DSA trees/recursion; sysdesign "framework at scale" | 8–10 apps; follow up referrals |
| 4 | Consolidate | Scheduled worker + SQS; deploy ECS/EKS; resiliency (retries, DLQ, pod debug) | 2 mocks (sysdesign + debugging); DSA graphs BFS/DFS; CI/CD & infra deep-dive | 8–10 apps; protect first rounds |
| 5 | — | K6/JMeter load; Grafana/CloudWatch dashboards; fix a bottleneck (LLM latency/cost) | 2 mocks (perf + Principal leadership); live interviews | Maintain; prioritize live processes |
| 6 | — | Worker→agent (LLM+tools+loop); agent generates tests; test the agents; README + arch diagram + 3-min demo | 2 mocks (Principal: test vision, influence, org strategy); offer/negotiation | Convert; keep applying until signed |

---

## 7. Day-by-day breakdown (tick as you go)
Rhythm: Days 1–6 = work, Day 7 = checkpoint + rest. From Week 3, "MOCK" days replace Design + DSA blocks.

### Week 1 — Foundations & Automation · Language: Python
**Day 1 (Python sprint)** — [ ] Py: types, collections, comprehensions, f-strings (hand-write)  [ ] Py katas: 5 small hand-written snippets, no AI  [ ] Design: test pyramid vs trophy for JobMatchAI  [ ] DSA: two-sum, Kadane, running-sum  [ ] Apply: LinkedIn Open-to-Work draft, list 20 targets
**Day 2 (Python sprint)** — [ ] Py: functions, args/kwargs, errors, modules, type hints + mypy  [ ] Py: generators, decorators, context managers (hand-write)  [ ] Design: POM, separation of concerns, fixtures  [ ] DSA: reverse words, valid anagram, first-unique-char  [ ] Apply: resume variant #1 (Architect-lean)
**Day 3 (Python sprint)** — [ ] Py: PyTest deep (fixtures, parametrize, markers, conftest) on tiny katas  [ ] Self-check: hand-write a fixture + a comprehension cold (escalation gate)  [ ] Design: test-data management  [ ] DSA: group anagrams, two-sum-map, freq counter  [ ] Apply: resume variant #2 (Staff-SDET-lean)
**Day 4 (project starts)** — [ ] Proj: scaffold repo, FastAPI health endpoint, docker-compose Postgres  [ ] Proj: DB schema (jobs/resume/matches) via SQLModel + migration + connect  [ ] Design: testing HTTP clients (mocking/VCR/contract)  [ ] DSA: window sum size-k, longest substr no-repeat  [ ] Apply: STAR #1 (automation ROI 96%)
**Day 5** — [ ] Py: async/await, httpx, logging, pydantic settings  [ ] Proj: first job-source client → fetch → normalize; unit-test normalizer w/ recorded fixtures  [ ] Proj: ingest→store endpoint + GET /jobs; API tests via TestClient  [ ] Design: UI E2E vs component  [ ] DSA: valid palindrome, container-most-water  [ ] Apply: STAR #2 (led UI dev team)
**Day 6** — [ ] Proj: minimal Vue list page wired to API; basic Playwright test  [ ] Proj: skeleton runs end-to-end (fetch→store→list→UI), README start  [ ] Design: say the JobMatchAI test strategy out loud (5 min)  [ ] DSA: redo 3 problems cold  [ ] Apply: STAR #3 (quality miss+fix), finalize both resumes
**Day 7 checkpoint** — [ ] skeleton E2E green [ ] PyTest+Playwright green [ ] 2 resumes [ ] 3 STAR · rest

### Week 2 — Automation depth + Matching + CI/CD start · Language: TypeScript
**Day 1 (TS sprint)** — [ ] TS: types, interfaces, generics, async/Promises, fetch (hand-write)  [ ] TS katas: 5 small snippets, no AI  [ ] Design: testing non-deterministic output (invariants/metamorphic/golden set)  [ ] DSA: valid parentheses, min-stack  [ ] Apply: **START — 3 apps, Open-to-Work ON**
**Day 2 (TS/Playwright sprint)** — [ ] TS: Playwright config, fixtures, locators, auto-wait  [ ] Proj: expand UI tests (list/filter/detail) in TS  [ ] Design: flakiness root causes  [ ] DSA: queue-via-stacks, daily-temperatures  [ ] Apply: 2 apps, ping 3 referrals
**Day 3** — [ ] Proj: embeddings score (sentence-transformers, cosine) stored  [ ] Proj: LLM matching (1 Claude call → {score,matched,missing,tips}) parse+store  [ ] Design: LLM-as-judge / eval harness  [ ] DSA: longest consecutive seq, intersection  [ ] Apply: 2 apps, STAR #4 (influence w/o authority)
**Day 4** — [ ] Consolidate Py+TS via project  [ ] Proj: data-driven matching tests (parametrize) + metamorphic assertions  [ ] Design: CI pipeline stages/gating/artifacts  [ ] DSA: min-window-substring  [ ] Apply: 2 apps, STAR #5 (mentoring)
**Day 5** — [ ] Proj: Dockerfiles (Python+Node); dockerize FE+BE; compose full stack + LocalStack  [ ] Design: containerized test envs  [ ] DSA: subsets, permutations  [ ] Apply: 2 apps
**Day 6** — [ ] Proj: first CI job (lint+PyTest+Playwright) green  [ ] Design: articulate CI strategy  [ ] DSA: review week  [ ] Apply: weekly review
**Day 7 checkpoint** — [ ] matching works [ ] tests green in CI [ ] 8+ apps [ ] 5 STAR · rest

### Week 3 — CI/CD + Terraform + Java kata + first mocks · Language: Java
**Day 1** — [ ] Java: classes, collections, streams, Maven/Gradle  [ ] Proj: Jenkinsfile stages (checkout→lint→unit→api→ui→report)  [ ] Design: sysdesign "framework for microservices at scale"  [ ] DSA: tree inorder/level-order  [ ] Apply: 3 apps
**Day 2** — [ ] Java: RestAssured + TestNG setup  [ ] Proj: port subset of API tests to RestAssured  [ ] **MOCK #1 (framework design)**  [ ] Apply: 2 apps
**Day 3** — [ ] Java: finish RestAssured suite (assertions, data providers)  [ ] Proj: HTML report + JUnit XML wired into pipeline  [ ] Design: test-result reporting/observability  [ ] DSA: max-depth, validate-BST  [ ] Apply: 2 apps, STAR #6
**Day 4** — [ ] Consolidate  [ ] Proj: Terraform basics; provision Postgres+SQS on LocalStack  [ ] Design: IaC + ephemeral envs  [ ] DSA: tree path-sum  [ ] Apply: 2 apps
**Day 5** — [ ] Proj: Terraform ECR+ECS/EKS skeleton; Jenkins build→push→deploy (dev)  [ ] **MOCK #2 (live coding)**  [ ] Apply: 2 apps
**Day 6** — [ ] Proj: pipeline E2E green incl. notify; tidy  [ ] Design: articulate CI/CD+IaC story  [ ] DSA: review  [ ] Apply: weekly review
**Day 7 checkpoint** — [ ] pipeline deploys via Terraform [ ] Java suite runs [ ] 2 mocks [ ] 8+ apps · rest

### Week 4 — Cloud/K8s + AWS runtime + mocks
**Day 1** — [ ] Proj: search→worker pushes to SQS; ingest pulls  [ ] Design: idempotency/retries/DLQ  [ ] DSA: grid BFS/DFS  [ ] Apply: 3 apps
**Day 2** — [ ] Proj: scheduled trigger (EventBridge/ECS task or K8s CronJob)  [ ] **MOCK #3 (system design)**  [ ] Apply: 2 apps
**Day 3** — [ ] Proj: deploy ECS/EKS to AWS dev via Terraform+Jenkins; ALB routing  [ ] Design: ECS/K8s debugging (logs, describe)  [ ] DSA: num-islands, clone-graph  [ ] Apply: 2 apps, STAR #7
**Day 4** — [ ] Proj: resiliency — inject failures, verify retries/DLQ; worker PyTest  [ ] Design: chaos/resiliency testing  [ ] DSA: BFS shortest path  [ ] Apply: 2 apps
**Day 5** — [ ] Proj: debug a broken pod/task live, fix  [ ] **MOCK #4 (debugging + CI/CD deep-dive)**  [ ] Apply: 2 apps
**Day 6** — [ ] Proj: harden deploy, secrets via Secrets Manager, docs  [ ] Design: articulate cloud/runtime story  [ ] DSA: review  [ ] Apply: weekly review
**Day 7 checkpoint** — [ ] running in cluster [ ] scheduled ingestion [ ] resiliency proven [ ] 2 mocks · rest

### Week 5 — Performance + Observability + live interviews
**Day 1** — [ ] Proj: K6/JMeter on matching API; baseline p95/p99  [ ] Design: perf test strategy  [ ] DSA: heap/top-k  [ ] Apply: prioritize live interviews
**Day 2** — [ ] Proj: instrument (Prometheus/CloudWatch + structured logs)  [ ] **MOCK #5 (perf scenario)**  [ ] Apply: live
**Day 3** — [ ] Proj: Grafana/CloudWatch dashboards (throughput, queue depth, latency, LLM cost)  [ ] Design: observability-driven testing  [ ] DSA: top-k, merge-intervals  [ ] Apply: STAR #8
**Day 4** — [ ] Proj: find bottleneck (LLM latency/cost, DB N+1) → fix (cache/batch/index) → re-measure  [ ] Design: capacity/scaling  [ ] DSA: review  [ ] Apply
**Day 5** — [ ] Proj: document perf tuning (before/after); add perf gate to CI  [ ] **MOCK #6 (Principal leadership/behavioral)**  [ ] Apply
**Day 6** — [ ] Proj: polish dashboards + perf README  [ ] Design: articulate perf+observability story  [ ] DSA: review  [ ] Apply: weekly review
**Day 7 checkpoint** — [ ] load-tested [ ] dashboards live [ ] a documented fix [ ] 2 mocks · rest

### Week 6 — AI-agentic testing + polish + close
**Day 1** — [ ] Proj: worker→agent (Claude tool-use: search/fetch/score/save + loop)  [ ] Design: agent architecture + guardrails  [ ] DSA: light review  [ ] Apply/interviews
**Day 2** — [ ] Proj: agent reads JD → generates test cases/data  [ ] **MOCK #7 (Principal test vision/strategy)**  [ ] Apply
**Day 3** — [ ] Proj: test the agents (eval harness, stub-LLM mocks, guardrail + cost/latency assertions)  [ ] Design: testing AI systems  [ ] DSA: light  [ ] Apply
**Day 4** — [ ] Proj: end-to-end integration; close gaps  [ ] Design: whole-system articulate  [ ] Apply
**Day 5** — [ ] Proj: README + architecture diagram + 3-min demo video  [ ] **MOCK #8 (full loop simulation)**  [ ] Apply: offer/negotiation prep
**Day 6** — [ ] Proj: final polish, pin repo, LinkedIn Featured  [ ] Retro: list weak spots to keep drilling  [ ] Apply: continue until signed
**Day 7 checkpoint** — [ ] agent works [ ] agents tested [ ] demo recorded [ ] portfolio public · celebrate + keep interviewing

---

## 8. Sub-tracks
- **DSA-light (~2/day, patterns over volume):** string parsing, hashmap counting, two-pointer, sliding window, stack/queue, basic tree/graph — plus SDET classics: LRU cache, rate limiter, log parser, retry-with-backoff, flaky-test detector, dedup design.
- **Design (Staff/Principal differentiator, out loud):** framework for microservices; test strategy for a data pipeline; testing non-deterministic AI; scaling E2E to thousands; flaky governance; test-data management; observability-driven testing.
- **Behavioral (8–10 STAR):** org-wide test strategy; influence without authority; mentoring; a costly quality miss + fix; automation ROI (the 96%); leading the UI dev team; a reversed decision.

## 9. Weekly Definition of Done (check every Sunday)
Shippable app increment + green pipeline + N applications sent + mocks done + STAR stories added.
If a week slips, cut **app scope** first (e.g., skip W6 agentic, keep matching) — prep > polish.
