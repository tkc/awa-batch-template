variable "repository_name" {
  description = "ECRリポジトリの名前"
  type        = string
}

variable "image_tag_mutability" {
  description = "タグの変更可否設定（MUTABLE または IMMUTABLE）"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "イメージプッシュ時にスキャンを行うかどうか"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "暗号化タイプ（AES256 または KMS）"
  type        = string
  default     = "AES256"
}

variable "kms_key" {
  description = "KMS鍵のARN（encryption_typeがKMSの場合に必要）"
  type        = string
  default     = null
}

variable "lifecycle_policy" {
  description = "ECRライフサイクルポリシー（JSON形式）"
  type        = string
  default     = ""
}

variable "repository_policy" {
  description = "ECRリポジトリポリシー（JSON形式）"
  type        = string
  default     = ""
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}
