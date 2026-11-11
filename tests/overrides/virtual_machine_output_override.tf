# Test-only override, copied into the module root by CI before `terraform test`.
# The VM object contains admin_password, which must be marked sensitive when the
# module is the root module under test.
output "virtual_machine" {
  sensitive = true
}
