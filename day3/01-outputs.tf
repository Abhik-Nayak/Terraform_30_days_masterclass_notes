output "account_id"{
    value = data.aws_caller_identity.current.account_id
}
output "bucket_arn"{
    value = aws_s3_bucket.my_bucket.arn
}
output "bucket_region"{
    value = aws_s3_bucket.my_bucket.region
}
output "default_vpc_id"{
    value = data.aws_vpc.default.id
}
output "logs_bucket_arn"{
    value = aws_s3_bucket.logs.arn
}

output "multi_buckets_arns"{
    value = aws_s3_bucket.multi[*].arn
}

output "env_bucket_ids" {
    value = {for k, v in aws_s3_bucket.env_buckets : k => v.id}
}