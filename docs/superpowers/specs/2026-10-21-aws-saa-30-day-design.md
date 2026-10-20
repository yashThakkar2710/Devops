# AWS Solutions Architect — 30 Day Plan

**Date:** 2026-10-21
**Status:** Approved, in progress
**Supersedes:** the 247-hour networking curriculum, which is parked (not deleted) — see §9.

---

## 1. Goal

Reach **AWS Solutions Architect Associate level capability** in 30 days, by building rather than reading. The certification is a checkpoint, not the objective: the learner explicitly wants the skill, and will decide near day 30 whether to book the exam.

Success is being able to **choose and justify an architecture** — not recall service names.

## 2. Learner

- Developer, 2 years experience. Strong on application code.
- **Near-zero AWS hands-on.** Knows service names, hasn't built with them.
- Has an AWS account, **free tier still active**.
- Completed Phase 0 of the networking curriculum: packets, IP/port, subnets, routing tables, DNS, TCP handshake, RTT/TTL. This maps directly onto VPC.
- Open to supplementary video as a second explanation. Building remains primary.

## 3. Time budget

| | Hours |
|---|---|
| 20 weekdays × 3h | 60 |
| 8 weekend days × 5h | 40 |
| **Total** | **~100** |

Each day opens with **30 minutes of revision** of the previous day, taken
from within that budget rather than added to it. Revision makes new material
land faster, so the trade is net positive — and without it, week 1 is
forgotten by week 4, which is exactly when it is needed.

Below ~80 hours this does not work from a near-zero start. The plan is costed at 99 hours.

**Split: 60% building, 25% concepts, 15% practice questions.** Practice questions are deliberately confined to week 4 — doing them earlier tests recall of material not yet built.

## 4. The two tiers

Fitting AWS into a month requires deciding what *not* to touch.

- **BUILD** (~25 services) — created, broken and fixed by hand. These are the ones an architect reasons about daily.
- **KNOW** (~30 services) — recognised and correctly chosen, never deployed. Snowball, Direct Connect, FSx and similar are exam-relevant and job-relevant as *decisions*, not as hands-on skills.

Attempting hands-on across all of AWS is the usual reason one-month attempts fail.

## 5. The spine

One architecture, grown over four weeks, rather than thirty disconnected tutorials.

```
Week 1   a server, inside a network built by hand
Week 2   survives an AZ failure, scales under load
Week 3   event-driven, encrypted, locked down
Week 4   monitored, cost-optimised, with a DR plan
```

By day 30 the learner has built the architecture the exam describes.

## 6. Cost discipline

Free tier is not free. The standard learner bill:

| Service | Cost if left running |
|---|---|
| NAT Gateway | ~$32/month + data — the most common surprise |
| Application Load Balancer | ~$16/month |
| Unattached Elastic IP | ~$3.60/month |
| RDS beyond free tier | varies |
| NLB, Fargate tasks, ElastiCache | small but nonzero |

**Rules:**
1. Budget alarm at $5 on day 1, before any resource is created.
2. Every lab has a teardown step, run the same day — the same contract as the networking labs.
3. Each day's entry states its cost risk explicitly.
4. Billing console checked every Monday.

## 7. Curriculum

100 hours across 30 days.

### Week 1 — Foundations you cannot fake (7 modules, ~24h)

- `01-01` Account safety and the IAM model: root lockdown, MFA, admin user, budget alarm, CloudTrail on. **Build:** secure the account end to end. **Cost:** $0
- `01-02` IAM in depth: identity vs resource policies, JSON anatomy, roles and trust, assume-role, **policy evaluation order (explicit Deny beats everything)**, conditions, permission boundaries. **Build:** hand-write a policy, attach a role to EC2, test with the CLI, break it deliberately and read the denial. Then two policies that do real work: **account-wide MFA enforcement** (`Deny` + `NotAction` + `BoolIfExists aws:MultiFactorAuthPresent`, with the lockout trap avoided) and a **budget action** that attaches a deny policy automatically when spending crosses a threshold. **Cost:** $0 · ~4h
- `01-03` VPC from scratch: CIDR choice, availability zones, subnets, route tables, internet gateway. A public subnet is only a route table entry. **Build:** a VPC with two public and two private subnets across two AZs, no wizard. **Cost:** $0
- `01-04` VPC egress and boundaries: NAT gateway, security groups vs NACLs, VPC endpoints. **Build:** private-subnet egress through NAT, then an S3 gateway endpoint that removes the need for it. **Cost:** NAT ~$0.045/hr — delete same day
- `01-05` EC2: instance families, purchasing options, AMIs, user data, key pairs, EBS volume types and snapshots. **Build:** launch into your own VPC, install nginx via user data, attach and snapshot a volume, bake an AMI. **Cost:** t3.micro free tier
- `01-06` S3: storage classes, lifecycle, versioning, bucket policy vs IAM, encryption options, static hosting, presigned URLs. **Build:** versioned bucket, lifecycle rule, static site, presigned URL, block public access. **Cost:** pennies
- `01-07` Week 1 build and review: a working web server in your own VPC reading from S3 **via an instance role, with no access keys anywhere**. **Cost:** small

### Week 2 — Resilient and scalable (7 modules, ~23h)

- `02-01` Load balancing: ALB vs NLB vs GWLB, listeners, target groups, health checks, path and host routing, stickiness, cross-zone. **Build:** ALB across two AZs, then terminate an instance and watch traffic move. **Cost:** ALB ~$0.0225/hr — delete same day
- `02-02` Auto Scaling: launch templates, target tracking vs step vs scheduled, health check types, cooldowns, lifecycle hooks. **Build:** an ASG behind the ALB, load the CPU, watch it scale out and back in. **Cost:** small
- `02-03` RDS: engines, **Multi-AZ vs read replicas** (the most-missed exam distinction), automated backups vs snapshots, subnet and parameter groups, encryption. **Build:** RDS in private subnets reachable only from the app tier; snapshot, restore, enable Multi-AZ. **Cost:** db.t3.micro free tier
- `02-04` DynamoDB: partition and sort keys, on-demand vs provisioned, GSI vs LSI, DAX, streams, TTL, global tables. **Build:** a table, then compare the cost of query vs scan on the same data. **Cost:** free tier
- `02-05` Storage and caching: EBS gp3/io2/st1/sc1, EFS vs EBS, FSx (know), ElastiCache Redis vs Memcached, Storage Gateway (know). **Build:** one EFS filesystem mounted on two instances at once. **Cost:** small
- `02-06` DNS and edge: Route 53 record types, alias vs CNAME, routing policies (simple, weighted, latency, failover, geolocation, multivalue), health checks; CloudFront origins, behaviours, OAC, cache keys, invalidation; Global Accelerator (know). **Build:** CloudFront in front of a private S3 bucket using OAC. **Cost:** small
- `02-07` Week 2 build: full three tier — CloudFront → ALB → ASG in private subnets → RDS Multi-AZ. **Then remove an AZ and prove it survives.** **Cost:** moderate — tear down fully

### Week 3 — Modern and secure (7 modules, ~23h)

- `03-01` Lambda and API Gateway: execution model, cold starts, memory and timeout, environment variables, layers, VPC attachment, concurrency and reserved concurrency; REST vs HTTP APIs, integrations, authorizers. **Build:** an API Gateway endpoint fronting a Lambda that reads DynamoDB. **Cost:** free tier
- `03-02` Messaging and events: SQS standard vs FIFO, visibility timeout, dead-letter queues, long polling; SNS fan-out; EventBridge buses and rules; Kinesis and Step Functions (know). **Choosing between SQS, SNS, EventBridge and Kinesis is a recurring exam question.** **Build:** SNS fanning out to two SQS queues feeding Lambdas; force a failure into the DLQ. **Cost:** free tier
- `03-03` Containers: ECR, ECS task definitions and services, Fargate vs EC2 launch type, EKS (know), and when a container beats a Lambda. **Build:** push an image to ECR and run it on Fargate behind the ALB. **Cost:** small — stop tasks same day
- `03-04` Encryption and secrets: KMS key types, envelope encryption, key policies vs IAM, rotation; Secrets Manager vs Parameter Store; ACM issuance and validation. **Build:** a customer-managed key, encrypt a bucket and a volume, move the database password into Secrets Manager and read it from Lambda. **Cost:** KMS $1/key/month — delete after
- `03-05` Security services: WAF rules and rate limiting, Shield Standard vs Advanced, GuardDuty, Inspector, Macie, Security Hub, Network Firewall (know). Which one detects, which one blocks, and where each sits. **Build:** a WAF rate-limit rule on the ALB, then trigger it deliberately. **Cost:** WAF ~$5/month — delete same day
- `03-06` Observability: CloudWatch metrics, logs, alarms, dashboards and Log Insights; CloudTrail for audit; Config for compliance; X-Ray (know). **Build:** a custom metric, an alarm that emails via SNS, a Log Insights query, and one Config rule. **Cost:** small
- `03-07` Week 3 build and review: make the week 2 architecture event-driven and encrypted end to end. **Cost:** moderate — tear down

### Week 4 — Architect decisions and exam shape (9 modules, ~30h)

- `04-01` Cost architecture: on-demand, reserved instances, Savings Plans, Spot; S3 storage class economics; **data transfer pricing**, which is the cost nobody predicts; Cost Explorer, budgets, Trusted Advisor, tagging. **Build:** analyse your own month's spend and set up tag-based cost allocation. **Cost:** $0
- `04-02` Resilience and disaster recovery: RTO and RPO defined properly, the four strategies (backup and restore, pilot light, warm standby, multi-site active-active) and their cost/recovery tradeoff, AWS Backup, cross-region replication. **Build:** a backup plan and cross-region S3 replication. **Cost:** small
- `04-03` Migration and hybrid: DMS, DataSync, the Snow family, Storage Gateway, Direct Connect, Site-to-Site VPN, Transit Gateway, PrivateLink, VPC peering. Mostly KNOW — the skill is matching tool to scenario. **Build:** peer two VPCs and route between them. **Cost:** $0
- `04-04` Multi-account and governance: Organizations, OUs, **SCPs vs IAM policies**, consolidated billing, Control Tower (know), IAM Identity Center, Resource Access Manager. **Build:** explore Organizations read-only; write an SCP on paper and predict its effect. **Cost:** $0
- `04-05` Decision tables: the "which service" comparisons the exam is built from — SQS vs SNS vs EventBridge vs Kinesis; ALB vs NLB; EBS vs EFS vs S3; RDS vs Aurora vs DynamoDB; Lambda vs Fargate vs EC2; Multi-AZ vs read replica vs multi-region. **Build:** write each table from memory, then check it. **Cost:** $0
- `04-06` Practice exam 1, then review **every** question — including the ones answered correctly by guessing. **Cost:** $0
- `04-07` Gap filling from exam 1: rebuild or re-read only the areas that failed. **Cost:** varies
- `04-08` Practice exam 2 and review. **Cost:** $0
- `04-09` Weak areas, final decision tables, practice exam 3, and the booking decision. **Cost:** $0

## 8. Method per day

0. **Revise — 30 minutes, before anything new.** Answer yesterday's recall
   questions from memory, then check against yesterday's page. A question
   answerable only by re-reading has not been learned; mark it and return to
   it the next day too. This is the single highest-return habit in the plan:
   recall produces retention, re-reading produces recognition.
1. **Concept** — what problem the service solves, before any clicking. 20–30 min.
2. **Build it** — console first for understanding, CLI second for repeatability. The majority of the time.
3. **Break it** — remove a permission, kill an instance, block a port. Read the error. This is where the understanding forms.
4. **Tear it down** — same day, without exception.
5. **Record** — notes to `docs/`, commands to `reference/cheatsheets/`, questions to `recall/`, and the day's page in `site/`.

Supplementary video is welcome as a *second* explanation after building, never as a replacement for it.

## 9. What happens to the networking curriculum

Parked, not deleted. `docs/phase-0-map/` and its lab stay where they are, and module `00-01` remains complete.

The work already done feeds directly into week 1:

| Already learned | Applies to |
|---|---|
| subnets, prefix lengths | VPC subnet design (`01-03`) |
| routing tables, direct vs via | VPC route tables (`01-03`) |
| ports and the TCP handshake | security group rules (`01-04`) |
| packets, DNS, TTL | Route 53 and VPC DNS (`02-06`) |

This is a real head start on the part of AWS that most learners find hardest.

The 83-module plan may be resumed after the exam decision. Its spec remains at `docs/superpowers/specs/2026-09-20-networking-curriculum-design.md`.

## 10. Deliverables

- One markdown note per day in `docs/week-N-*/`.
- **One HTML page per day** in `site/day-NN.html`, built the same day, so revision has something to check against. (Originally planned per week; changed on day 1 — weekly pages arrive too late to revise from.)
- Cheatsheets grown per day in `reference/cheatsheets/`, commands only after use.
- Recall questions per week in `recall/`.
- `PROGRESS.md` regenerated from this spec.

## 11. Out of scope

- Services outside the SAA-C03 blueprint.
- Terraform and infrastructure as code. Console and CLI only, to keep attention on the services themselves. IaC is the natural next project.
- CI/CD, Kubernetes operations, observability platforms beyond CloudWatch.
- Professional-level or specialty certification material.
- Exam booking itself, which is deferred to day 30 by the learner's choice.
