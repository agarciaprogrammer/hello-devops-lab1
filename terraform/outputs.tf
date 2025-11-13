output "s3_frontend_url" {
  value = aws_s3_bucket_website_configuration.frontend.website_endpoint
}

output "ec2_public_ip" {
  value = aws_instance.api_server.public_ip
}
