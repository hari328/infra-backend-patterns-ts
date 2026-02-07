# DNS + SSL (Route53 + ACM)

## DNS — Route53

### What it does
Translates human-readable names to IP addresses.

```
api.yourdomain.com → 54.23.100.12 (ALB's IP)
grafana.yourdomain.com → 54.23.100.12 (same ALB, different listener rule)
```

### What you create
1. **Hosted Zone** — a container for your domain's DNS records
2. **A/ALIAS records** — point subdomains to your ALB

```
Route53 Hosted Zone: yourdomain.com
  ├── api.yourdomain.com     → ALB
  ├── grafana.yourdomain.com → ALB
  └── prometheus.yourdomain.com → ALB
```

All subdomains point to the same ALB. The ALB then uses listener rules to route to the right service.

### Where you buy the domain
Anywhere (Namecheap, Google Domains, Route53 itself). You just point the domain's nameservers to Route53.

---

## SSL — ACM (AWS Certificate Manager)

### What it does
Gives you a free SSL certificate so your site works on HTTPS.

### What you create
One **wildcard certificate**: `*.yourdomain.com`

This single cert covers ALL subdomains — api, grafana, prometheus, anything you add later.

### Who does SSL termination?
**The ALB.** This is the key point.

```
User (HTTPS) → ALB (terminates SSL here, decrypts) → ECS Task (plain HTTP, port 3000)
```

- The ALB holds the SSL cert
- It decrypts incoming HTTPS traffic
- It forwards plain HTTP to your containers
- Your app code never deals with SSL — it just listens on HTTP

### How does AWS know you own the domain? (SSL Validation)

When you request a cert from ACM, AWS says: "prove you own this domain."

**DNS validation** (recommended):
1. You request `*.yourdomain.com` cert from ACM
2. ACM says: "create this DNS record to prove ownership"
   - Something like: `_abc123.yourdomain.com → _def456.acm-validations.aws`
3. Terraform creates that record in your Route53 hosted zone automatically
4. ACM checks the record, confirms you own the domain, issues the cert
5. The validation record stays forever — ACM auto-renews the cert every year

This all happens in Terraform — no manual steps:

```hcl
# Request the cert
resource "aws_acm_certificate" "main" {
  domain_name       = "*.yourdomain.com"
  validation_method = "DNS"
}

# Create the validation DNS record in Route53
resource "aws_route53_record" "cert_validation" {
  zone_id = aws_route53_hosted_zone.main.zone_id
  name    = aws_acm_certificate.main.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.main.domain_validation_options[0].resource_record_type
  records = [aws_acm_certificate.main.domain_validation_options[0].resource_record_value]
  ttl     = 60
}

# Wait for validation to complete
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}
```

### The flow
```
1. Terraform creates ACM cert request
2. Terraform creates DNS validation record in Route53
3. ACM verifies the record → issues cert
4. ALB HTTPS listener uses this cert
5. ACM auto-renews forever — zero maintenance
```

## Terraform resources

| Resource | Purpose |
|---|---|
| `aws_route53_zone` | Hosted zone for your domain |
| `aws_route53_record` | DNS records (A/ALIAS to ALB, validation records) |
| `aws_acm_certificate` | Wildcard SSL cert |
| `aws_acm_certificate_validation` | Waits for cert to be validated |

## Cost
- Route53 hosted zone — $0.50/month
- ACM certificate — **free**
- DNS queries — $0.40 per million queries (negligible)

