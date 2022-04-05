resource "aws_route53_zone" "main" {
  name = "awssession.ml"
force_destroy="true"  

}

# resource "aws_route53_record" "blog-ns" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = "blog.awssession.ml"
#   type    = "NS"
#   ttl     = "30"
#   records = aws_route53_zone.dev.name_servers
# }