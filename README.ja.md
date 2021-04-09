[![test](https://github.com/reireias/rails-on-ecs/workflows/test/badge.svg)](https://github.com/reireias/rails-on-ecs/actions) [![lint](https://github.com/reireias/rails-on-ecs/workflows/lint/badge.svg)](https://github.com/reireias/rails-on-ecs/actions) [![build](https://github.com/reireias/rails-on-ecs/actions/workflows/build.yml/badge.svg)](https://github.com/reireias/rails-on-ecs/actions/workflows/build.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# rails-on-ecs
Rails on AWS ECS を構築する Ruby on Rails の実装です。

Terraform リポジトリ: [reireias/rails-on-ecs-terraform](https://github.com/reireias/rails-on-ecs-terraform)

## Tips

### イメージビルド
GitHub Actionsでイメージビルドを行います。

[docker/build-push-action](https://github.com/docker/build-push-action) を利用することで、イメージビルドとプッシュを簡潔に記述できます。

[Dockerfile](Dockerfile) の実装のようにマルチステージビルドを利用する実装になっています。

最終的なイメージ以外にbuilderステージもECRをプッシュし、 `--cache-from` オプションに指定することで、次のビルド時にキャッシュとして利用できるようにしています。

```yml
      # cache-from に前回の builder ステージのイメージを指定
      - name: Build and Push
        uses: docker/build-push-action@v2
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        with:
          push: true
          cache-from: |
            type=registry,ref=${{ env.ECR_REGISTRY }}/${{ env.ECR_REPOSITORY }}:builder
          tags: |
            ${{ env.ECR_REGISTRY }}/${{ env.ECR_REPOSITORY }}:${{ github.sha }}
            ${{ env.ECR_REGISTRY }}/${{ env.ECR_REPOSITORY }}:latest

      # 今回のbuilderイメージを保存
      - name: Save builder cache
        uses: docker/build-push-action@v2
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        with:
          target: builder
          push: true
          build-args: |
            BUILDKIT_INLINE_CACHE=1
          tags: |
            ${{ env.ECR_REGISTRY }}/${{ env.ECR_REPOSITORY }}:builder
```

### ヘルスチェック
[okcomputer](https://github.com/sportngin/okcomputer) gem を利用することで、ヘルスチェックをシンプルに設定できます。

`/health_checks/all` にアクセスすることで、追加で指定したDB等へのヘルスチェックも行えるため疎通確認や障害の調査などで非常に便利です。

### 環境変数から読み込む
以下は環境変数から読み込むようにすることで、特定のインフラとの密結合を避けています。

- データベースの接続情報: `DATABASE_URL`
- データベースの接続情報(リードレプリカ): `READER_DATABASE_URL`

また、秘匿情報をセキュアに管理するため、 `RAILS_MASTER_KEY` も環境変数で受け取るようにしています。
