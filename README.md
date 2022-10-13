# itsalwaysdns

If you've spent a fair amount of time diagnosing issues with web services, chances are you've heard the running joke, "It's always DNS!" - an oft-overlooked, fundamental step when diagnosing a problem.

I've used that as my motivation to create this script!
## Features

* Simple DNS checks for the domain/hostname provided
* Iterates over each nameserver, from each resolver that you've defined
* Prints a hash for each DNS result, to make comparison easy
* Checks the SSL certificate of each resultant, unique IP address and prints the certificate's CN, expiry date and fingerprint, also to allow for easy comparison

See the example below for the kind of output you may expect.
## Usage

1. Clone this repo and change directory

```
git clone https://github.com/curtis86/itsalwaysdns && cd itsalwaysdns
```

2. Edit `itsalwaysdns.conf` and set the resolvers you'd like to use - if you're not sure, you can keep the defaults here (public recursive resolvers), or use `nameservers` from your `/etc/resolv.conf`

3. Run the script, substituting `example.com` with the domain you wish to check:

```
./itsalwaysdns example.com
```

## Example

Note: in this check, we're only testing against one resolver (Cloudflare's 1.1.1.1)

```
*** DNS Report for microsoft.com (Fri 14 Oct 2022 00:16:04 AEDT) ***

[+]  Got 4 delegated nameservers and 4 nameserver records
[+]  Delegated nameserver and nameserver records match.

TCP Check:

[+]  ns1-39.azure-dns.com is reachable on TCP/port 53
[+]  ns2-39.azure-dns.net is reachable on TCP/port 53
[+]  ns3-39.azure-dns.org is reachable on TCP/port 53
[+]  ns4-39.azure-dns.info is reachable on TCP/port 53

DNS Results:

[+]  -> 1.1.1.1 --> ns1-39.azure-dns.com ---> microsoft.com (A):
[+]  20.103.85.33
[+]  20.112.52.29
[+]  20.53.203.50
[+]  20.81.111.85
[+]  20.84.181.62
[+]  Dns result hash: 10de294cf4b056ac53b0465f528d5eda4604c7f7520e0b3e778d8e3cf288057a

[+]  -> 1.1.1.1 --> ns2-39.azure-dns.net ---> microsoft.com (A):
[+]  20.103.85.33
[+]  20.112.52.29
[+]  20.53.203.50
[+]  20.81.111.85
[+]  20.84.181.62
[+]  DNS result hash: 10de294cf4b056ac53b0465f528d5eda4604c7f7520e0b3e778d8e3cf288057a

[+]  -> 1.1.1.1 --> ns3-39.azure-dns.org ---> microsoft.com (A):
[+]  20.103.85.33
[+]  20.112.52.29
[+]  20.53.203.50
[+]  20.81.111.85
[+]  20.84.181.62
[+]  DNS result hash: 10de294cf4b056ac53b0465f528d5eda4604c7f7520e0b3e778d8e3cf288057a

[+]  -> 1.1.1.1 --> ns4-39.azure-dns.info ---> microsoft.com (A):
[+]  20.103.85.33
[+]  20.112.52.29
[+]  20.53.203.50
[+]  20.81.111.85
[+]  20.84.181.62
[+]  DNS result hash: 10de294cf4b056ac53b0465f528d5eda4604c7f7520e0b3e778d8e3cf288057a

SSL fingerprints:
[+]  20.103.85.33 has 8e9b491366cd7dbacc7b03c2e31e0b1c4934d4f11844238a86dde46e3987fed4 (CN: microsoft.com, Expiry: Oct  6 17:40:31 2023 GMT)
[+]  20.112.52.29 has 8e9b491366cd7dbacc7b03c2e31e0b1c4934d4f11844238a86dde46e3987fed4 (CN: microsoft.com, Expiry: Oct  6 17:40:31 2023 GMT)
[+]  20.53.203.50 has 8e9b491366cd7dbacc7b03c2e31e0b1c4934d4f11844238a86dde46e3987fed4 (CN: microsoft.com, Expiry: Oct  6 17:40:31 2023 GMT)
[+]  20.81.111.85 has 8e9b491366cd7dbacc7b03c2e31e0b1c4934d4f11844238a86dde46e3987fed4 (CN: microsoft.com, Expiry: Oct  6 17:40:31 2023 GMT)
[+]  20.84.181.62 has 8e9b491366cd7dbacc7b03c2e31e0b1c4934d4f11844238a86dde46e3987fed4 (CN: microsoft.com, Expiry: Oct  6 17:40:31 2023 GMT)
```

### Notes

* This has only been tested on a few common TLDs, behaviour of others is unknown
* Subdomain checks are mostly working, but to how many levels has not been tested yet
* Metadata returned from DNS lookups need to be further assesed, the current implentation is still quite simple
* SSL CN check is simply the Subject field, it does not yet support Subject Alternative Name (SAN)
* More checks will be added later, ie. MX record, SSL cipher and TLS versions, HTTP content
* Docker container coming soon!