# S3バケット
resource "aws_s3_bucket" "main" {
  bucket = var.s3_bucket_name != null ? var.s3_bucket_name : "${local.name_prefix}-data-${random_string.bucket_suffix.result}"
  
  tags = local.common_tags
}

# ランダムな文字列（S3バケット名をユニークにするため）
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3バケットの暗号化設定
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3バケットのライフサイクル設定
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  
  rule {
    id     = "cleanup-old-data"
    status = "Enabled"
    
    # 60日後にStandard-IAに移行
    transition {
      days          = 60
      storage_class = "STANDARD_IA"
    }
    
    # 180日後にGlacierに移行
    transition {
      days          = 180
      storage_class = "GLACIER"
    }
    
    # 365日後に削除
    expiration {
      days = 365
    }
  }
}

# S3バケットのパブリックアクセスブロック設定
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3バケットのフォルダー構造
resource "aws_s3_object" "input_folder" {
  bucket = aws_s3_bucket.main.id
  key    = "input/"
  source = "/dev/null"  # ダミーファイル（フォルダのみを作成するため）
}

resource "aws_s3_object" "output_folder" {
  bucket = aws_s3_bucket.main.id
  key    = "output/"
  source = "/dev/null"  # ダミーファイル（フォルダのみを作成するため）
}

resource "aws_s3_object" "logs_folder" {
  bucket = aws_s3_bucket.main.id
  key    = "logs/"
  source = "/dev/null"  # ダミーファイル（フォルダのみを作成するため）
}