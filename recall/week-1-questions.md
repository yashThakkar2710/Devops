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

## 01-02 · IAM in depth

12. You hold `AdministratorAccess`. One more policy denies
    `s3:DeleteBucket`. Can you delete a bucket? Can you still terminate EC2
    instances? Explain the rule you are applying.

13. Why can you not enforce a rule using only `Allow`? What does that imply
    about how security teams and delivery teams use policies differently?

14. A policy grants `s3:ListBucket` on `arn:aws:s3:::reports/*`. What can
    the holder actually do, and why is this a bug that looks correct?

15. Why might you deliberately grant `GetObject` without `ListBucket`? What
    does that change for an attacker who steals the credential?

16. Explain the difference between `Bool` and `BoolIfExists`. Which
    real-world credential does that difference protect against, and why?

17. Why does the MFA enforcement policy use `NotAction` rather than
    `Action`? What breaks without the carve-out?

18. Your first test user created an S3 bucket despite the policy existing.
    What was wrong, and what is the general lesson?

19. Name the two policies a role has. Which one does a user never need, and
    why not?

20. You are an administrator. You assume a read-only role and EC2 refuses
    you. Why — and is that a bug?

21. Read this and say everything it tells you:
    `arn:aws:sts::639679388494:assumed-role/S3ReadOnlyRole/yash-admin`

22. Two denial messages: "no identity-based policy allows" versus "explicit
    deny in a policy". What is different, and why do they need opposite
    fixes?

23. Why is a stolen role credential less dangerous than a stolen access
    key? Give two reasons.

24. Why does a budget breaker that denies everything end up protecting you
    *less* than one that denies only creation?

25. Attaching a policy takes effect instantly on an existing session, but
    MFA status does not change mid-session. Why are these different?

## 01-03 · A VPC from scratch

26. How can two different companies both use `10.0.0.0/16` without any
    conflict? What makes that possible?

27. Your server is `10.0.1.50`. Someone in another country types that
    address into their browser. What happens, and why is that the first
    layer of security?

28. Why is a bigger slash number a *smaller* range?

29. What does `0.0.0.0/0` mean literally, and why does that make it the
    catch-all in a route table?

30. A packet is going to `10.0.2.99`. The route table has both
    `10.0.0.0/16 → local` and `0.0.0.0/0 → igw`. Which line wins, and what
    rule are you applying?

31. You create an internet gateway and attach it to your VPC. Can your
    servers reach the internet now? Explain precisely.

32. What single change turns a private subnet into a public one?

33. Why should an internet route never be added to the main route table?

34. Why can a subnet not span two availability zones?

35. A server sits in a public subnet with a correct route. The internet
    still cannot reach it. What else is missing?

36. Your private subnet needs to download software updates. Why can you not
    simply add a route to the internet gateway?

37. Why can a VPC's CIDR never be changed after creation?

38. A subnet is named `public-1a` and nothing can reach the internet from
    it. Give the most likely cause.

39. On day 1 we concluded billing access was already enabled because the
    Budgets page loaded. It was not. What was wrong with that test, and what
    is the general lesson?
