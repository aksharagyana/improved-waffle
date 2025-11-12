# GitLab CI Templates for Terraform Module Publishing

This repository contains reusable GitLab CI templates for validating and publishing Terraform modules to the GitLab Terraform Registry with semantic versioning support.

## Features

- **Automated Validation**: Runs `terraform fmt` and `terraform validate` on all PRs and commits
- **Security Scanning**: Optional tfsec and Checkov security scanning
- **Documentation Generation**: Automatic README.md updates with terraform-docs
- **Semantic Versioning**: Automatic version bumping based on conventional commit messages
- **Manual Publishing**: Manual trigger required for publishing to GitLab Registry
- **Git Tagging**: Automatic git tag creation and pushing

## Templates

### 1. terraform-validation.yml

Provides validation steps for Terraform modules:
- `terraform fmt` - Format checking
- `terraform validate` - Syntax and configuration validation
- `terraform_security_scan` - Security scanning with tfsec
- `terraform_docs` - Documentation generation

**Triggers on:**
- Pull requests
- Commits to any branch (except tags)

### 2. terraform-registry-publish.yml

Handles publishing to GitLab Terraform Registry:
- `determine_version` - Parses commit messages for semantic versioning
- `create_tag` - Creates and pushes git tags
- `build_module` - Packages the module
- `publish_to_registry` - Publishes to GitLab Registry

**Triggers on:**
- Manual trigger on main branch only

## Usage

### Basic Setup

1. Copy the templates to your Terraform module repository
2. Create a `.gitlab-ci.yml` file in your module root:

```yaml
stages:
  - validate
  - security
  - documentation
  - version
  - tag
  - build
  - publish

include:
  - local: 'templates/terraform-validation.yml'
  - local: 'templates/terraform-registry-publish.yml'
```

### Advanced Setup

For more control, use the example pipeline:

```yaml
stages:
  - validate
  - security
  - documentation
  - version
  - tag
  - build
  - publish

include:
  - local: 'templates/terraform-validation.yml'
  - local: 'templates/terraform-registry-publish.yml'

# Add your custom validation steps here
custom_validation:
  stage: validate
  image: hashicorp/terraform:latest
  script:
    - terraform init -backend=false
    - terraform plan -out=tfplan
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS
      when: never
    - if: $CI_COMMIT_BRANCH
      when: on_success
    - if: $CI_COMMIT_TAG
      when: never
```

## Semantic Versioning

The pipeline uses conventional commit messages to determine version bumps:

### Commit Message Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Version Bump Rules

- **Major (1.0.0 → 2.0.0)**: Breaking changes
    - `feat!: breaking change`
    - `fix!: breaking fix`
    - `BREAKING CHANGE:` in commit body

- **Minor (1.0.0 → 1.1.0)**: New features
    - `feat: new feature`
    - `feat(scope): new feature with scope`

- **Patch (1.0.0 → 1.0.1)**: Bug fixes and improvements
    - `fix: bug fix`
    - `perf: performance improvement`
    - `refactor: code refactoring`

### Examples

```bash
# Major version bump
git commit -m "feat!: change API interface"

# Minor version bump
git commit -m "feat: add new resource type"

# Patch version bump
git commit -m "fix: resolve validation error"
```

## Publishing Process

1. **Development**: Work on feature branches
2. **Validation**: Automatic validation on PRs and commits
3. **Merge**: Merge to main branch
4. **Manual Trigger**: Click "Run pipeline" on main branch
5. **Version Detection**: Pipeline analyzes commit messages
6. **Tagging**: Creates and pushes git tag
7. **Publishing**: Publishes to GitLab Terraform Registry

## Registry Access

After publishing, your module will be available at:
```
https://gitlab.com/<group>/<project>/-/terraform/modules
```

## Configuration

### Environment Variables

No additional environment variables are required. The pipeline uses:
- `CI_JOB_TOKEN` - Automatically provided by GitLab
- `CI_PROJECT_ID` - Automatically provided by GitLab
- `CI_API_V4_URL` - Automatically provided by GitLab

### Customization

You can customize the templates by:
1. Modifying the template files directly
2. Overriding jobs in your `.gitlab-ci.yml`
3. Adding additional validation steps

## Troubleshooting

### Common Issues

1. **Validation Fails**: Check your Terraform syntax and formatting
2. **Version Detection**: Ensure commit messages follow conventional format
3. **Registry Upload**: Verify GitLab permissions and project settings
4. **Tag Creation**: Ensure you have push permissions to the repository

### Debug Mode

Enable debug output by adding to your `.gitlab-ci.yml`:

```yaml
variables:
  TF_LOG: DEBUG
  TF_LOG_PATH: terraform.log
```

## Terraform Docs Configuration

This directory contains the default terraform-docs configuration used by the GitLab CI/CD templates.

### Default Configuration

The default configuration (`terraform-docs.yml`) is designed to generate only the **Inputs** and **Outputs** tables in the README.md file, which is the most common use case for Terraform modules.

### Default Settings

- **Formatter**: `markdown table`
- **Output**: Injects into README.md
- **Sections**: Only Inputs and Outputs (excludes providers, resources, requirements, data-sources)
- **Sorting**: By name (alphabetical)
- **Settings**: Standard formatting with anchors, descriptions, types, and required flags

### How It Works

1. **Automatic Detection**: The CI/CD pipeline automatically checks if your project has a custom `.terraform-docs.yml` or `.terraform-docs.yaml` file
2. **Default Fallback**: If no custom config is found, the pipeline creates a default configuration based on the template
3. **Custom Override**: Projects can provide their own configuration to override the default behavior


## Contributing

1. Create a feature branch
2. Make your changes
3. Test with your Terraform modules
4. Submit a pull request
