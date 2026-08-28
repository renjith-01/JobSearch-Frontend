# JobMatchAI — Portfolio Project + 6-Week QE Upskilling Plan

> Personal project for **Renjith T** (17+ yrs QA/SDET, ex-Cisco, now ex-N-able/Adlumin).
> Goal: rebuild hands-on coding fluency and produce **one** portfolio artifact that
> demonstrates Automation, CI/CD, Performance, Observability, Cloud/K8s, and AI-agentic
> testing — while interviewing for Staff SDET / QA Automation Architect roles.

---

## 1. The idea in one line
A web app that **autonomously searches job portals, pulls jobs into a data pipeline, matches
each job description against my resume using AI, scores the fit, suggests resume
improvements, and lists the best matches** — mirroring the production ingestion pipeline I
engineered at Adlumin.

## 2. Tech stack (confirmed)
| Layer | Choice |
|---|---|
| Frontend | **Vue 3 + Vite** |
| Backend/API | **Python + FastAPI** |
| Workers | **Python** (scheduled ingest worker → later an LLM agent) |
| Queue | **SQS** (LocalStack locally) or Redis |
| DB / index | **Postgres + pgvector** (semantic search); OpenSearch optional |
| AI | Embeddings (`sentence-transformers`, local & free) + **Claude API** for reasoning/insights |
| IaC | **Terraform** |
| CI/CD | **Jenkins** (+ GitHub Actions optional) |
| Deploy | **AWS ECS Fargate** (simple) *or* **EKS** (if K8s is a study goal) |
| Local AWS | **LocalStack** (avoid cloud bills during dev) |
| Tests | **PyTest** (backend) + **Playwright in TypeScript** (frontend) |

> Languages covered naturally: **Python** (backend/agents), **TypeScript** (Playwright suite).
> **Java** is NOT part of this app — do it as a separate kata (port PyTest API tests to
> RestAssured/TestNG) only if target jobs require it.

## 3. Architecture
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

## 4. Repo structure
```
jobmatch-ai/
├── frontend/            # Vue 3 + Vite
│   ├── src/
│   └── tests/           # Playwright (TypeScript)
├── backend/             # FastAPI
│   ├── app/
│   │   ├── api/         # routes
│   │   ├── core/        # config, db, settings
│   │   ├── ingest/      # job-source API clients + normalizer
│   │   ├── matching/    # embeddings + Claude insight calls
│   │   └── agents/      # agentic search (added W6)
│   └── tests/           # PyTest (unit + API + contract)
├── workers/             # scheduled ingest worker
├── infra/               # Terraform (modules/ + envs/)
├── ci/                  # Jenkinsfile + scripts
├── docker/              # Dockerfiles, docker-compose (+ LocalStack)
└── docs/
```

## 5. AWS / Terraform resources (ECS Fargate baseline)
- **VPC** + public/private subnets, security groups, NAT
- **ECR** — container images
- **ECS cluster** + Fargate services: `frontend`, `backend`
- **ALB** — routes `/` → frontend, `/api` → backend
- **RDS Postgres** (pgvector) — or Aurora Serverless v2
- **SQS** queue + **dead-letter queue**
- **EventBridge Scheduler** (or ECS scheduled task) — periodic job search
- **Secrets Manager** — job-API keys, Claude API key, DB creds (never commit)
- **CloudWatch** — logs, metrics, dashboards, alarms
- **IAM** roles/policies (least privilege)
- *(EKS variant: swap ECS for EKS cluster + node group/Fargate profile + K8s manifests: Deployment, Service, Ingress, CronJob.)*

## 6. The AI part (demystified)
**Two touchpoints. Only (A) is required.**

### (A) Matching & insight — REQUIRED, and small
Three levels — use as many as you like:
1. **No AI baseline** — extract skills, set-intersection. Keep for comparison.
2. **Embeddings (semantic score)** — vectorize resume + JD, cosine similarity = match %.
   Free/offline via `sentence-transformers`. Ranks thousands of jobs cheaply.
3. **LLM reasoning (the insights)** — ONE call returns the human-readable analysis:
```python
prompt = f"""Compare this resume to the job description.
Return JSON: {{"score":0-100,"matched":[...],"missing":[...],"resume_tips":[...]}}
RESUME:\n{resume_text}\nJOB:\n{jd_text}"""
result = client.messages.create(...)     # one Claude API call
job["analysis"] = json.loads(result)
```
**Good architecture:** Level 2 to rank ALL jobs cheaply → Level 3 only on the top ~20.
(Cheap filter → expensive analysis on top-N. Great interview talking point.)

### (B) Agentic search — OPTIONAL, the W6 "wow"
- Start as a **plain scheduled worker** (cron / ECS scheduled task / K8s CronJob) that calls
  job APIs and stores results. Not an agent — fine for W1–W5.
- An **agent = LLM + tools + a loop.** Give it tools `search(query)`, `fetch_jd(url)`,
  `score(resume,jd)`, `save(job)` and let it decide (expand queries from the resume, pick
  which jobs to fetch, judge relevance). Hand-roll with Claude tool-use first (learn it),
  not a heavy framework.

> Reality check on sources: **do NOT scrape LinkedIn/Indeed/Naukri** (ToS + bans).
> Use APIs that allow it: **Adzuna, Remotive, RemoteOK, TheMuse, USAJobs, Jooble**, and
> per-company **Greenhouse/Lever** public endpoints. Respect robots.txt/ToS — and say so.

## 7. Testing strategy per layer (this is your QE showcase)
| Layer | What to test | Tooling |
|---|---|---|
| Job-source clients | schema/normalization, pagination, rate-limit handling | PyTest + recorded fixtures (VCR) |
| Pipeline/queue | idempotency, retries, dead-letter, dedup | PyTest + LocalStack |
| Matching engine | **non-deterministic AI** → assert *ranges/shape*, golden sets, semantic thresholds, LLM-as-judge | PyTest + eval harness |
| API | contract, auth, error paths | PyTest + FastAPI TestClient |
| UI | list/filter/detail flows | Playwright (TS) |
| Agents (W6) | tool-call correctness, guardrails, cost/latency budget, deterministic mocks | PyTest + eval harness |
| Non-functional | throughput, p95/p99, LLM latency & cost | K6/JMeter + Grafana/CloudWatch |

**Deliberately NOT automated:** exploratory resume-quality judgment, one-off portal onboarding.

## 8. The 6-week plan (app slice + QE focus per week)
> "Focus" = the study area you deliberately level up that week. The app is one continuous
> project that grows each week.

| Wk | Focus | App slice to build | Quality layer to deliver | Lang |
|---|---|---|---|---|
| **1** | Automation | Vue skeleton + FastAPI + Postgres; **1** job API → store → list | PyTest API suite + basic Playwright (TS); hand-written | Python |
| **2** | Automation + CI/CD start | Matching endpoint (embeddings + one Claude call) | Data-driven tests; first Jenkins job green | TS |
| **3** | CI/CD + Terraform | Dockerize; **Terraform** provisions AWS (LocalStack first); Jenkins deploys | Full pipeline lint→test→report→notify, gates deploy | — |
| **4** | Cloud & K8s / AWS | **Scheduled search worker** + **SQS**; deploy to ECS/EKS | Resiliency: retries, DLQ, pod/task debugging | Python |
| **5** | Perf + Observability | Run ingestion at volume | K6/JMeter on matching API; Grafana/CloudWatch dashboards; fix a bottleneck (LLM latency/cost) | — |
| **6** | AI Agentic Testing | Upgrade worker → **agent** (LLM+tools+loop) | Agent that auto-generates test cases; **test the agents** (eval harness, mocks) | Python |

**Guardrails:** walking skeleton in W1 must run end-to-end before adding anything.
The app serves interview prep — if app work threatens prep time, cut app scope.
Apply to jobs *while* building; early interviews reveal exactly what to drill.

## 9. How to use Claude as a coach (not a code generator)
- Ask it to **interview** you and grade answers (framework design, coding, K8s debug, perf).
- Ask it to **review code YOU wrote** and point out weaknesses — without rewriting it.
- Ask it to **quiz** you on fundamentals and **refuse answers** until you attempt them.
- Only after you've tried: ask for the "better version" + why.

## 10. Interview positioning (resume)
- Primary: **Python** (strong). Proficient: **TypeScript, Java** — don't claim "expert" in all three.
- Add domain **Cybersecurity/SIEM** + **AI/agent-based test automation** to the summary.
- Lead the story with: *"personal system mirroring the production ingestion pipeline I built at Adlumin, with AI matching + full QE on top."*

---

## 11. Executable timetable (target: Principal/Staff SDET, Test Architect)
**Assumptions:** ~6 focused hrs/day, 6 days/week (post-resignation full-time). If only
3–4 hrs/day → stretch to 8–9 weeks and drop the Java kata. Apply in parallel from Week 2.
Interview bar for these roles = applied coding (DSA-light) + heavy framework/system design
+ leadership/behavioral.

### Daily engine (repeat every working day)
| Block | Time | What |
|---|---|---|
| 1 | 90 min | Language fluency — hand-write code, no AI. Language of the week. |
| 2 | 120 min | JobMatchAI — the week's slice + its tests. |
| 3 | 60 min | Design/theory — week's concept + one framework/system-design prompt. |
| 4 | 45 min | DSA-light — 2 problems, pattern of the day. |
| 5 | 30 min | Applications + STAR stories + LinkedIn. |

From Week 3: 2 days/week swap blocks 3–4 for a full mock interview.

### 6-week calendar
| Wk | Language | Project milestone | Interview-prep focus | Apply |
|---|---|---|---|---|
| 1 | Python deep | Scaffold; Vue+FastAPI+Postgres; 1 job API→store→list; PyTest + basic Playwright | Framework-design fundamentals; DSA arrays/strings/hashmap; 3 STAR | Profiles + resume variants (soft-launch end) |
| 2 | TypeScript (Playwright suite) | Matching endpoint (embeddings + 1 Claude call); data-driven tests; Dockerize; first Jenkins green | POM/fixtures/parallel/flakiness; DSA two-pointer/sliding-window/stack; +3 STAR | START 5–8 apps; Open-to-Work; ping 5 referrals |
| 3 | Java kata (port API tests → RestAssured/TestNG) | Full pipeline lint→test→report→notify; Terraform→AWS (LocalStack first); Jenkins deploys | 2 mocks (framework+coding); DSA trees/recursion; sysdesign "framework at scale" | 8–10 apps; follow up referrals |
| 4 | Consolidate | Scheduled worker + SQS; deploy ECS/EKS; resiliency (retries, DLQ, pod debug) | 2 mocks (sysdesign + debugging); DSA graphs BFS/DFS; CI/CD & infra deep-dive | 8–10 apps; protect first rounds |
| 5 | — | K6/JMeter load; Grafana/CloudWatch dashboards; fix a bottleneck (LLM latency/cost) | 2 mocks (perf + Principal-level leadership); live interviews | Maintain; prioritize live processes |
| 6 | — | Worker→agent (LLM+tools+loop); agent generates tests; test the agents; README + arch diagram + 3-min demo | 2 mocks (Principal: test vision, influence, org strategy); offer/negotiation | Convert; keep applying until signed |

### Sub-tracks
- **DSA-light (~2/day, patterns over volume):** string parsing, hashmap counting, two-pointer,
  sliding window, stack/queue, basic tree/graph — plus SDET classics: LRU cache, rate limiter,
  log parser, retry-with-backoff, flaky-test detector, dedup design.
- **Design (Principal/Staff differentiator, out loud):** framework for microservices; test
  strategy for a data pipeline; testing non-deterministic AI; scaling E2E to thousands; flaky
  governance; test-data management; observability-driven testing.
- **Behavioral (8–10 STAR):** org-wide test strategy; influence without authority; mentoring;
  a costly quality miss + fix; automation ROI (the 96%); leading the UI dev team; a reversed decision.

### Weekly Definition of Done (check every Sunday)
Shippable app increment + green pipeline + N applications sent + mocks done + STAR stories added.
If a week slips, cut app scope first (e.g., skip W6 agentic, keep matching) — prep > polish.

---

## 12. Day-by-day breakdown (tick as you go)
Rhythm: Days 1–6 = work (6 focused hrs via the daily engine), Day 7 = checkpoint + rest.
From Week 3, the "MOCK" days replace the Design + DSA blocks.

### Week 1 — Foundations & Automation · Language: Python
**Day 1** — [ ] Py: types, collections, comprehensions, f-strings (hand-write)  [ ] Proj: scaffold repo (§4), FastAPI health endpoint, docker-compose Postgres  [ ] Design: test pyramid vs trophy for JobMatchAI  [ ] DSA: two-sum, Kadane, running-sum  [ ] Apply: LinkedIn Open-to-Work draft, list 20 targets
**Day 2** — [ ] Py: functions, args/kwargs, errors, modules, type hints+mypy  [ ] Proj: DB schema (jobs/resume/matches) via SQLModel + migration + connect  [ ] Design: POM, separation of concerns, fixtures  [ ] DSA: reverse words, valid anagram, first-unique-char  [ ] Apply: resume variant #1 (Architect-lean)
**Day 3** — [ ] Py: PyTest deep (fixtures, parametrize, markers, conftest)  [ ] Proj: first job-source client → fetch → normalize; unit-test normalizer w/ recorded fixtures  [ ] Design: test-data management  [ ] DSA: group anagrams, two-sum-map, freq counter  [ ] Apply: resume variant #2 (Staff-SDET-lean)
**Day 4** — [ ] Py: async/await, httpx, context managers  [ ] Proj: ingest→store endpoint + GET /jobs; API tests via TestClient  [ ] Design: testing HTTP clients (mocking/VCR/contract)  [ ] DSA: window sum size-k, longest substr no-repeat  [ ] Apply: STAR #1 (automation ROI 96%)
**Day 5** — [ ] Py: logging, pydantic settings, packaging  [ ] Proj: minimal Vue list page wired to API; basic Playwright test  [ ] Design: UI E2E vs component  [ ] DSA: valid palindrome, container-most-water  [ ] Apply: STAR #2 (led UI dev team), polish LinkedIn
**Day 6** — [ ] Py: redo 2 snippets from memory  [ ] Proj: skeleton runs end-to-end (fetch→store→list→UI), README start  [ ] Design: say the JobMatchAI test strategy out loud (5 min)  [ ] DSA: redo 3 problems cold  [ ] Apply: STAR #3 (quality miss+fix), finalize both resumes
**Day 7 checkpoint** — [ ] skeleton E2E green [ ] PyTest+Playwright green [ ] 2 resumes [ ] 3 STAR · rest

### Week 2 — Automation depth + Matching + CI/CD start · Language: TypeScript
**Day 1** — [ ] TS: types, interfaces, generics, async  [ ] Proj: embeddings score (sentence-transformers, cosine) stored  [ ] Design: testing non-deterministic output (ranges/shape/golden sets)  [ ] DSA: valid parentheses, min-stack  [ ] Apply: **START — 3 apps, Open-to-Work ON**
**Day 2** — [ ] TS: Playwright+TS (config, fixtures, locators, auto-wait)  [ ] Proj: expand UI tests (list/filter/detail) in TS  [ ] Design: flakiness root causes  [ ] DSA: queue-via-stacks, daily-temperatures  [ ] Apply: 2 apps, ping 3 referrals
**Day 3** — [ ] TS: Promises, fetch, error handling  [ ] Proj: LLM matching (1 Claude call → {score,matched,missing,tips}) parse+store  [ ] Design: LLM-as-judge / eval harness  [ ] DSA: longest consecutive seq, intersection  [ ] Apply: 2 apps, STAR #4 (influence w/o authority)
**Day 4** — [ ] Consolidate Py+TS via project  [ ] Proj: data-driven matching tests (parametrize)  [ ] Design: CI pipeline stages/gating/artifacts  [ ] DSA: min-window-substring  [ ] Apply: 2 apps, STAR #5 (mentoring)
**Day 5** — [ ] Dockerfiles (Python+Node)  [ ] Proj: dockerize FE+BE; compose full stack + LocalStack  [ ] Design: containerized test envs  [ ] DSA: subsets, permutations  [ ] Apply: 2 apps
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

## Portable context prompt (paste into Claude on another machine)
```
I'm Renjith T, 17+ yrs QA/SDET (ex-Cisco, ex-N-able/Adlumin), interviewing for Staff
SDET / QA Automation Architect roles. I've been directing AI to write code and need to
rebuild hands-on fluency in Python (primary), TypeScript, and Java.

I'm building ONE portfolio project — "JobMatchAI": a Vue + FastAPI web app that
autonomously searches job APIs, runs a data pipeline (SQS/Postgres+pgvector), matches
job descriptions to my resume with embeddings + Claude, scores fit, and suggests resume
improvements. Deploy via Terraform to AWS ECS/EKS with Jenkins CI/CD. Tests: PyTest +
Playwright (TS).

I'm following a 6-week plan: W1 Automation, W2 Automation+CI/CD, W3 CI/CD+Terraform,
W4 Cloud/K8s+AWS, W5 Performance+Observability, W6 AI-agentic testing. Each week I build
an app slice AND its quality layer.

Coach me: interview me and grade my answers, review code I write (don't write it for me),
quiz me on fundamentals, and refuse answers until I try. Start by asking where I am in
the plan.
```
