# Week 1 — recall questions

Answer out loud or in writing **before** looking anything up. A question you
can only answer by re-reading is one you have not learned yet. Mark it and
return tomorrow.

## 01-01 · Account safety and the IAM model

1. Root cannot be restricted by any policy. Why would AWS design it that
   way, rather than letting you lock it down?

2. You have MFA on root. Someone obtains a root **access key**. Are you
   protected? Explain precisely why or why not.

3. Your budget is set to $5. You spend $40 overnight. What does AWS do?

4. Given that, what actually protects you from a large bill?

5. You are a full administrator but the billing page says access denied.
   What is going on, and why does AWS separate these two things?

6. You launch an instance in Mumbai. Tomorrow the console shows no
   instances. Give two possible explanations and say how you would tell
   them apart.

7. You created an IAM user 20 minutes ago, but CloudTrail Event history in
   Mumbai does not show it. Why not?

8. Read this and say what it is and where it lives:
   `arn:aws:iam::639679388494:user/yash-admin`
   Why is one of its fields empty?

9. You are the only person using this account. Why put yourself in a group
   rather than attaching the policy directly?

10. Why was a zero-spend budget chosen here instead of a $5 monthly budget?

11. `AdministratorAccess` is close to root power. Name two things it still
    cannot do that root can — and why that difference matters.
