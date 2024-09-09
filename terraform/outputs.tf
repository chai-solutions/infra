output "api_server_public_ip" {
  description = "Public IP address of the API server"
  value       = aws_eip.public_server_ip_addr[0].public_ip
  depends_on  = [aws_eip.public_server_ip_addr]
}

output "api_server_public_url" {
  description = "Public DNS URL of the API server"
  value       = aws_eip.public_server_ip_addr[0].public_dns
  depends_on  = [aws_eip.public_server_ip_addr]
}

output "db_endpoint" {
  description = "Endpoint for database to connect to"
  value       = aws_db_instance.database.address
}

output "db_port" {
  description = "Database port"
  value       = aws_db_instance.database.port
}
