# Part 4 Questions
## DNS Flood Protection

## Slowloris Protection

## SYN Flood Protection

# Part 6 Question
## Can user defeat port knocking with PC?
As we previously know, there are $2^{16}$ possible ports on a computer. So, if we want to defeat port knocking with length three, we need to try $2^{16} \times 2^{16} \times 2^{16}$ different combinations. If we knock 10 port in 1 second on regular PC, it took 
$$\frac{2^{16} \times 2^{16} \times 2^{16}}{10 \times 60 \times 60 \times 24 \times 365} \approx 892551(years)$$
to test all possible combinations. Considering configured port knocking can have different lengths other than three, it is almost impossible to defeat port knocking with PC.
