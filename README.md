[![test](https://github.com/reireias/rails-on-ecs/workflows/test/badge.svg)](https://github.com/reireias/rails-on-ecs/actions) [![lint](https://github.com/reireias/rails-on-ecs/workflows/lint/badge.svg)](https://github.com/reireias/rails-on-ecs/actions) [![build](https://github.com/reireias/rails-on-ecs/actions/workflows/build.yml/badge.svg)](https://github.com/reireias/rails-on-ecs/actions/workflows/build.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**[日本語 | Jpanese](README.ja.md)**

# rails-on-ecs
Example code for Ruby on Rails with AWS ECS.

Terraform Repository: [reireias/rails-on-ecs-terraform](https://github.com/reireias/rails-on-ecs-terraform)

## Tips

## Image builds
GitHub Actions are used to build images.

You can use [docker/build-push-action](https://github.com/docker/build-push-action) to describe image build and push in a concise way.

The implementation uses multi-stage build like the implementation in [Dockerfile](Dockerfile).

In addition to the final image, the builder stage also pushes the ECR, which can be used as a cache for the next build by specifying the `--cache-from` option.

```yml
      # cache-from is the image of the previous builder stage
      - name: Build and Push
        uses: docker/build-push-action@v2
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        with:
          push: true
          cache-from: |{ steps.login-ecr.outputs.registry }} with: push: true
            type=registry,ref=${{ env.ECR_REGISTRY }}/${{ env.ECR_REPOSITORY }}:builder
          tags: |
            ${{ env.ECR_REGISTRY }}/${{ env.ECR_REPOSITORY }}:${{ github.sha }}
            ${{ env.ECR_REGISTRY }}/${{ env.ECR_REPOSITORY }}:latest

      # Save the builder image for this time
      - name: Save builder cache
        uses: docker/build-push-action@v2
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        with:
          target: builder
          push: true
          build-args: |
            BUILDKIT_INLINE_CACHE=1
          tags: |{ env.
            ${{ env.ECR_REGISTRY }}/${{ env.ECR_REPOSITORY }}:builder
```

### health check
You can use the [okcomputer](https://github.com/sportngin/okcomputer) gem to set up health checks in a simple way.

By accessing `/health_checks/all`, you can also perform health checks on additional specified DBs, etc. This is very useful for checking communication and investigating failures.

### Load from environment variables
The following are read from environment variables to avoid tight coupling with specific infrastructure.

- Database connection information: `DATABASE_URL`.
- Database connection information (read replica): `READER_DATABASE_URL`.

Also, `RAILS_MASTER_KEY` is set as an environment variable for secure management of confidential information.
