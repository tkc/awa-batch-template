output "vpc_endpoint_security_group_id" {
  description = "ID of the security group for VPC endpoints"
  value       = aws_security_group.vpc_endpoints.id
}

output "flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = aws_flow_log.main.id
}

output "flow_log_group_name" {
  description = "Name of the CloudWatch Log Group for VPC Flow Logs"
  value       = aws_cloudwatch_log_group.flow_log.name
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = [aws_nat_gateway.nat.id]
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = [aws_route_table.private.id]
}

output "public_route_table_id" {
  description = "ID of public route table"
  value       = aws_route_table.public.id
}

output "vpc_endpoint_s3_id" {
  description = "ID of S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}
