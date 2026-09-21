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

## 00-01 · the handshake, RTT and TTL

14. After two packets of the handshake, one side is still uncertain about
    something. Which side, and what?

15. Why is four packets unnecessary, given that three are required?

16. Packet 7 has `seq 639031898` and packet 8 has `ack 639031899`. Explain
    the difference of one.

17. Your name lookup needed no handshake, but the page fetch did. What
    property of the two conversations causes that difference?

18. Pinging `127.0.0.1` gives 0.043 ms rather than 0 ms. What is being
    measured?

19. A reply arrives with `ttl=52`. What can you conclude, and what
    assumption does that conclusion rest on?

20. A traceroute shows `* * *` at hops 9 and 10, then a normal reply at
    hop 11. Is the path broken? How do you know?

21. Hop 5 of a traceroute reports 113 ms; the final hop reports 31 ms.
    Explain how that is possible without either number being wrong.

22. In one traceroute hop, two different addresses replied. What does that
    tell you, and which earlier observation in the same capture does it
    explain?
