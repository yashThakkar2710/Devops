# Phase 0 — recall questions

Answer out loud or in writing **before** looking anything up.

## 00-01 · Journey of a request

1. A packet arrives at a router that has never seen your machine before.
   What does it need to carry so the router knows what to do with it?

2. Your machine and a server both have an IP address. Why is that not
   enough — what does the port add that the address cannot?

3. Port 53 means name lookups on every machine on earth. Why can that not
   simply be negotiated at the start of each conversation instead?

4. Your computer picked port 59573 at random for the lookup, then threw it
   away. What would break if it reused the same number every time?

5. In a tcpdump line, the reply looks identical to the question with the
   two ends swapped. Why is that enough for your computer to know which
   question is being answered?

6. A name lookup fails. Describe what the user sees, and what the capture
   shows. Why do these two look so different?

7. Why does the name lookup have to happen first, before anything else?

## Answers you should be able to derive, not recall

If you can only answer a question by re-reading the module, mark it and
return tomorrow. Recognition is not retention.

## 00-01 · lines 3–6 and the routing decision

8. Your machine has five addresses at once. Why is "what is my IP address"
   not a well-formed question?

9. `ip route get 8.8.8.8` prints `via 172.26.0.1`. What does the presence
   of that word tell you, and what would its absence tell you?

10. Your entire routing table is two lines, yet it can handle every address
    on the internet. How?

11. `curl` sent two name questions from the **same** source port, and the
    answers came back in the opposite order to the questions. What exactly
    stops the two replies being confused with each other?

12. Your machine asked for an IPv6 address, received a valid one, and then
    used IPv4. Was that a bug? What evidence would settle it?

13. Why does `dig` asking a name, and `curl` asking the same name moments
    later, produce two separate lookups rather than one?
