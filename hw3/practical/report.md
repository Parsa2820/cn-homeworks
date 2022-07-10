# Part 4 Questions
## DNS Flood Protection
DNS flooding attack is a type of distributed denial of service attack that is used to attack a DNS server. In this attack, a malicious user sends a large number of requests to a DNS server(s) belonging to a target zone. 
As the result resolution of the zone and its sub-zones resources get slower and slower untill the DNS server stops responding. The most effective way to mitigate this kind of ditributed attacks, is to learn attack patterns with machine learning algorithms and use thme to detect attacks.

## SYN Flood Protection
SYN flooding attack is a type of denial of service attack in which attacker starts lots of connections to a target server without closing them. This cause the server to run out of resources and stop responding.
In order to stop this attack, we limit the number of connections that an IP address can make to a server. This is also done in the script with `iptables` command.

## Slowloris Protection
Slowloris is a denial of service attack program that make lots of HTTP  connections to a server and keep them open as long as possible. This attack can also be solved by the technique mentioned in the previous section and is implemented in the script.

# Part 6 Question
## Can user defeat port knocking with PC?
As we previously know, there are $2^{16}$ possible ports on a computer. So, if we want to defeat port knocking with length three, we need to try $2^{16} \times 2^{16} \times 2^{16}$ different combinations. If we knock 10 port in 1 second on regular PC, it took 
$$\frac{2^{16} \times 2^{16} \times 2^{16}}{10 \times 60 \times 60 \times 24 \times 365} \approx 892551(years)$$
to test all possible combinations. Considering configured port knocking can have different lengths other than three, it is almost impossible to defeat port knocking with PC.
