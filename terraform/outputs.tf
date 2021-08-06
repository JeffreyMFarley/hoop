output "cloudfront_id" {
  value = module.static_web.cloudfront_id
}

output "image_repo_fortunes" {
  value = module.image_repo["fortunes"].repo_url
}

output "image_repo_heroes" {
  value = module.image_repo["heroes"].repo_url
}

output "image_repo_names" {
  value = module.image_repo["names"].repo_url
}

output "url_static_web" {
  value = module.static_web.endpoint
}

output "url_api" {
  value = module.rest_api.main_url
}

output "static_web_bucket" {
  value = module.www_buckets[var.name].name
}

output "POSTGRES_USER" {
  value = module.db.user
}

output "POSTGRES_DB" {
  value = module.db.db_name
}

output "POSTGRES_HOST" {
  value = module.db.host
}
