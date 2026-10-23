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

### Subnetting drills — do these cold, no notes

40. Give the slash for each: 128, 32, 512, 16, 64, 256, 1024 addresses.

41. How many *usable* addresses in a `/26`? A `/23`? Why not the full count?

42. You need 100 servers in one subnet. Smallest size that fits, and why
    not the next one down?

43. Split `10.0.7.0/24` into eight subnets. What slash, and what are the
    first four starting addresses?

44. Is `10.0.1.100` inside `10.0.1.64/26`? Show how you decided.

45. Why is `10.0.1.50/26` invalid?

46. Four subnets of ~250 servers each. Subnet size, total space, and the
    smallest VPC CIDR that fits.

47. The exam answer to 46 and the real-world answer differ. Say both, and
    say why.

### VPC design method

48. What is the *only* reason to put two things in separate subnets?

49. App servers and the database are both private, so their rules match
    today. Why separate them anyway?

50. Why does the load balancer subnet need addresses when none of your
    servers go in it?

51. Why is the app tier usually the largest subnet, and the database the
    smallest? Both answers surprise people.

52. Lay out subnets for 500, 60 and 60 servers from `10.0.0.0`, largest
    first. Then do it smallest first and say exactly what gets wasted.

53. Why can a `/23` not start at `10.0.1.0`? Give the test you would use.

54. Why is that not an AWS policy but a property of how addressing works?

55. Does AWS divide a VPC address range between availability zones? When
    does the zone actually get decided?

56. Give the argument for grouping subnets by zone rather than by tier.

57. Is `ap-south-1a` the same building for every AWS account? What is the
    stable identifier, and when does the difference matter?

58. Our VPC uses `/24` for every subnet, ignoring the sizing method.
    Defend that choice, then say when it would be the wrong one.

59. Why are `10.0.3.0/24` through `10.0.10.0/24` left empty on purpose?

## 01-04 · NAT, security groups, NACLs and endpoints

60. Why is `0.0.0.0/0 -> internet gateway` the wrong fix for a private
    subnet that needs software updates?

61. Your laptop reaches the internet but the internet cannot reach your
    laptop. Explain the mechanism - and why no firewall rule is involved.

62. Would a NAT gateway work in a private subnet if you gave it an Elastic
    IP? Explain precisely what would happen.

63. Name the two independent things required before anything is reachable
    from the internet. What happens with only one of them?

64. Your NAT is in `public-1a`. Building A fails. What happens to
    `private-1b`, and why is that outcome surprising?

65. What is the standard fix for that, and what does it cost? Why do many
    small setups not bother?

66. You allow port 443 inbound on a security group. Do you need an
    outbound rule? What about on a NACL? Explain the difference.

67. Why are NACLs stateless while security groups are stateful? Give the
    design reason, not just the fact.

68. You want to block one specific IP address from a whole subnet. Which
    tool, and why can the other one structurally not do it?

69. A NACL has `100 ALLOW 0.0.0.0/0` and `200 DENY 1.2.3.4`. Is 1.2.3.4
    blocked? What rule are you applying?

70. Two servers sit in the same subnet. Can one accept web traffic while
    the other refuses it? Why?

71. Something cannot connect to your server. Name the three things you
    check, in order, and say why that order.

72. Why is a gateway endpoint free when an interface endpoint is not?

73. Both endpoint types now exist for S3. How do you tell which one an exam
    question is asking for?

74. What is a `pl-` prefix list, and why reference one instead of writing
    IP ranges yourself?

75. A route table shows a target marked **Blackhole**. What does that mean,
    and what question does it usually answer?

76. You delete a NAT gateway. Name the two things left behind and what each
    costs you.

## 01-05 · EC2, EBS and AMIs

77. Name the three independent things required before the internet can
    reach a server. What happens when only two are present?

78. Why is auto-assign public IP off by default in a subnet you built, but
    on in the default VPC?

79. Your server reports its IP as `10.0.1.238` but you reach it at
    `13.233.89.217`. Explain what is happening and where.

80. You launch from an AMI with no user data at all, and nginx is already
    running. Why?

81. The page served by web-2 shows web-1's hostname. Explain exactly why,
    and say what general rule that gives you about AMIs.

82. When would you use user data rather than bake something into an AMI?
    Give the Auto Scaling argument for the other direction.

83. Why can an EBS volume not be attached to an instance in a different
    availability zone - and how do you move it there anyway?

84. You stop an instance. What happens to data on EBS? On instance store?
    Why are they different?

85. Why did gp3 replace gp2? What problem did gp2 create for customers?

86. One connection hangs and times out; another says "connection refused"
    instantly. What does each tell you, and why do they need opposite
    fixes?

87. Why do firewalls drop packets rather than rejecting them?

88. You deregister an AMI. What is left behind, what does it cost, and why
    does the console not clean it up by default?

89. You terminate an instance with a root volume and one extra volume
    attached. What happens to each?

90. Nightly video processing that can restart if interrupted - which
    purchasing option? Why would the same option be wrong for a database?

91. Your browser times out but `curl` works from the same machine, to the
    same address. What have you proven, and where do you look next?

92. Walk the seven-step diagnosis from this day from memory. What did each
    step eliminate?
