# Testing

This module is tested with the native [`terraform test`](https://developer.hashicorp.com/terraform/language/tests)
framework. Tests run automatically in GitHub Actions on every pull request to
any target branch and on pushes to `main` (see
`.github/workflows/terraform-test.yaml`).

## What runs in CI

| Job      | Command                              | Purpose                                         |
| -------- | ------------------------------------ | ----------------------------------------------- |
| Format   | `terraform fmt -check -recursive`    | Consistent formatting                           |
| Validate | `terraform init` + `terraform validate` | Syntax, types and references are valid      |
| Test     | `terraform test`                     | Module behaviour (defaults, wiring, validation) |

## How the tests work

- Test files live in `tests/` and end in `.tftest.hcl`.
- Every test file declares `mock_provider` blocks. Mocked providers never call
  Azure: no credentials are needed and **no real resources are created**.
  Resource attributes that Azure would compute (for example `id`) get generated
  fake values.
- Each `run` block plans (`command = plan`) or "applies" against the mocks
  (`command = apply`) with a set of input variables, then checks the result with
  `assert` blocks.
- Input validation is tested with `expect_failures`, which passes only when the
  listed variable validation or precondition fails.
- Data sources and nested modules that would need real lookups can be replaced
  with `override_data` / `override_module`.

- When tests run, the module is the *root* module. Terraform then rejects
  outputs that contain sensitive attributes unless they are marked
  `sensitive = true` (consumers calling the module are not affected). Put
  test-only override files in `tests/overrides/` named `*_override.tf`, e.g.

  ```hcl
  output "storage_account" {
    sensitive = true
  }
  ```

  CI copies them into the module root right before `terraform test`.

These are unit-style tests: they verify how the module turns inputs into
resource configuration. They do not prove that Azure accepts the configuration;
that still happens when a consuming workload runs `terraform plan`/`apply`.

## OpenTofu compatibility

CI currently runs Terraform only. The latest OpenTofu release checked (1.13.9)
cannot initialize this module: it rejects the `action_trigger` and `action`
blocks in `vm_power.tf`, and the `state_key` argument in the test suite. The
module also requires Terraform `~> 1.14`, which does not include OpenTofu 1.13.9.
The test workflow therefore does not claim OpenTofu compatibility. Do not remove
the production power-action behavior or weaken the version constraint to make an
OpenTofu run pass; enable OpenTofu only when the engine supports the complete
module and test configuration.

## Writing a test

```hcl
mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
}

run "defaults" {
  command = plan

  assert {
    condition     = azurerm_example.this.name == "expected"
    error_message = "Name should default to 'expected'."
  }
}

run "rejects_invalid_input" {
  command = plan

  variables {
    some_setting = "not-allowed"
  }

  expect_failures = [var.some_setting]
}
```

Guidelines:

- Add or update a test whenever you change behaviour, defaults or validation.
- Use obviously fake values (`rg-test`, `00000000-0000-0000-0000-000000000000`,
  documentation IP ranges such as `192.0.2.0/24`). Never use real subscription
  IDs, tenant IDs, names or addresses — this repository is public.
- Prefer one behaviour per `run` block with a descriptive name.

## Running locally

Requires Terraform `~> 1.14` for this module (mock-provider tests require
Terraform >= 1.7).

Run these commands from the module root. Initialization does not contact Azure.
The test-only override is needed because Terraform treats this module as the
root module during tests:

```sh
terraform init -backend=false
```

Copy the test-only output override into the module root. In PowerShell:

```powershell
Copy-Item tests\overrides\virtual_machine_output_override.tf .
```

In Bash (Linux/macOS):

```sh
cp tests/overrides/virtual_machine_output_override.tf .
```

Run the complete suite with `terraform test`. To run just this module's test
file, use the path separator for your shell/platform:

```powershell
terraform test '-filter=tests\virtual_machine.tftest.hcl'
```

```sh
terraform test -filter=tests/virtual_machine.tftest.hcl
```

A successful command is not enough by itself: confirm Terraform reports at least
one passing run, such as `Success! 14 passed, 0 failed` (the count may change as
tests are added). A command that exits successfully but runs zero tests does not
provide test coverage. The CI workflow enforces a nonzero passing-run count.
Remove the copied `*_override.tf` file after testing; it is git-ignored.

If the module references internal modules over SSH, you need SSH access to
GitHub for `terraform init` to download them.
