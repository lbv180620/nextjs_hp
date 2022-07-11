include Makefile.env

# 擬似ターゲット
# .PHONEY:

ps:
	docker compose ps

# ==== プロジェクトの立ち上げ ====

# launch:
# 	@make file-set
# 	@make publish-phpmyadmin
# 	@make publish-redisinsight
# 	@make build
# 	@make up
# 	@make useradd
# 	@make db-set

launch:
	cp env/.env.example .env
	@make build
	@make up
	@make useradd-client


file-set:
	mkdir -p sqls/{sql,script} infra/{data,redis} && \
		touch sqls/sql/query.sql sqls/script/set-query.sh && \
		cp env/.env.example .env && \
		mkdir .vscode && cp env/{launch.json,settings.json} .vscode
		mkdir backend
# mkdir backend frontend

# phpMyAdmin
publish-phpmyadmin:
	mkdir -p ./infra/phpmyadmin/sessions
	sudo chown 1001 ./infra/phpmyadmin/sessions

# redisinsight
publish-redisinsight:
	mkdir -p ./infra/redisinsight/sessions
	sudo chown 1001 ./infra/redisinsight/sessions

db-set:
	docker compose exec db bash -c 'mkdir /var/lib/mysql/sql && \
		touch /var/lib/mysql/sql/query.sql && \
		chown -R mysql:mysql /var/lib/mysql'

useradd:
# web-root
	docker compose exec web bash -c ' \
		useradd -s /bin/bash -m -u $$USER_ID -g $$GROUP_ID $$USER_NAME'
# db-root
	docker compose exec db bash -c ' \
		useradd -s /bin/bash -m -u $$USER_ID -g $$GROUP_ID $$USER_NAME'
groupadd:
# web-root
	docker compose exec web bash -c ' \
		groupadd -g $$GROUP_ID $$GROUP_NAME'
# db-root
	docker compose exec db bash -c ' \
		groupadd -g $$GROUP_ID $$GROUP_NAME'

useradd-client:
# client-root
	docker compose exec client bash -c ' \
		useradd -s /bin/bash -m -u $$USER_ID -g $$GROUP_ID $$USER_NAME'
groupadd-client:
# client-root
	docker compose exec client bash -c ' \
		groupadd -g $$GROUP_ID $$GROUP_NAME'
webpack-set:
	mkdir -p $(env)/src/{scripts,styles,templates,images}
	cp -r env/webpack-$(env)/{*,.eslintrc.js,.prettierrc} $(env)/
	mkdir $(env)/src/styles/scss
	mv $(env)/styles/* $(env)/src/styles/scss/
	rm -rf $(env)/styles
	mv $(env)/setupTests.ts $(env)/src/
	mkdir $(env)/public
	cp env/.htaccess $(env)/public/

webpack-del:
	rm -r $(env)/{webpack,webpack.common.js,webpack.dev.js,webpack.prod.js,jsconfig.json,tsconfig.json,babel.config.js,postcss.config.js,stylelint.config.js,.eslintrc.js,.prettierrc,package.json,tailwind.config.js,tsconfig.jest.json,jest.config.js}


# ==== docker composeコマンド群 ====

build:
	docker compose build --no-cache --force-rm

up:
	docker compose up -d

rebuild:
	@make build
	@make up

down:
	docker compose down --remove-orphans

reset:
	@make down
	@make up

init:
	docker compose up -d --build
	docker compose exec web composer install
	docker compose exec web cp .env.example .env
remake:
	@make destroy
	@make init

start:
	docker compose start
stop:
	docker compose stop

restart:
	@make stop
	@make start

destroy:
	@make chown
	@make purge
	@make delete

purge:
	docker compose down --rmi all --volumes --remove-orphans

destroy-volumes:
	docker compose down --volumes --remove-orphans

delete:
	rm -rf infra/{data,redis} backend frontend sqls && rm .env
	rm -rf infra/{redisinsight,phpmyadmin} .vscode

# ログ関連

logs:
	docker compose logs
logs-watch:
	docker compose logs --follow
log-web:
	docker compose logs web
log-web-watch:
	docker compose logs --follow web
log-app:
	docker compose logs app
log-app-watch:
	docker compose logs --follow app
log-db:
	docker compose logs db
log-db-watch:
	docker compose logs --follow db

# ==== コンテナ操作コマンド群 ====

# web
web:
	docker compose exec web bash
web-usr:
	docker compose exec -u $(USER) web bash
stop-web:
	docker compose stop web

# db
db:
	docker compose exec db bash
db-usr:
	docker compose exec -u $(USER) db bash

# client
client:
	docker compose exec client bash
client-usr:
	docker compose exec -u $(USER) client bash
stop-client:
	docker compose stop clinet

# sql
sql:
	docker compose exec db bash -c 'mysql -u $$MYSQL_USER -p$$MYSQL_PASSWORD $$MYSQL_DATABASE'

sql-root:
	docker compose exec db bash -c 'mysql -u root -p'

sqlc:
	@make query
	docker compose exec db bash -c 'mysql -u $$MYSQL_USER -p$$MYSQL_PASSWORD $$MYSQL_DATABASE < /var/lib/mysql/sql/query.sql'

query:
	@make chown-data
	cp ./sqls/sql/query.sql ./infra/data/sql/query.sql
# cp ./sqls/sql/query.sql ./_data/sql/query.sql
	@make chown-mysql

cp-sql:
	@make chown-data
	cp -r -n ./sqls/sql/** ./data/sql
# cp -r -n ./sqls/sql ./_data/sql
	@make chown-mysql

# redis
redis:
	docker compose exec redis redis-cli --raw

# ==== Composerコマンド群 ====

comp-install:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer install

comp-update:
	docker compose exec web composer update

# composerのバージョンアップ
# https://qiita.com/onkbear/items/f98d274d38eacfe7a209
comp-self-update:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer self-update --$(v)

# ==== パッケージ管理コマンド群 ====

# npm
npm:
	@make npm-install
npm-install:
	docker compose exec web npm install
npm-ci:
	docker compose exec web npm ci
npm-dev:
	docker compose exec web npm run dev
npm-watch:
	docker compose exec web npm run watch
npm-watch-poll:
	docker compose exec web npm run watch-poll
npm-hot:
	docker compose exec web npm run hot
npm-v:
	docker compose exec web npm -v
npm-init:
	docker compose exec web npm init -y
npm-i-D:
	docker compose exec web npm i -D $(pkg)
npm-run:
	docker compose exec web npm run $(cmd)
npm-un-D:
	docker compose exec web npm uninstall -D $(pkg)
# npx
npx-v:
	docker compose exec web npx -v
npx:
	docker compose exec web npx $(pkg)

# yarn
# npm-scriptコマンド
# コンテナ経由ではなく、backend/下で直接ビルドした方がいい
yarn:
	docker compose exec web yarn $(pkg)
yarn-install:
	docker compose exec web yarn install

# npm ciに相当するyarnのコマンド
# https://techblg.app/articles/npm-ci-in-yarn/
# yarnのバージョンが2未満の場合
yarn-ci:
	docker compose exec web yarn install --frozen-lockfile
yarn-ci-refresh:
	rm -rf $(env)/node_modules
	@make yarn-ci

# yarnのversionが2以上の場合
yarn-ci-v2:
	docker compose exec web yarn install --immutable --immutable-cache --check-cache

yarn-dev:
	docker compose exec web yarn dev
yarn-build:
	docker compose exec web yarn build
yarn-watch:
	docker compose exec web yarn watch
yarn-watch-poll:
	docker compose exec web yarn watch-poll
yarn-hot:
	docker compose exec web yarn hot
yarn-v:
	docker compose exec web yarn -v
yarn-init:
	docker compose exec web yarn init -y
yarn-add:
	docker compose exec web yarn add $(pkg)
yarn-add-%:
	docker compose exec web yarn add $(@:yarn-add-%=%)
yarn-add-dev:
	docker compose exec web yarn add -D $(pkg)
yarn-add-dev-%:
	docker compose exec web yarn add -D $(@:yarn-add-dev-%=%)
yarn-run:
	docker compose exec web yarn run $(cmd)
yarn-run-s:
	docker compose exec web yarn run $(pkg)
yarn-rm:
	docker compose exec web yarn remove $(pkg)

# node
node:
	docker compose exec web node $(file)

# ==== パーミッション関連 ====

chown:
	@make chown-data
	@make chown-backend

# chown-web
chown-backend:
	sudo chown -R $(USER):$(GNAME) backend

chown-work:
	docker compose exec web bash -c 'chown -R $$USER_NAME:$$GROUP_NAME /work'

# chown-db
chown-data:
	sudo chown -R $(USER):$(GNAME) infra/data

chown-mysql:
	docker compose exec db bash -c 'chown -R mysql:mysql /var/lib/mysql'

# ==== Git関連 ====

# git msg=save
git:
	git add .
	git commit -m $(msg)
	git push origin $(br)
g:
	@make git

git-msg:
	env | grep "msg"

git-%:
	git add .
	git commit -m $(@:git-%=%)
	git push origin

# ==== Volume関連 ====

# link
link:
	source
	ln -s `docker volume inspect $(rep)_db-store | grep "Mountpoint" | awk '{print $$2}' | awk '{print substr($$0, 2, length($$0)-3)}'` .
unlink:
	unlink _data
rep:
	env | grep "rep"

chown-volume:
	sudo chown -R $(USER):$(GNAME) ~/.local/share/docker/volumes

rm-data:
	@make chown-data
	rm -rf data

change-data:
	@make rm-data
	@make link

# docker
volume-ls:
	docker volume ls
volume-inspect:
	docker volume inspect $(rep)_db-store

# ==== 環境の切り替え関連 ====

# --- DB環境の切り替え ---

# webコンテナに.envファイルを持たせる:
# edit.envで環境変数を変更し、コンテナ内に.envを作成(環境変数は.envを優先するので、ビルド時にコンテナに持たせた環境変数を上書きする)
# phpdotenvを使用する際必要
cpenv:
	docker cp ./env/edit.env `docker compose ps -q web`:/work/.env

# DBの環境変更:
# DBの切り替え方法
# ①まずphpMyadminで切り替えるDB名でDBを作成しておき、かつ権限を持たせる
# ②作成したDB名でedit.envで環境変数をmake chenvで変更かつ再upしコンテナの環境変数を更新する
chenv:
	cp ./env/edit.env .env
	@make up

# ==== Dockerコマンド群 ====

# ==== Dockerコマンド群 ====

# Docker for Mac におけるディスク使用
# https://docs.docker.jp/docker-for-mac/space.html

# DockerでIPアドレスが足りなくなったとき
# docker network inspect $(docker network ls -q) | grep -E "Subnet|Name"
# docker network ls
# docker network rm ネットワーク名
# docker network prune
# https://docs.docker.jp/config/daemon/daemon.html
# daemon.json
# {
#   "experimental": false,
#   "default-address-pools": [
#       {"base":"172.16.0.0/12", "size":24}
#   ],
#   "builder": {
#     "gc": {
#       "enabled": true,
#       "defaultKeepStorage": "20GB"
#     }
#   },
#   "features": {
#     "buildkit": true
#   }
# }

# docker networkの削除ができないときの対処方法
# https://qiita.com/shundayo/items/8b24af5239d9162b253c

# error while removing network でDocker コンテナを終了できない時の対処方法
# https://sun0range.com/information-technology/docker-error-while-removing-network/#%E3%83%8D%E3%83%83%E3%83%88%E3%83%AF%E3%83%BC%E3%82%AF%E5%89%8A%E9%99%A4%E3%82%92%E8%A9%A6%E3%81%BF%E3%82%8B
# → Docker for Macを再起動後、docker network rm ネットワーク名 で削除

# ネットワーク検証
# docker network inspect ネットワーク名
# # network削除
# docker network rm ネットワーク名
# # 確認
# docker network ls

# コンテナが削除できない
# https://engineer-ninaritai.com/docker-rm/

# 方法① コンテナを停止させる
# docker stop [コンテナID]
# docker rm [コンテナID]

# 方法② オプションを付けて強制削除
# docker rm -f [コンテナ]

# ==== Linuxコマンド群 ====

# githubにアップされている画像の取り込み方法
# 1. 画像ファイルを開く
# 2. ダウンロードボタンをクリック
# 3. ダウンロード画面のURLをコピー
# 4. 適当なフォルダでwgetコマンドで取り込みむ
# 例) https://raw.githubusercontent.com/deatiger/ec-app-demo/develop/src/assets/img/src/no_image.png
# wget <URL>

# ==== Composerパッケージ関連 ====

# ---- PHPUnit ----

comp-add-D-phpunit:
	docker compose exec web composer require phpunit/phpunit --dev

# ---- DBUnit ----

# {
#     "require-dev": {
#         "phpunit/phpunit": "^5.7|^6.0",
#         "phpunit/dbunit": ">=1.2"
#     }
# }
#
# composer update

# ---- phpdotenv ----

comp-add-phpdotenv:
	docker compose exec web composer require vlucas/phpdotenv

# ---- Monolog ----

# https://reffect.co.jp/php/monolog-to-understand

comp-add-monolog:
	docker compose exec web composer require monolog/monolog

# ---- MongoDB ----

comp-add-mongodb:
	docker compose exec web composer require "mongodb/mongodb"

# ---- Laravel Collection ----

# https://github.com/illuminate/support

comp-add-laravel-collection:
	docker compose exec web composer require illuminate/support

# ---- Carbon ----

# PHPの日付ライブラリ

# https://carbon.nesbot.com/
# https://github.com/briannesbitt/carbon

# https://coinbaby8.com/carbon-laravel.html
# https://blog.capilano-fw.com/?p=867
# https://technoledge.net/composer-carbon/
# https://qiita.com/mackeyTA/items/e8b5e47a9f020a1902c0
# https://www.wakuwakubank.com/posts/421-php-carbon/
# https://codelikes.com/laravel-carbon/
# https://logical-studio.com/develop/development/laravel/20210709-laravel-carbon/

comp-add-carbon:
	docker compose exec web composer require nesbot/carbon

# ※ laravelにはデフォルトでcarbonが入っているので、下記のようにuseで定義するだけで使うことができる。
# use Carbon\Carbon;

# ---- PHP_CodeSniffer ----

# https://github.com/squizlabs/PHP_CodeSniffer
# https://www.ninton.co.jp/archives/6360#toc2
# https://tadtadya.com/php_codesniffer-should-be-installed/
# https://pointsandlines.jp/server-side/php/php-codesniffer
# https://qiita.com/atsu_kg/items/571def8d0d2d3d594e58

comp-add-D-php_codesniffer:
	docker compose exec web composer require "squizlabs/php_codesniffer=*" --dev

# ---- PHPCompatibility ----

# https://github.com/PHPCompatibility/PHPCompatibility
# https://qiita.com/e__ri/items/ed97da62eb5d5c4b2932

comp-add-D-php-compatibility:
	docker compose exec web composer require "phpcompatibility/php-compatibility=*" --dev

# ---- PHPStan ----

# https://phpstan.org/user-guide/getting-started
# https://blog.shin1x1.com/entry/getting-stated-with-phpstan

comp-add-D-phpsatn:
	docker compose exec web composer require phpstan/phpstan --dev

# ==== Laravelで使える便利なComposerパッケージ関連 ====

# PHPフレームワークLaravelの使い方
# https://qiita.com/toontoon/items/c4d0371e504c37f6576e

# https://github.com/chiraggude/awesome-laravel#popular-packages
# laravel-awesome-projectのページの「popular-packages」の欄に、便利なパッケージがカテゴリ別で大量に紹介されている。

# https://qiita.com/minato-naka/items/4b47a22ba07b2604ce02
# https://yutaro-blog.net/2022/03/30/laravel-composer-package/#index_id1
# https://qiita.com/ChiseiYamaguchi/items/7277aad6be309d0f7ae7

install-recommend-packages:
	docker compose exec web composer require doctrine/dbal
	docker compose exec web composer require --dev barryvdh/laravel-ide-helper
	docker compose exec web composer require --dev beyondcode/laravel-dump-server
	docker compose exec web composer require --dev barryvdh/laravel-debugbar
	docker compose exec web composer require --dev roave/security-advisories:dev-master
	docker compose exec web php artisan vendor:publish --provider="BeyondCode\DumpServer\DumpServerServiceProvider"
	docker compose exec web php artisan vendor:publish --provider="Barryvdh\Debugbar\ServiceProvider"

# ---- Doctrine DBAL ----

# https://github.com/doctrine/dbal

# マイグレーション後のデーブルの編集に必要
# migrationでカラム定義変更をする場合にインストールしておく必要あり。
# Model のプロパティを補完する際に必要
# リリース情報: https://github.com/doctrine/dbal/releases
# Laravel 6 -> 2

install-dbal:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require --dev "doctrine/dbal:$(v).*"

# ---- Laravel Debugbar ----

# https://github.com/barryvdh/laravel-debugbar

# リリース情報: https://github.com/barryvdh/laravel-debugbar/releases?page=1
# デバッグ

# ブラウザ下部にデバッグバーを表示する。
# その時にリクエストで発行されたSQL一覧や、今持っているセッション情報一覧など
# デバッグに便利な情報がブラウザ上で確認できるようになる。

install-debuger:
	docker compose exec workspace php -d memory_limit=-1 /usr/bin/composer require --dev barryvdh/laravel-debugbar:$(v)

# --- コード補完 ----

# Laravel IDE Helper
# # https://github.com/barryvdh/laravel-ide-helper
# 対応バージョン: https://github.com/barryvdh/laravel-ide-helper/releases?page=1
# v2.9.0よりDropped support for Laravel 6 and Laravel 7, as well as support for PHP 7.2
# Laravel 6 7 → 2.8.2  Laravel 5 → 2.6.3

# IDEを利用してコーディングする際に、
# コード補完を強化する。
# 変数からアローを書いたときにメソッドやプロパティのサジェスチョンがたくさん表示されたり、
# メソッド定義元へのジャンプできる範囲が増えたり。

install-ide-helper:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require --dev barryvdh/laravel-ide-helper:"$(v)"

ide-helper:
	docker compose exec web php artisan clear-compiled
	@make ide-helper-generate
	@make ide-helper-models
# @make ide-helper-meta

# _ide_helper.php生成
ide-helper-generate:
	docker compose exec web php artisan ide-helper:generate

# _ide_helper_models.php生成
ide-helper-models:
	docker compose exec web php artisan ide-helper:models --nowrite

ide-helper-model:
	docker compose exec web php artisan ide-helper:models "App\Models\$(model)" --nowrite

# .phpstorm.meta.php生成(PHPStorm限定)
ide-helper-meta:
	docker compose exec web php artisan ide-helper:meta

# --- Laravel/uiライブラリ関連 ---

# Laravel8 → 3 Laravel7 → 2 Laravel6 → 1
install-laravel-ui:
	docker compose exec web composer require --dev laravel/ui "$(v).x"

# スキャフォールド
install-bootstrap:
	docker compose exec web php artisan ui bootstrap
install-bootstrap-auth:
	docker compose exec web php artisan ui bootstrap --auth

install-react:
	docker compose exec web php artisan ui react
install-react-auth:
	docker compose exec web php artisan ui react --auth

install-vue:
	docker compose exec web php artisan ui vue
install-vue-auth:
	docker compose exec web php artisan ui vue --auth

# public/js public/css生成
# ※ エラーが出たら、make npm-dev | make yarn-dev
# npm
npm-scaffold:
	@make npm-install
	@make npm-dev

# yarn
yarn-scaffold:
	@make yarn-install
	@make yarn-dev

# <<公式パッケージ>>

# Laravel 7.x TOC
# https://readouble.com/laravel/7.x/ja/
# laravel 8.x TOC
# https://readouble.com/laravel/8.x/ja/

# Laravel Breeze
# Cashier (Stripe) - 課金システムを作れる
# Cashier (Paddle)
# Dusk
# Envoy
# Fortify
# Homestead
# Horizon
# Jetstream
# Octane
# Passport
# Sail
# Sanctum
# Scout - 全文検索処理
# Socialite - SNSなど外部システム認証を導入
# Telescope
# Valet

# ---- Laravel Breeze ----

# https://readouble.com/laravel/8.x/ja/starter-kits.html#laravel-breeze

# Laravel Breeze ※Laravel 8以降
install-breeze:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require --dev laravel/breeze

# ※npm-scaffold または yarn-scaffold が必要
breeze-install:
	docker compose exec web php artisan breeze:install
	@make yarn-scaffold

# ---- Laravel Cashier ----

# https://github.com/laravel/cashier-stripe
# https://laravel.com/docs/9.x/billing
# Laravel 8.x Laravel Cashier (Stripe)
# https://readouble.com/laravel/8.x/ja/billing.html
# Laravel 8.x Laravel Cashier (Paddle)
# https://readouble.com/laravel/8.x/ja/cashier-paddle.html

# https://reffect.co.jp/laravel/cashier
# https://blog.capilano-fw.com/?p=3893
# https://re-engines.com/2020/07/08/laravel-cashier/

# Laravel上で定期支払いを実装させたいときに便利。

# ※ 公式からの注意点:
# サブスクリプションを提供せず、「一回だけ」の支払いを取り扱う場合は、
# Cashierを使用してはいけません。StripeかBraintreeのSDKを直接使用してください。

cashier-install:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require laravel/cashier

# ---- Laravel Dusk ----

# ブラウザーテスト

# https://github.com/laravel/dusk
# https://www.oulub.com/docs/laravel/ja-jp/dusk
# https://laravel.com/docs/9.x/dusk
# Laravel 8.x Laravel Dusk
# https://readouble.com/laravel/8.x/ja/dusk.html

# https://re-engines.com/2020/09/28/laravel-dusk/
# https://qiita.com/ryo3110/items/9a67267871d291d0e2a7
# https://qiita.com/t_kanno/items/55252cfa06ca51c1036e

dusk-install:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require --dev laravel/dusk


# ---- Laravel Passport ----

# API認証をするときに便利

# https://laravel.com/docs/9.x/passport
# https://www.oulub.com/docs/laravel/ja-jp/passport
# Laravel 8.x Laravel Passport
# https://readouble.com/laravel/8.x/ja/passport.html

# https://qiita.com/zaburo/items/65de44194a2e67b59061
# https://reffect.co.jp/laravel/laravel-passport-understand

passport-install:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require laravel/passport


# ---- Laravel Sanctum ----

# Laravel 8.x Laravel Sanctum
# https://readouble.com/laravel/8.x/ja/sanctum.html
# https://laravel.com/docs/8.x/sanctum
# https://qiita.com/ucan-lab/items/3e7045e49658763a9566
# https://yutaro-blog.net/2021/08/18/laravel-sanctum/
# https://reffect.co.jp/laravel/laravel-sanctum-token
# https://codelikes.com/use-laravel-sanctum/

# リリース情報
# ※Laravel8.6以降からLaravel Sanctumが標準でインストールされるので不要
# https://github.com/laravel/sanctum/releases

# ①インストールとファイルの生成
sanctum-install:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require laravel/sanctum
	docker compose exec web php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"

# ②APIトークンを使用する場合は、この後マイグレートする。
# make mig
# ※ APIトークンを使用しない場合、2019_12_14_000001_create_personal_access_tokens_table.phpを削除

# ③カーネルミドルウェアの設定 - １行目をコメントアウト
# app/Http/Kernel.php
# 'api' => [
#     \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
#     'throttle:api',
#     \Illuminate\Routing\Middleware\SubstituteBindings::class,
# ],

# ④config/sanctum.php の編集
# localhostのポートを8080に変更

# **** ユーザー認証設定 ****

# Authentication
# https://laravel.com/docs/8.x/authentication

# Manually Authenticating Users
# https://laravel.com/docs/8.x/authentication#authenticating-users

# Logging Out
# https://laravel.com/docs/8.x/authentication#logging-out

# ログイン用APIの作成
# ⑴ LoginController.phpの作成。
# ⑵ Manually Authenticating Users からLoginController.phpにペースト。
# ⑶ APIの場合、returnの部分がレスポンスになるよう、リダイレクトから修正。
# ログイン成功時は、ログインユーザー情報を返す。
# return response()->json(Auth::user());
# 失敗時は、401ステータスを返す。
# return response()->json([], 401);
# ⑷ PHPDocの修正
# ⑸ メソッド名をauthenticateからloginに変更

# ログアウト用APIの作成
# ⑴ Logging Out からLoginController.phpにペースト
# ⑵ APIの場合、returnの部分がレスポンスになるよう、リダイレクトから修正。
# ログアウトに成功したら、trueを返す。
# return response()->json(true);
# ⑶ PHPDocを修正

# ---- Laravel Scout + Algolia | Elasticsearch ----

# Laravel 8.x Laravel Scout
# https://readouble.com/laravel/8.x/ja/scout.html
# https://www.oulub.com/docs/laravel/ja-jp/scout#installation
# https://github.com/laravel/scout

# Eloquentモデルに対し、全文検索を提供するパッケージ。
# Algoliaのドライバも用意されているため、とても便利。

scout-install:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require laravel/scout

# https://www.algolia.com/
# https://qiita.com/avosalmon/items/b7b90c734709093fb927
# https://blog.capilano-fw.com/?p=3843
# https://reffect.co.jp/laravel/laravel-scout
algolia-install:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require algolia/algoliasearch-client-php

# https://public-constructor.com/laravel-scout-with-elasticsearch/#toc2
# https://qiita.com/sola-msr/items/64d57d3970b715c795f5
# https://liginc.co.jp/472808
elasticsearch-install:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require elasticsearch/elasticsearch

# ---- Laravel Socialite ----

# Laravel 8.x Laravel Socialite
# https://readouble.com/laravel/8.x/ja/socialite.html

# メモリ不足の場合: Fatal error: Allowed memory size of 1610612736 bytes exhaustedの対処方法
# https://feeld-uni.com/entry/2021/01/19/194546
# https://codesapuri.com/articles/1

# リリース情報: https://github.com/laravel/socialite/releases
# Laravel8 -> 5.0.0以上 Laravel6 → 4.2.0以上

socialite-install:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require laravel/socialite "$(v)"

# ---- Laravel Telescope ----

# Laravelで使う公式デバックアシスタント

# https://laravel.com/docs/9.x/telescope
# Laravel 8.x Laravel Telescope
# https://readouble.com/laravel/8.x/ja/telescope.html

# https://blog.capilano-fw.com/?p=2435
# https://www.searchlight8.com/laravel-telescope-use/
# https://kekaku.addisteria.com/wp/20191001092424
# https://biz.addisteria.com/laravel_telescope/

telescope-install:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require laravel/telescope --dev

# ---- Laravel Queue ----

# 非同期処理で何かしたいときに便利

# https://laravel.com/docs/9.x/queues
# Laravel 8.x キュー
# https://readouble.com/laravel/8.x/ja/queues.html

# https://qiita.com/naoki0531/items/f9b8545b77c643a3fa44
# https://qiita.com/toontoon/items/0c9291c9b6be2eb1816d
# https://masa-engineer-blog.com/laravel-job-queue-asynchronous-process/

# https://reffect.co.jp/laravel/laravel-queue-setting-manuplate
# https://reffect.co.jp/laravel/laravel-job-queue-easy-setup


# <<サードパーティ製パッケージ>>

# ---- nunomaduro/larastan ----

# https://github.com/nunomaduro/larastan
# https://phpstan.org/user-guide/rule-levels
# https://qiita.com/MasaKu/items/7ed6636a57fae12231e0
# https://zenn.dev/naoki0722/articles/090bd3309474d9
# https://tech-tech.blog/php/laravel/larastan/

# php8.0以上, laravel9.0以上 → nunomaduro/larastan:^2.0
# それ以下 → nunomaduro/larastan:^1.0

comp-add-D-larastan:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require nunomaduro/larastan:^$(v).0 --dev

# ---- itsgoingd/clockwork ----

# https://underground.works/clockwork/#documentation
# https://github.com/itsgoingd/clockwork
# https://qiita.com/tommy0218/items/3fbd8b45808cee748010
# https://qiita.com/gungungggun/items/6ecd0e62ff2ae4cb0aee
# https://www.webopixel.net/php/1526.html

comp-add-D-clockwork:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require itsgoingd/clockwork

# ---- laravelcollective/html ----

# https://github.com/LaravelCollective/html
# https://laravelcollective.com/docs
# http://program-memo.com/archives/653
# https://monmon.jp/1049/i-want-to-use-the-larvase-collective-html-in-larva8-for-installation/
# https://laraweb.net/practice/7965/
# https://blog.motikan2010.com/entry/2017/01/28/%E3%80%8ELaravel_Collective%E3%80%8F%E3%81%A7%E3%81%AEHTML%E7%94%9F%E6%88%90%E3%82%92%E7%B0%A1%E5%8D%98%E3%81%AB%E3%81%BE%E3%81%A8%E3%82%81%E3%81%A6%E3%81%BF%E3%82%8B

# bladeファイルでフォームを書くときに便利なメソッドを提供する。
# CSRFトークンを自動で埋め込んでくれたり、
# モデルとフォームを紐づけて自動で初期値を入れてくれたり。
# ※Laravel5.8なら、laravelcollective/htmlの5.8を選ぶ。

comp-add-laravelcollective-html:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require "laravelcollective/html":"$(v)"

# ---- wildside/userstamps ----

# https://github.com/WildSideUK/Laravel-Userstamps

# データを作成、更新した際に
# created_by、updated_byのカラムを
# ログイン中ユーザIDで自動更新してくれる。

comp-add-userstamps:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require wildside/userstamps

# ---- guzzlehttp/guzzle ----

# https://github.com/guzzle/guzzle
# https://reffect.co.jp/php/php-http-client-guzzle
# https://qiita.com/yousan/items/2a4d9eac82c77be8ba8b
# https://qiita.com/clustfe/items/f9ff2b12da7a501197f8
# https://webplus8.com/laravel-guzzle-http-client/

# Laravel 9.x HTTPクライアント
# https://readouble.com/laravel/9.x/ja/http-client.html

# 簡単にHTTPリクエストを送信するコードが書ける。
# 外部サービスのAPIにリクエストするときや
# フロントエンドからajaxでAPIリクエストするときに利用。

comp-add-guzzle:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require guzzlehttp/guzzle

# ---- laracasts/flash ----

# https://github.com/laracasts/flash
# https://laravel10.wordpress.com/2015/03/18/laracastsflash/

# フラッシュメッセージを簡単に表示できる。
# データ登録完了時や削除完了時に
# 画面上部に「登録完了しました。」みたいなメッセージ表示をする。

comp-add-flash:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require laracasts/flash

# ---- kyslik/column-sortable ----

# https://github.com/Kyslik/column-sortable
# https://qiita.com/anomeme/items/5475c5e8ba9136e73b4e
# https://qiita.com/haserror/items/e7daeae404b675f739e1
# https://note.com/telluru052/n/nf4139126d556
# https://webru.info/laravel/column-sortable/

# 一覧系画面で簡単にソート機能を実装できる。
# 一覧テーブルのヘッダー行をクリックするだけで
# 昇順、降順ソートを切り替えられる。

comp-add-column-sortable:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require kyslik/column-sortable

# ---- league/flysystem-aws-s3-v3 ----

# https://github.com/thephpleague/flysystem-aws-s3-v3
# https://qiita.com/ucan-lab/items/61903ce10a186e78f15f
# https://tech-tech.blog/php/laravel/s3/

# Laravel 8.x ファイルストレージ
# https://readouble.com/laravel/8.x/ja/filesystem.html#composer-packages

# S3にファイルアップロード、ダウンロードをする場合に利用。

# thephpleague/flysystem-aws-s3-v3のv2系を利用する場合、thephpleague/flysystemの2系をインストールする必要がある。
#リリース情報: https://github.com/thephpleague/flysystem/releases

# Laravelフレームワークがleague/flysystemの1系を参照している → thephpleague/flysystem-aws-s3-v3の1系をインストール
# ※ Laravel9.xからleague/flysystemのv2がサポートなので、9系以降はv1。

comp-add-flysystem-aws-s3-v3:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require -W league/flysystem-aws-s3-v3:^$(v).0

# ---- aws/aws-sdk-php-laravel ----

# https://github.com/aws/aws-sdk-php-laravel
# https://github.com/aws/aws-sdk-php-laravel/blob/master/README.md
# https://px-wing.hatenablog.com/entry/2020/11/02/084742
# https://qiita.com/nemui_yo/items/14ffacbad02ff786a993

# その他AWSサービス利用時に必要。
# SESでメール送信など。

# composer.json
# {
#     "require": {
#         "aws/aws-sdk-php-laravel": "~3.0"
#     }
# }

# composer update

# ---- orangehill/iseed ----

# https://github.com/orangehill/iseed
# https://qiita.com/imunew/items/3973658bdcae9ab77b8a
# https://www.out48.com/archives/5103/
# https://daybydaypg.com/2020/10/18/post-1625/

# 実際にDBに入っているデータからseederファイルを逆生成する。

comp-add-D-iseed:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require --dev "orangehill/iseed"

# ---- Enum ----

# LaravelでEnumを実装したいときに利用。
# 似たようなパッケージがいくつかあり、どれがベストかはまだわからない。

# ※ PHP8.1からEnumが標準に
# https://www.php.net/manual/ja/language.types.enumerations.php
# https://www.php.net/manual/ja/language.enumerations.methods.php
# https://blog.capilano-fw.com/?p=9829
# https://qiita.com/ucan-lab/items/e9f53aa024ca3cc5ea1b
# https://qiita.com/rana_kualu/items/bdfa6c844125c1d0f4d4

# marc-mabe/php-enum
# https://github.com/marc-mabe/php-enum

# myclabs/php-enum
# https://github.com/myclabs/php-enum

comp-add-php-enum-myclabs:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require myclabs/php-enum

# bensampo/laravel-enum
# https://github.com/BenSampo/laravel-enum

comp-add-laravel-enum:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require bensampo/laravel-enum

# ---- spatie/laravel-menu ----

# https://github.com/spatie/laravel-menu

# 階層になっているメニューを生成できる。

comp-add-laravel-menu:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require spatie/laravel-menu

# ---- spatie/laravel-permission ----

# https://github.com/spatie/laravel-permission
# https://reffect.co.jp/laravel/spatie-laravel-permission-package-to-use
# https://qiita.com/sh-ogawa/items/09b7097b5721dcdbe566

# https://e-seventh.com/laravel-permission-summary/
# https://e-seventh.com/laravel-permission-basic-usage/

# ユーザ、ロール、権限
# の制御を簡単にできる。
# ユーザ、ロール、権限を
# 多対多対多で管理するようなアプリでは非常に便利。

# ユーザへのロール・権限の付与、はく奪の処理や
# ユーザのロール・権限によるアクセス制御などが簡単。

comp-add-laravel-permission:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require spatie/laravel-permission

# ---- encore/laravel-admin ----

# お手軽に管理画面を作れる

# https://enjoyworks.jp/tech-blog/7298
# https://qiita.com/Dev-kenta/items/25ac692befe6f26f11cf
# https://zenn.dev/eri_agri/articles/e7c6f1690ab9d9

comp-add-laravel-admin:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require encore/laravel-admin

# ---- davejamesmiller/laravel-breadcrumbs ----

# https://github.com/d13r/laravel-breadcrumbs
# https://poppotennis.com/posts/laravel-breadcrumbs
# https://prograshi.com/framework/laravel/laravel-breadcrumbs-structured-markup/
# https://kojirooooocks.hatenablog.com/entry/2018/01/11/005638
# https://pgmemo.tokyo/data/archives/1302.html

# パンくずリストの表示や管理がしやすくなる。

comp-add-laravel-laravel-breadcrumbs:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require diglactic/laravel-breadcrumbs

# ---- league/csv ----

# https://csv.thephpleague.com/9.0/
# https://github.com/thephpleague/csv
# https://tech.griphone.co.jp/2018/12/12/advent-calendar-20181212/
# https://blitzgate.co.jp/blog/1884/
# https://blog.ttskch.com/php-league-csv/

# CSVのインポート・エクスポート処理を簡単にしてくれる。

comp-add-csv:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require league/csv:^9.0

# ---- barryvdh/laravel-dompdf ----

# https://github.com/barryvdh/laravel-dompdf
# https://codelikes.com/laravel-dompdf/
# https://blog.capilano-fw.com/?p=182
# https://syuntech.net/php/laravel/laravel-dompdf/
# https://zakkuri.life/laravel-pdf-ja/
# https://biz.addisteria.com/laravel_dompdf/

# https://reffect.co.jp/laravel/how_to_create_pdf_in_laravel
# https://reffect.co.jp/laravel/laravel-dompdf70-japanese

# PDF出力処理を簡単にできる。

# 日本語化
# https://github.com/dompdf/utils

comp-add-laravel-dompdf:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require barryvdh/laravel-dompdf

# ---- barryvdh/laravel-snappy ----

# https://github.com/barryvdh/laravel-snappy
# https://reffect.co.jp/laravel/how_to_create_pdf_in_laravel_snappy
# https://qiita.com/naga3/items/3b65a39e235b8bd26f4a

# https://biz.addisteria.com/laravel_snappy_pdf/

# PDF出力処理を簡単にできる。

# Wkhtmltopdfのインストール
# https://github.com/KnpLabs/snappy#wkhtmltopdf-binary-as-composer-dependencies
# ※ Laravel-Snappyのパッケージをインストールする前にWhtmltopdfをインストールする必要がある。
# https://github.com/barryvdh/laravel-snappy/blob/master/readme.md
# $ composer require h4cc/wkhtmltopdf-amd64 0.12.x
# $ composer require h4cc/wkhtmltoimage-amd64 0.12.x

# 【補足】MACにWKhtmltopdfをインストールする場合
# MAC環境で、Laravel-SnappyのInstallationに沿って設定を行っていくとPDFの作成を行った際にエラーが発生します。
# 実行権限の問題かと判断し、権限を変更しても同じエラーが発生します。
# https://reffect.co.jp/laravel/how_to_create_pdf_in_laravel_snappy#MACWKhtmltopdf

comp-add-laravel-snappy:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require barryvdh/laravel-snappy

# ---- jenssegers/agent ----

# https://github.com/jenssegers/agent
# https://qiita.com/kazuhei/items/08e3d88c2b8bf8a6b0ab
# https://qiita.com/Syoitu/items/08cefa675c0e289df6e5
# https://leben.mobi/blog/laravel_useragent_check/php/

# ユーザエージェントの取得、判定処理をできる

comp-add-agent:
	docker compose exec web php -d memory_limit=-1 /usr/bin/composer require jenssegers/agent

# ==== Laravel Mix ====

# laravel-mix
# https://laravel-mix.com/docs/4.0/installation
# https://qiita.com/tokimeki40/items/2c9112272a8b92bbaef9
#
# v6:
# Development
# npx mix
# Production
# npm mix --production
# watch
# npx mix watch
# Hot Module Replacemen
# npx mix watch --hot
#
# v5:
# –progress:ビルドの進捗状況を表示させるオプション
# –hide-modules:モジュールについての情報を非表示にするオプション
# –config:Laravel Mixで利用するwebpack.config.jsの読み込み
# cross-env:環境依存を解消するためにインストールしたパッケージ
#
# package.json
# "scripts": {
#     "dev": "npm run development",
#     "development": "cross-env NODE_ENV=development node_modules/webpack/bin/webpack.js --progress --config=node_modules/laravel-mix/setup/webpack.config.js",
#     "watch": "npm run development -- --watch",
#     "hot": "cross-env NODE_ENV=development node_modules/webpack-dev-server/bin/webpack-dev-server.js --inline --hot --config=node_modules/laravel-mix/setup/webpack.config.js",
#     "prod": "npm run production",
#     "production": "cross-env NODE_ENV=production node_modules/webpack/bin/webpack.js --config=node_modules/laravel-mix/setup/webpack.config.js"
# }
yarn-add-D-mix:
	docker compose exec web yarn add -D laravel-mix glob cross-env rimraf

# webpack.mix.js
touch-mix:
	docker compose exec web touch webpack.mix.js

# laravel-mix-polyfill
# https://laravel-mix.com/extensions/polyfill
# IE11対応
yarn-add-D-mix-polyfill:
	docker compose exec web add yarn -D laravel-mix-polyfill

# laravel-mix-pug
# https://laravel-mix.com/extensions/pug-recursive
yarn-add-D-mix-pug:
	docker compose exec web yarn add -D laravel-mix-pug-recursive

# laravel-mix-ejs
# https://laravel-mix.com/extensions/ejs
yarn-add-D-mix-ejs:
	docker compose exec web yarn add -D laravel-mix-ejs

# ==== gulp関連 ====

yarn-add-D-gulp:
	docker compose exec web yarn add -D gulp browser-sync

mkgulp:
	cp env/gulpfile.js backend/

# ===== webpack関連 =====

# webpack5 + TS + React
yarn-add-D-webpack5-env:
	docker compose exec web yarn add -D \
	webpack webpack-cli \
	sass sass-loader css-loader style-loader \
	postcss postcss-loader autoprefixer \
	babel-loader @babel/core @babel/runtime @babel/plugin-transform-runtime @babel/preset-env core-js@3 regenerator-runtime babel-preset-minify\
	mini-css-extract-plugin html-webpack-plugin html-loader css-minimizer-webpack-plugin terser-webpack-plugin copy-webpack-plugin \
	webpack-dev-server \
	browser-sync-webpack-plugin browser-sync \
	dotenv-webpack \
	react react-dom @babel/preset-react @types/react @types/react-dom \
	react-router-dom@5.3.0 @types/react-router-dom history@4.10.1 \
	react-helmet-async \
	typescript@3 ts-loader fork-ts-checker-webpack-plugin \
	eslint@7.32.0 eslint-config-prettier@7.2.0 prettier@2.5.1 @typescript-eslint/parser@4.33.0 @typescript-eslint/eslint-plugin@4.33.0 husky@4.3.8 lint-staged@10.5.3 \
	eslint-plugin-react eslint-plugin-react-hooks eslint-config-airbnb eslint-plugin-import eslint-plugin-jsx-a11y \
	stylelint stylelint-config-standard stylelint-scss stylelint-config-standard-scss stylelint-config-prettier stylelint-config-recess-order postcss-scss \
	glob lodash rimraf npm-run-all axios \
	redux react-redux @types/redux @types/react-redux @reduxjs/toolkit @types/node \
	redux-actions redux-logger @types/redux-logger redux-thunk connected-react-router reselect typescript-fsa typescript-fsa-reducers immer normalizr \
	jest jsdom eslint-plugin-jest @types/jest @types/jsdom ts-jest \
	@testing-library/react @testing-library/jest-dom \
	@emotion/react @emotion/styled @emotion/babel-plugin \
	styled-components \
	tailwindcss@2.2.19 @types/tailwindcss eslint-plugin-tailwindcss \
	@material-ui/core @material-ui/icons @material-ui/styles @material-ui/system @types/material-ui \
	@chakra-ui/react @emotion/react@^11 @emotion/styled@^11 framer-motion@^6 @chakra-ui/icons focus-visible \
	yup react-hook-form @hookform/resolvers @hookform/error-message @hookform/error-message

# webpackの導入
yarn-add-D-webpack:
	docker compose exec web yarn add -D webpack webpack-cli
yarn-add-D-webpack-v4:
	docker compose exec web yarn add -D webpack@4.46.0 webpack-cli

# webpackの実行
yarn-webpack:
	docker compose exec web yarn webpack
webpack:
	@make yarn-webpack
wp:
	@make yarn-webpack
yarn-webpack-config:
	docker compose exec web yarn webpack --config $(path)
# modeを省略すると商用環境モードになる
yarn-run-webpack:
	docker compose exec web yarn webpack --mode $(mode)
yarn-run-webpack-dev:
	docker compose exec web yarn webpack --mode development
	docker compose exec web yarn webpack --mode development
# eval無効化
yarn-run-webpack-dev-none:
	docker compose exec web yarn webpack --mode development --devtool none

# webpack.config.js生成
touch-webpack:
	docker compose exec web touch webpack.config.js

# sass-loader
# sass ↔︎ css
yarn-add-D-loader-sass:
	docker compose exec web yarn add -D sass sass-loader css-loader style-loader

# postcss-loader
# ベンダープレフィックスを自動付与
yarn-add-D-loader-postcss:
	docker compose exec web yarn add -D postcss postcss-loader autoprefixer

# postcss-preset-env
# https://zenn.dev/lollipop_onl/articles/ac21-future-css-with-postcss
# https://levelup.gitconnected.com/setup-tailwind-css-with-webpack-3458be3eb547
yarn-add-D-postcss-preset-env:
	docker compose exec web yarn add -D postcss-preset-env

# postcss.config.js生成
touch-postcss:
	docker compose exec web touch postcss.config.js

# .browserslistrc生成(ベンダープレフィックス付与確認用)
# Chrome 4-25
touch-browserslist:
	docker compose exec web touch .browserslistrc

# file-loader
# CSSファイル内で読み込んだ画像ファイルの出力先での配置
# webpack5から不要
yarn-add-D-loader-file:
	docker compose exec web yarn add -D file-loader

# mini-css-extract-plugin
# ※webpack 4.x | mini-css-extract-plugin 1.x
# 1.6.2
# style-loaderの変わりに使う。
# これでビルドすると、CSSが別ファイルとして生成される。
# version選択できます。
yarn-add-D-plugin-minicssextract:
	docker compose exec web yarn add -D mini-css-extract-plugin@$(@)

# babel-loader
# JSX、ECMAScriptのファイルをバンドルするためのloader
# webpack 4.x | babel-loader 8.x | babel 7.x
yarn-add-D-loader-babel:
	docker compose exec web yarn add -D babel-loader @babel/core @babel/preset-env
# https://zenn.dev/sa2knight/articles/5a033a0288703c
yarn-add-D-loader-babel-full:
	docker compose exec web yarn add -D @babel/core @babel/runtime @babel/plugin-transform-runtime @babel/preset-env babel-loader

# babelでトランスパイルを行う際に、古いブラウザが持っていない機能を補ってくれるモジュール群
# regenerator-runtimeはES7で導入されたasync/awaitを補完するために使われる。
# core-js@3は色々な機能を補完
yarn-add-D-complement-babel:
	docker compose exec web yarn add -D core-js@3 regenerator-runtime

# babel-preset-minify
# https://www.npmjs.com/package/babel-preset-minify
# https://chaika.hatenablog.com/entry/2021/01/06/083000
yarn-add-D-babel-preset-minify:
	docker compose exec web yarn add -D babel-preset-minify

yarn-add-D-babel-option:
	docker compose exec web yarn add -D @babel/plugin-external-helpers @babel/plugin-proposal-class-properties @babel/plugin-proposal-object-rest-spread

# .babelrc生成
# JSON形式で記載
touch-babelrc:
	docker compose exec web touch .babelrc

# babel.config.js
touch-babel:
	docker compose exec web touch babel.config.js

# eslint-loader
# ※eslint-loader@4: minimum supported eslint version is 6
# ESlintを使うためにeslint
# ESlintとwebpackを連携するためにeslint-loader
# ESlint上でbabelと連携するためにbabel-eslint
# 8系はエラーが出る
# eslint-loaderは非推奨になった
yarn-add-D-loader-eslint:
	docker compose exec web yarn add -D eslint@6 eslint-loader babel-eslint

# eslint-webpack-plugin

# .eslintrc生成
# JSON形式で記載
touch-eslintrc:
	docker compose exec web touch .eslintrc

# 対話形式で.eslintrc生成
yarn-eslint-init:
	docker compose exec web yarn run eslint --init

# html-webpack-plugin
# 指定したhtmlに自動的にscriptタグを注入する。
# ファイル名をhashにした時に、手動でhtmlに読み込ませる必要がなくなる。
#※Drop support for webpack 4 and node <= 10 - For older webpack or node versions please use html-webpack-plugin 4.x
# 4.5.2
yarn-add-D-plugin-htmlwebpack:
	docker compose exec web yarn add -D html-webpack-plugin@$(@)

# html-loader
# htmlファイル内で読み込んだ画像をJSファイルに自動的バンドルする
# HTMLファイル内で読み込んだ画像ファイルの出力先での配置
# 1.3.2
# ※html-webpack-pluginで対象となるhtmlファイルを読み込んでいないと、html-loaderだけ記入してもimgタグはバンドルされない。
# html-loaderとhtml-webpack-pluginは一緒に使う。
yarn-add-D-loader-html:
	docker compose exec web yarn add -D html-loader@$(@)

# 商用と開発でwebpack.config.jsを分割
touch-webpack-separation:
	docker compose exec web touch webpack.common.js webpack.dev.js webpack.prod.js

# webpack-merge
# webpackの設定ファイルをmergeする
yarn-add-D-webpackmerge:
	docker compose exec web yarn add -D webpack-merge

# 商用にminify設定
# JS版: terser-webpack-plugin
# ※webpack4 4.x 4.2.3
# CSS版: optimize-css-assets-webpack-plugin(webpack4の場合)
# HTML版: html-webpack-plugin https://github.com/jantimon/html-webpack-plugin
# ※webpack5以上は、css-minimizer-webpack-plugin
yarn-add-D-minify-v4:
	docker compose exec web yarn add -D optimize-css-assets-webpack-plugin terser-webpack-plugin@4.2.3 html-webpack-plugin@4.5.2
yarn-add-D-minify-v5:
	docker compose exec web yarn add -D css-minimizer-webpack-plugin terser-webpack-plugin html-webpack-plugin

# webpack-dev-server
# 開発用のサーバが自動に立ち上がるようにする
yarn-add-D-webpackdevserver:
	docker compose exec web yarn add -D webpack-dev-server

# ejs-html-loader
# ejs-compiled-loader
# ejs-plain-loader
yarn-add-D-loader-ejs-plain:
	docker compose exec web yarn add -D ejs ejs-plain-loader

# raw-loader
# txtファイルをバンドルするためのloader
# webpack5から不要
yarn-add-D-loader-raw:
	docker compose exec web yarn add -D raw-loader

# extract-text-webpack-plugin
# webpack4以降は mini-css-extract-pluginがあるので不要
yarn-add-D-plugin-extracttextwebpack:
	docker compose exec web yarn add -D extract-text-webpack-plugin

# resolve-url-loader
yarn-add-D-loader-resolveurl:
	docker compose exec web yarn add -D resolve-url-loader

# browser-sync
yarn-add-D-plugin-browsersync:
	docker compose exec web yarn add -D browser-sync-webpack-plugin browser-sync

# copy-webpack-plugin
# copy-webpack-pluginは、指定したファイルをそのままコピーして出力します。これも、出力元と先を合わせるのに役立ちます。
# https://webpack.js.org/plugins/copy-webpack-plugin/
yarn-add-D-plugin-copy:
	docker compose exec web yarn add -D copy-webpack-plugin

# imagemin-webpack-plugin
# ファイルを圧縮します。
# 各ファイル形式に対応したパッケージもインストールします。
# png imagemin-pngquant
# jpg imagemin-mozjpeg
# gif imagemin-gifsicle
# svg imagemin-svgo
yarn-add-D-plugin-imagemin:
	docker compose exec web yarn add -D imagemin-webpack-plugin imagemin-pngquant imagemin-mozjpeg imagemin-gifsicle imagemin-svgo


# webpack-watched-glob-entries-plugin
# globの代わり
# https://shuu1104.com/2021/11/4388/
yarn-add-D-plugin-watched-glob-entries:
	docker compose exec web yarn add -D webpack-watched-glob-entries-plugin

# clean-webpack-plugin
# https://shuu1104.com/2021/12/4406/
yarn-add-D-plugin-clean:
	docker compose exec web yarn add -D clean-webpack-plugin

# webpack-stats-plugin
# mix-manifest.jsonを、laravel-mixを使わずに自作する
# https://qiita.com/kokky/items/02063edf3252e147940a
yarn-add-D-plugin-webpack-stats:
	docker compose exec web yarn add -D webpack-stats-plugin


# source-map-loader
# webpack-hot-middleware

# dotenv-webpack
# ※webpack5からそのままではprocess.envで環境変数を読み込めない
# https://forsmile.jp/javascript/1054/

yarn-add-D-dotenv-webpack:
	docker compose exec web yarn add -D dotenv-webpack

# ---- PWA化 ----

# https://www.npmjs.com/package/workbox-sw
# https://www.npmjs.com/package/workbox-webpack-plugin
# https://www.npmjs.com/package/webpack-pwa-manifest
# https://github.com/webdeveric/webpack-assets-manifest

# https://www.hivelocity.co.jp/blog/46013/
# https://qiita.com/umashiba/items/1157e7e520f668417cf0

yarn-add-D-pwa:
	docker compose exec web yarn add -D workbox-sw workbox-webpack-plugin webpack-pwa-manifest webpack-assets-manifest

# ==== jQuery ====

yarn-add-jquey:
	docker compose exec web yarn add jQuery

# ==== Bootstrap ====

yarn-add-bootstrap-v5:
	docker compose exec web yarn add bootstrap @popperjs/core
yarn-add-bootstrap-v4:
	docker compose exec web yarn add bootstrap@4.6.1

# ==== Tailwind CSS 関連 ====

# Tailwind CHEAT SHEET
# https://nerdcave.com/tailwind-cheat-sheet

# Tailwind CSS IntelliSense
# 有効にすると補完が効く。

# https://zenn.dev/otanu/articles/f0a0b2bd0d9c44

# https://tailwindcss.jp/docs/installation
# https://gsc13.medium.com/how-to-configure-webpack-5-to-work-with-tailwindcss-and-postcss-905f335aac2
# https://qiita.com/hirogw/items/518a0143aee2160eb2d8
# https://qiita.com/maru401/items/eb4c7160b19127a76457

# インストールパッケージ
# https://github.com/tailwindlabs/tailwindcss-from-zero-to-production/tree/main/01-setting-up-tailwindcss

# entrypointに import "tailwind.css"
# webpackと一緒に使う場合は、src/css/tailwind.css -o public/css/dist.css は不要
# tailwind.css
# @tailwind base;
# @tailwind components;
# @tailwind utilities;

# package.json
# "scripts": {
#     "dev": "TAILWIND_MODE=watch postcss src/css/tailwind.css -o public/css/dist.css -w",
#     "prod": "NODE_ENV=production postcss src/css/tailwind.css -o public/css/dist.css"
#   }

yarn-add-D-tailwind-postcss-cli:
	docker compose exec web yarn add -D tailwindcss postcss postcss-cli autoprefixer cssnano
yarn-add-D-tailwind-v2-postcss-cli:
	docker compose exec web yarn add -D tailwindcss@2.2.19 postcss
	postcss-cli autoprefixer cssnano

# https://qiita.com/hironomiu/items/eac89ca4801534862fed#tailwind-install--initialize
# ホットリロードの併用すると、勝手にビルドされ続ける
yarn-add-D-tailwind-v3-webpack:
	docker compose exec web yarn add -D tailwindcss @types/tailwindcss eslint-plugin-tailwindcss
# 推奨
yarn-add-D-tailwind-v2-webpack:
	docker compose exec web yarn add -D tailwindcss@2.2.19 @types/tailwindcss eslint-plugin-tailwindcss



# postcss.config.js
# module.exports = (ctx) => {
#     return {
#         map: ctx.options.map,
#         plugins: {
#             tailwindcss: {},
#             autoprefixer: {},
#             cssnano: ctx.env === "production" ? {} : false,
#         },
#     }
# };
#
# module.exports = (ctx) => {
#     return {
#         map: ctx.options.map,
#         plugins: [
#             require('tailwindcss'),
#             require('autoprefixer'),
#             ctx.env === "production && require('cssnano')
#         ].filter(Boolean),
#     }
# };

# tailwind.config.js
# module.exports = {
#   mode: "jit",
#   purge: ["./public/index.html"],

# tailwind.config.jsとpostcss.config.js生成
yarn-tailwind-init-p:
	docker compose exec web yarn tailwindcss init -p

# tailwind.config.js生成
yarn-tailwind-init:
	docker compose exec web yarn tailwindcss init

# ==== React関連 ====

# https://zenn.dev/shohigashi/scraps/15f0eb42e97d5c

yarn-add-D-react-full:
	docker compose exec web yarn add -D react react-dom react-router-dom @babel/preset-react @types/react @types/react-dom @types/react-router-dom react-helmet-async history

yarn-add-D-react:
	docker compose exec web yarn add -D react react-dom @babel/preset-react @types/react @types/react-dom

# https://issueoverflow.com/2018/08/02/use-react-easily-with-react-scripts/
yarn-add-D-react-scripts:
	docker compose exec web yarn add -D react-scripts


# ---- react-router ----

# https://qiita.com/koja1234/items/486f7396ed9c2568b235
yarn-add-D-react-router:
	docker compose exec web yarn add -D react-router history

# 推奨
# https://zenn.dev/h_yoshikawa0724/articles/2020-09-22-react-router
# react-router も必要になりますが、react-router-dom の依存関係にあるので、一緒に追加されます。
# v6
# https://reactrouter.com/docs/en/v6
yarn-add-D-react-router-dom-v6:
	docker compose exec web yarn add -D react-router-dom @types/react-router-dom history

# v5
# https://v5.reactrouter.com/
# Reduxと一緒に使う場合は、react-routerは5系、historyは4系推奨
yarn-add-D-react-router-dom:
	docker compose exec web yarn add -D react-router-dom@5.3.0 @types/react-router-dom@ history@4.10.1

# ---- react-helmet ----

# https://github.com/nfl/react-helmet
# https://www.npmjs.com/package/@types/react-helmet
yarn-add-D-react-helmet:
	docker compose exec web yarn add -D react-helmet @types/react-helmet

# 推奨
# https://github.com/staylor/react-helmet-async
yarn-add-D-react-helmet-async:
	docker compose exec web yarn add -D react-helmet-async


# ---- react-spinners ----

yarn-add-D-react-spinners:
	docker compose exec web yarn add -D react-spinners

# ---- html-react-parser ----

yarn-add-D-html-react-parser:
	docker compose exec web yarn add -D html-react-parser

# ---- react-paginate ----

# https://www.npmjs.com/package/react-paginate
yarn-add-D-react-paginate:
	docker compose exec web yarn add -D react-paginate @types/react-paginate

# ---- react-countup ----

# https://www.npmjs.com/package/react-countup
yarn-add-D-react-countup:
	docker compose exec web yarn add -D react-countup

# ---- react-tag-input ----

# https://www.npmjs.com/package/react-tag-input
# https://github.com/pathofdev/react-tag-input
# https://www.npmjs.com/package/@types/react-tag-input

yarn-add-D-react-tag-input:
	docker compose exec web yarn add -D react-tag-input @types/react-tag-input

# ---- react toastify ----

# https://github.com/fkhadra/react-toastify
# https://fkhadra.github.io/react-toastify/introduction/

yarn-add-D-toastify:
	docker compose exec web yarn add -D react-toastify

# **** Icons ****

# ---- react-icons ----

yarn-add-D-react-icons:
	docker compose exec web yarn add -D react-icons

# ---- tabler-icons-react ----

# https://tabler-icons-react.vercel.app/
# https://github.com/konradkalemba/tabler-icons-react
# https://www.npmjs.com/package/tabler-icons-react

yarn-add-D-tabler-icons:
	docker compose exec web yarn add -D tabler-icons-react

# ---- heroicons ----

# https://heroicons.com/
# https://www.npmjs.com/package/@heroicons/react
# https://github.com/tailwindlabs/heroicons

yarn-add-D-heroicons:
	docker compose exec web yarn add -D @heroicons/react

# ==== Create React App ====

# ---- create-react-app ----

yarn-create-react-app:
	docker compose exec web yarn create react-app .

yarn-create-react-app-npm:
	docker compose exec web yarn create react-app . --use-npm

yarn-create-react-app-ts:
	docker compose exec web yarn create react-app . --template typescript

# https://kic-yuuki.hatenablog.com/entry/2019/09/08/111817
yarn-add-eslint-config-react-app:
	docker compose exec web yarn add eslint-config-react-app

yarn-start:
	docker compose exec web yarn start

# ---- reduxjs/cra-template-redux-typescript ----

# https://github.com/reduxjs/cra-template-redux-typescript

# npx create-react-app my-app --template redux-typescript

yarn-create-react-app-redux-ts:
	docker compose exec web yarn create react-app --template redux-typescript .

# ---- PWA化 ----

# https://qiita.com/suzuki0430/items/9c2bd2b8839c164cfb28
# npx create-react-app [プロジェクト名] --template cra-template-pwa
# npx create-react-app [プロジェクト名] --template cra-template-pwa-typescript

yarn-create-react-app-ts-pwa:
	docker compose exec web yarn create react-app --template cra-template-pwa-typescript .

# ---- CRACO -----

# https://github.com/gsoft-inc/craco/blob/master/packages/craco/README.md

# カスタマイズ
# importのalias設定
# https://zukucode.com/2021/06/react-create-app-import-alias.html
yarn-add-D-craco:
	docker compose exec web yarn add -D @craco/craco eslint-import-resolver-alias

# craco.config.js
# const path = require('path');
#
# module.exports = {
#   webpack: {
#     alias: {
#       '@src': path.resolve(__dirname, 'src/'),
#     },
#   },
# };

# "scripts": {
#   "start": "craco start",
#   "build": "craco build",
#   "test": "craco test",
#   "eject": "craco eject"
# },

# tsconfig.paths.json
# {
#   "compilerOptions": {
#     "baseUrl": ".",
#     "paths": {
#       "@src/*": [
#         "./src/*"
#       ],
#     }
#   }
# }

# eslintrc.js
# module.exports = {
#   settings: {
#     'import/resolver': {
#       alias: {
#         map: [['@src', './src']],
#         extensions: ['.js', '.jsx', '.ts', '.tsx'],
#       },
#     },
#   },
# };

# tsconfig.json
# {
# 	"extends": "./tsconfig.paths.json",
# }

# Tailwind CSS for create-react-app
# https://v2.tailwindcss.com/docs/guides/create-react-app
# https://ramble.impl.co.jp/1681/#toc8
yarn-add-D-tailwind-v2-react:
	docker compose exec web yarn add -D tailwindcss@npm:@tailwindcss/postcss7-compat postcss@^7 autoprefixer@^9 @craco/craco

# "scripts": {
#     "start": "craco start",
#     "build": "craco build",
#     "test": "craco test",
#     "eject": "react-scripts eject"
#   },

# craco.config.js
# module.exports = {
#     style: {
#         postcss: {
#             plugins: [
#                 require('tailwindcss'),
#                 require('autoprefixer')
#             ]
#         }
#     }
# };
touch-caraco:
	docker compose exec web touch craco.config.js

# tailwind.config.js
# purge: [
#         './src/**/*.{js,jsx,ts,tsx}',
#         './public/index.html'
# ],
# yarn-tailwind-init:
	docker compose exec web yarn tailwind init

# ==== CSS in JSX ====

# styled-jsx
yarn-add-D-styledjsx:
	docker compose exec web yarn add -D styled-jsx

# styled-components
yarn-add-D-styledcomponents:
	docker compose exec web yarn add -D styled-components

#emotion
# https://github.com/iwakin999/next-emotion-typescript-example
# https://zenn.dev/iwakin999/articles/7a5e11e62ba668
# https://emotion.sh/docs/introduction
# https://qiita.com/cheez921/items/1d13545f8a0ea46beb51
# https://emotion.sh/docs/@emotion/babel-preset-css-prop
# https://www.npmjs.com/package/@emotion/babel-plugin
# https://qiita.com/xrxoxcxox/items/17e0762d8e69c1ef208f
#
# React v17以上
yarn-add-D-emotion-v11:
	docker compose exec web yarn add -D @emotion/react @emotion/styled @emotion/babel-plugin

# React v17以下
yarn-add-D-emotion-v10:
	docker compose exec web yarn add -D @emotion/core @emotion/styled @emotion/babel-preset-css-prop

# 非推奨
yarn-add-D-emotion-css:
	docker compose web yarn add -D @emotion/css

# Linaria
# https://github.com/callstack/linaria
# https://www.webopixel.net/javascript/1722.html
yarn-add-D-inaria:
	docker compose exec web yarn add -D @linaria/core @linaria/react @linaria/babel-preset @linaria/shaker @linaria/webpack-loader

# ==== Storybook ====

# 公式
# https://storybook.js.org/docs/react/get-started/introduction
# https://storybook.js.org/tutorials/intro-to-storybook/react/ja/get-started/
# https://storybook.js.org/tutorials/intro-to-storybook/angular/ja/get-started/

# Configure Storybook
# https://storybook.js.org/docs/react/configure/overview

# How to write stories
# https://storybook.js.org/docs/react/writing-stories/introduction

# ArgTypes
# https://storybook.js.org/docs/react/api/argtypes

# Args
# https://storybook.js.org/docs/react/writing-stories/args

# Actions
# https://storybook.js.org/docs/react/essentials/actions

# PropTypes(JS)
# https://ja.reactjs.org/docs/typechecking-with-proptypes.html
# https://www.npmjs.com/package/prop-types
# https://qiita.com/h-yoshikawa44/items/bab6845472e4d428732c
# https://zenn.dev/syu/articles/95eabfa766c358

# Interactions
# import { userEvent, within } from "@storybook/testing-library";
# import { expect } from "@storybook/jest";

# TypeScript
# https://storybook.js.org/docs/react/configure/typescript
# https://github.com/kiiiyo/learn-storybook/tree/fix/setup-storybook
# https://zenn.dev/kolife01/articles/nextjs-typescript-storybook-tailwind
# https://zenn.dev/otanu/articles/f0a0b2bd0d9c44

# Storybookのアップデート情報
# https://mokajima.com/updating-storybook/
# ※ Storybook 6.0 から TypeScript がビルトインサポートされたため、TypeScript 関連の設定が不要となった。
# https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#zero-config-typescript

# 記事
# https://reffect.co.jp/html/storybook
# https://www.techpit.jp/courses/109/curriculums/112/sections/841/parts/3119
# https://blog.microcms.io/storybook-react-use/
# https://zenn.dev/otanu/articles/f0a0b2bd0d9c44
# https://tech-mr-myself.hatenablog.com/entry/2020/02/05/214226
# https://qiita.com/masakinihirota/items/ac552b8b492d2b962818
# https://panda-program.com/posts/nextjs-storybook-typescript-errors
# https://tech-mr-myself.hatenablog.com/entry/2020/02/05/214226
# https://zenn.dev/yukishinonome/articles/6bc6e33d579276
# https://zenn.dev/tomon9086/articles/a0f3e549b4e848627e3c

# **** Storybookのセットアップ ****

# https://storybook.js.org/docs/react/get-started/install

# ⑴ StoryBookのインストール(.storybook, src/stories)
sb-init:
	docker compose exec web npx storybook init

# ⑵ ビルドとブラウザ表示
sb:
	docker compose exec web yarn storybook

# **** addons ****

# Supercharge Storybook
# https://storybook.js.org/addons

# Essential addons
# https://storybook.js.org/docs/react/essentials/introduction

# まとめ
# https://qiita.com/kichion/items/93ffe1ba773d26c20ff6
# https://blog.spacemarket.com/code/storybook-addon/
# https://tech.stmn.co.jp/entry/2021/05/17/155842
# https://iwb.jp/storybook-for-html-css-js-style-guide-tool-addons/

# @storybook/jest
# https://storybook.js.org/addons/@storybook/addon-jest
sb-add-jest:
	docker compose exec web yarn add -D @storybook/jest

# @storybook/addon-storysource
# https://storybook.js.org/addons/@storybook/addon-storysource
sb-add-storysource:
	docker compose exec web yarn add -D @storybook/addon-storysource

# @storybook/addon-console
# https://storybook.js.org/addons/@storybook/addon-console
sb-add-console:
	docker compose exec web yarn add -D @storybook/addon-console

# @storybook/addon-contexts
# https://storybook.js.org/addons/@storybook/addon-contexts
# https://kakehashi-dev.hatenablog.com/entry/2022/02/04/103000
sb-add-contexts:
	docker compose exec web yarn add -D @storybook/addon-contexts

# @storybook/addon-a11y
# https://storybook.js.org/addons/@storybook/addon-a11y
sb-add-a11y:
	docker compose exec web yarn add -D @storybook/addon-a11y

# @storybook/addon-google-analytics
# https://storybook.js.org/addons/@storybook/addon-google-analytics
sb-add-google-analytics:
	docker compose exec web yarn add -D @storybook/addon-google-analytics

# @whitespace/storybook-addon-html
# https://storybook.js.org/addons/@whitespace/storybook-addon-html
# https://zenn.dev/mym/articles/69badd52494031
yarn-add-D-storybook-addon-html:
	docker compose exec web yarn add -D @whitespace/storybook-addon-html

# @pickra/copy-code-block
# https://github.com/Pickra/copy-code-block
yarn-add-D-copy-code-block:
	docker compose exec web yarn add -D @pickra/copy-code-block

# @storybook/addon-info
# ※ @storybook/addon-infoの後継が@storybook/addon-docsとなり不要に
# Storybook 6.0 で非推奨
sb-add-info:
	docker compose exec web yarn add -D @storybook/addon-info @types/storybook__addon-info

# @storybook/addon-knobs
# ※ @storybook/addon-knobsの後継が@storybook/addon-controlsとなり不用に
# Storybook 7.0 より後で非推奨となる可能性
sb-add-knobs:
	docker compose exec web yarn add -D @storybook/addon-knobs

# react-docgen-typescript-loader
# https://github.com/styleguidist/react-docgen-typescript
# ※ Storybook 6.0以降より不要に
yarn-add-D-react-docgen-typescript-loader:
	docker compose exec web yarn add -D react-docgen-typescript-loader

# gh-pages
yarn-add-D-gh-pages:
	docker compose exec web yarn add -D gh-pages

# ==== Redux ====

# https://qiita.com/hironomiu/items/eac89ca4801534862fed

# https://redux.js.org/introduction/installation
# https://react-redux.js.org/tutorials/connect
# https://github.com/paularmstrong/normalizr
yarn-add-D-redux:
	docker-compos exec web yarn add -D redux react-redux @types/redux @types/react-redux @types/node redux-thunk connected-react-router reselect immer normalizr

# https://github.com/reduxjs/redux-toolkit
yarn-add-D-reduxjs-toolkit:
	docker compose exec web yarn add -D @reduxjs/toolkit

# https://redux-toolkit.js.org/
# https://redux-toolkit.js.org/tutorials/typescript
yarn-add-D-redux-full:
	docker compose exec web yarn add -D redux react-redux @types/redux @types/react-redux @reduxjs/toolkit @types/node redux-actions redux-logger @types/redux-logger redux-thunk connected-react-router reselect typescript-fsa typescript-fsa-reducers immer normalizr


yarn-add-line-liff:
	docker compose exec web yarn add -D @line/liff


# ---- thunk -----

# https://github.com/reduxjs/redux-thunk

yarn-add-D-redux-thunk:
	docker compose exec web yarn add -D redux-thunk

# ---- saga ----

# https://redux-saga.js.org/

yarn-add-D-redux-saga:
	docker compose exec web yarn add redux-saga

# ---- class-transformer ----

# https://github.com/typestack/class-transformer

yarn-add-D-class-transformer:
	docker compose exec web yarn add -D class-transformer reflect-metadata

# ---- class-validator ----

# https://github.com/typestack/class-validator

yarn-add-D-class-validator:
	docker compose exec web yarn add -D class-validator

# ==== Recoil ====

# https://recoiljs.org/docs/introduction/getting-started/
# https://zenn.dev/eitarok/articles/7ee50e2f91f939
yarn-add-D-recoil:
	docker compose exec web yarn add -D recoil recoil-persist

# ==== useSWR ====

# https://swr.vercel.app/ja

yarn-add-D-swr:
	docker compose exec web yarn add -D swr

# ==== React Query ====

# https://react-query.tanstack.com/
# https://github.com/tannerlinsley/react-query
# react-query@4.0.0-beta.10

yarn-add-D-react-query:
	docker compose exec web yarn add -D react-query

# ===== Zustand	====

# https://github.com/pmndrs/zustand

# 記事
# https://qiita.com/daishi/items/deb20d951f532b86f029
# https://reffect.co.jp/react/zustand
# https://zenn.dev/dai_shi/articles/f848fb75650753

yarn-add-D-zustand:
	docker compose exec web yarn add -D zustand

# ==== DIコンテナ ====

# https://github.com/rbuckton/reflect-metadata

# Decorators
# https://mae.chab.in/archives/59845
# https://qiita.com/taqm/items/4bfd26dfa1f9610128bc


# ---- tsyringe ----

# https://github.com/microsoft/tsyringe

# tsconfig.json
# {
#   "compilerOptions": {
#     "experimentalDecorators": true,
#     "emitDecoratorMetadata": true
#   }
# }

yarn-add-D-tsyringe:
	docker compose exec web yarn add -D tsyringe reflect-metadata


# babel.config.js
# plugins: [
#             'babel-plugin-transform-typescript-metadata',
#             /* ...the rest of your config... */
#          ]

yarn-add-D-babel-plugin-transform-typescript-metadata:
	docker compose exec web yarn add -D babel-plugin-transform-typescript-metadata

# ---- inversify ----

# https://inversify.io/
# https://github.com/inversify/InversifyJS


# tsconfig.json
# {
#     "compilerOptions": {
#         "target": "es5",
#         "lib": ["es6"],
#         "types": ["reflect-metadata"],
#         "module": "commonjs",
#         "moduleResolution": "node",
#         "experimentalDecorators": true,
#         "emitDecoratorMetadata": true
#     }
# }

yarn-add-D-inversify:
	docker compose exec web yarn add -D inversify reflect-metadata

# ---- typedi ----

# https://github.com/typestack/typedi

# tsconfig.json
# {
#   "compilerOptions": {
#     "experimentalDecorators": true,
#     "emitDecoratorMetadata": true
#   }
# }

yarn-add-D-typedi:
	docker compose exec web yarn add -D typedi reflect-metadata

# ==== Next.js ====

# https://nextjs.org/docs
# https://nextjs.org/docs/getting-started
# https://nextjs-ja-translation-docs.vercel.app/docs/getting-started
# https://zenn.dev/otanu/articles/f0a0b2bd0d9c44

# tutorial
# https://nextjs.org/learn/basics/create-nextjs-app
# npx create-next-app nextjs-blog --use-npm --example "https://github.com/vercel/next-learn/tree/master/basics/learn-starter"

# ---- Automatic Setup ----

# JS
yarn-create-next-app:
	docker compose exec web yarn create next-app .

npx-create-next-app:
	docker compose exec web npx create-next-app .

npx-create-next-app-use-npm:
	docker compose exec web npx create-next-app . --use-npm

# TS
yarn-create-next-app-ts:
	docker compose exec web yarn create next-app --typescript .

npx-create-next-app-ts:
	docker compose exec web npx create-next-app --ts .

# ---- Manual Setup ----

# package.json
# "scripts": {
#   "dev": "next dev -p 3001",
#   "build": "next build",
#   "start": "next start",
#   "lint": "next lint"
# }
yarn-add-D-next:
	yarn add -D next react react-dom

# **** おすすめ環境 ****

# ---- Next.js + Supabase + Mantine + React Query + Zustand etc ----

yarn-add-D-next-env:
	docker compose exec web yarn add -D dayjs @mantine/core @mantine/hooks @mantine/form @mantine/dates @mantine/next tabler-icons-react @supabase/supabase-js react-query@4.0.0-beta.10 @heroicons/react date-fns yup axios zustand @mantine/notifications

# **** 便利なライブラリ ****

# ---- tawindcss & prettier ----

# 以下のマニュアルに従いsetting
# https://tailwindcss.com/docs/guides/nextjs

# [CSSTree] Unknown at-rule `@tailwind` の解消方法
# https://qiita.com/masakinihirota/items/bd8c07aa54efad307588
# https://qiita.com/P-man_Brown/items/bf05437afecde268ec15
# https://it-blue-collar-dairy.com/deferi_at-rule-no-unknown_for_stylelint/
# https://zenn.dev/k_neko3/articles/1189846d6340ef

yarn-add-D-next-tailwind-prettier:
	docker compose exec web yarn add -D tailwindcss postcss autoprefixer prettier prettier-plugin-tailwindcss

# npx tailwindcss init -p

# 2022年現在、Mantine UI と Tailwind CSS を同時に使用した場合に、コンポーネントが上手く表示されないという問題に対処するために、
# tailwind.config.js に下記を追記
# corePlugins: {
#     preflight: false,
# },

# tailwind.config.js
# /** @type {import('tailwindcss').Config} */
# module.exports = {
#   content: [
#     './pages/**/*.{js,ts,jsx,tsx}',
#     './components/**/*.{js,ts,jsx,tsx}',
#   ],
#   theme: {
#     extend: {},
#   },
#   plugins: [],
#   corePlugins: {
#     preflight: false,
#   },
# }

# styles/global.css
# @import "tailwindcss/base";
# @import "tailwindcss/components";
# @import "tailwindcss/utilities";

# .prettierrc
# {
#   "singleQuote": true ,
#   "semi": false
# }

# ---- gray-matter ----

# https://github.com/jonschlinkert/gray-matter
# npm install --save gray-matter
yarn-add-D-gray-matter:
	docker compose exec web yarn add -D gray-matter

# ---- remark ----

# https://github.com/remarkjs/remark
# npm install --save remark remark-html
yarn-add-D-remark:
	docker compose exec web yarn add -D remark remark-html

# ---- date-fns ----

# https://date-fns.org/
# npm install --save date-fns
yarn-add-D-date-fns:
	docker compose exec web yarn add -D date-fns

# ==== UI ====

# ---- Material UI -----

# https://mui.com/getting-started/installation/
# https://next--material-ui.netlify.app/ja/guides/typescript/
# https://zenn.dev/h_yoshikawa0724/articles/2021-09-26-material-ui-v5
# https://zuma-lab.com/posts/next-mui-emotion-settings
# https://cloudpack.media/59677

# v4
yarn-add-D-ui-material-v4:
	dockert-compose exec web yarn add -D @material-ui/core @material-ui/icons @material-ui/styles @material-ui/system @types/material-ui

yarn-add-D-ui-mui-v4-webpack:
	docker compose exec web yarn add -D @material-ui/core @material-ui/icons @material-ui/system

# v5
yarn-add-D-ui-mui-emotion:
	docker compose exec web yarn add @mui/material @emotion/react @emotion/styled @mui/icons-material @mui/system @mui/styles @mui/lab

yarn-add-D-ui-mui-styled-components:
	docker compose exec web yarn add @mui/material @mui/styled-engine-sc styled-components @mui/icons-material @mui/system @mui/styles @mui/lab

# 推奨
yarn-add-D-ui-mui-v5-webpack:
	docker compose exec web yarn add -D @mui/material @mui/icons-material @mui/system @mui/styles @mui/lab


# ---- Chakra UI ----

# https://chakra-ui.com/docs/getting-started

yarn-add-D-ui-chakra:
	docker compose exec web yarn add -D @chakra-ui/react @emotion/react@^11 @emotion/styled@^11 framer-motion@^6 @chakra-ui/icons focus-visible

# ---- Mantine UI ----

# https://ui.mantine.dev/
# https://github.com/mantinedev/ui.mantine.dev

# xs,sm,md,lg,xlのデフォルト値一覧
# https://github.com/mantinedev/mantine/blob/master/src/mantine-styles/src/theme/default-theme.ts

# Shared props (すべてのMantineコンポーネントで共通するprops一覧)
# https://mantine.dev/pages/basics/#shared-props

# Responsive styles (breakpoints)
# https://mantine.dev/theming/responsive/#configure-breakpoints

# ※ @mantine/dates は dayjs に依存する

yarn-add-D-ui-mantine:
	docker compose exec web yarn add -D dayjs @mantine/core @mantine/hooks @mantine/form @mantine/dates @mantine/next @mantine/notifications

# **** Next.jsでの設定の仕方 ****

# Usage with Next.js
# https://mantine.dev/theming/next/

# 1. Create pages/_document.tsx file:
# - コピーして貼り付け
# - Next.jsでのサーバーサイドレンダリングに対応するために必要な設定

# 2. (Optional) Replace your pages/_app.tsx with
# - Mantineのプロバイダーをimport
# import { MantineProvider } from '@mantine/core';

# 3. React Queryを使用する場合
# - import
# import { QueryClient, QueryClientProvider } from 'react-query'
# import { ReactQueryDevtools } from 'react-query/devtools'

# - プロジェクト全体に適応されるグローバルな設定
# const queryClinent = new QueryClient({
#   defaultOptions: {
#     queries: {
#       retry: false,
#       refetchOnWindowFocus: false,
#     },
#   },
# })

# 4. コンポーネントをプロバイダーでラップする。
# function MyApp({ Component, pageProps }: AppProps) {
#   return (
#     <QueryClientProvider client={queryClient}>
#       <MantineProvider
#         withGlobalStyles
#         withNormalizeCSS
#         theme={{
#           colorScheme: 'dark',
#           fontFamily: 'Verdana, sans-self',
#         }}
#       >
#         <Component {...pageProps} />
#       </MantineProvider>
#       <ReactQueryDevtools initialIsOpen={false} />
#     </QueryClientProvider>
#   )
# }

# ---- Headless UI ----

# https://headlessui.dev/
# https://github.com/tailwindlabs/headlessui/tree/main/packages/%40headlessui-react
yarn-add-D-ui-headless:
	docker compose exec web yarn add @headlessui/react


# ---- react bootstrap ----

# https://react-bootstrap.github.io/
# https://github.com/react-bootstrap/react-bootstrap

yarn-add-D-react-bootstrap:
	docker compose exec web yarn add -D react-bootstrap bootstrap


# ---- React Hook Form & Yup | Zod ----

# https://react-hook-form.com/
# https://qiita.com/NozomuTsuruta/items/60d15d97eeef71993f06
# https://qiita.com/NozomuTsuruta/items/0140acaee87b7c4ed856
# https://zenn.dev/you_5805/articles/ad49926e7ad2d9
# https://www.npmjs.com/package/@hookform/error-message
# https://www.npmjs.com/package/yup
# https://www.npmjs.com/package/zod

yarn-add-D-react-hook-form-yup:
	docker compose exec web yarn add -D yup react-hook-form @hookform/resolvers @hookform/error-message

yarn-add-D-react-hook-form-zod:
	docker compose exec web yarn add -D zod react-hook-form @hookform/resolvers @hookform/error-message

# ---- Formik ----

yarn-add-D-formik-yup:
	docker compose web yarn add -D yup @types/yup formik

# ==== TypeScript =====

# https://github.com/microsoft/TypeScript/tree/main/lib
# https://qiita.com/ryokkkke/items/390647a7c26933940470
# https://zenn.dev/chida/articles/bdbcd59c90e2e1
# https://www.typescriptlang.org/ja/tsconfig
# https://typescriptbook.jp/reference/tsconfig/tsconfig.json-settings
yarn-add-D-loader-ts:
	docker compose exec web yarn add -D typescript@3.9.9 ts-loader

yarn-add-D-babel-ts:
	docker compose exec web yarn add -D typescript@3.9.9 babel-loader @babel/preset-typescript

yarn-add-D-loader-ts-full:
	docker compose exec web yarn add -D typescript@3.9.9 ts-loader @babel/preset-typescript @types/react @types/react-dom

# https://qiita.com/yamadashy/items/225f287a25cd3f6ec151
yarn-add-D-ts-option:
	docker compose exec web yarn add -D @types/webpack @types/webpack-dev-server ts-node @types/node typesync

# fork-ts-checker-webpack-plugin
# https://www.npmjs.com/package/fork-ts-checker-webpack-plugin
# https://github.com/TypeStrong/fork-ts-checker-webpack-plugin
yarn-add-D-plugin-forktschecker:
	docker compose exec web yarn add -D fork-ts-checker-webpack-plugin

# ESLint & & Stylelint & Prettier(TypeScript用)
# eslint-config-prettier
# ESLintとPrettierを併用する際に
#
# @typescript-eslint/eslint-plugin
# ESLintでTypeScriptのチェックを行うプラグイン
#
# @typescript-eslint/parser
# ESLintでTypeScriptを解析できるようにする
#
# husky
# Gitコマンドをフックに別のコマンドを呼び出せる
# 6系から設定方法が変更
#
# lint-staged
# commitしたファイル(stagingにあるファイル)にlintを実行することができる
#
# ※ eslint-config-prettierの8系からeslintrcのextendsの設定は変更
# https://github.com/prettier/eslint-config-prettier/blob/main/CHANGELOG.md#version-800-2021-02-21
yarn-add-D-ts-eslint-prettier:
	docker compose exec web yarn add -D eslint@7.32.0 eslint-config-prettier@7.2.0 prettier@2.5.1 @typescript-eslint/parser@4.33.0 @typescript-eslint/eslint-plugin@4.33.0 husky@4.3.8 lint-staged@10.5.3

# https://github.com/yannickcr/eslint-plugin-react
# https://qiita.com/Captain_Blue/items/5d6969643148174e70b3
# https://zenn.dev/yhay81/articles/def73cf8a02864
# https://qiita.com/ro-komatsuna/items/bbfe5304c78ce4a10f1a
# https://zenn.dev/ro_komatsuna/articles/eslint_setup
yarn-add-D-eslint-react:
	docker compose exec web yarn add -D eslint-plugin-react eslint-plugin-react-hooks eslint-config-airbnb eslint-plugin-import eslint-plugin-jsx-a11y

yarn-add-D-eslint-option:
	docker compose exec web yarn add -D eslint-plugin-babel flowtype-plugin relay-plugin eslint-plugin-ava eslint-plugin-eslint-comments eslint-plugin-simple-import-sort eslint-plugin-sonarjs eslint-plugin-unicorn

# .eslintrc.js
# module.exports = {
#     env: {
#         browser: true,
#         es6: true
#     },
#     extends: [
#         "eslint:recommended",
#         "plugin:@typescript-eslint/recommended",
#         "prettier",
#         "prettier/@typescript-eslint"
#     ],
#     plugins: ["@typescript-eslint"],
#     parser: "@typescript-eslint/parser",
#     parserOptions: {
#         "sourceType": "module",
#         "project": "./tsconfig.json"
#     },
#     root: true,
#     rules: {}
# }
touch-eslintrcjs:
	docker compose exec web touch .eslintrc.js

# stylelint-recommended版
# https://qiita.com/y-w/items/bd7f11013fe34b69f0df
yarn-add-D-stylelint-recommended:
	docker compose exec web yarn add -D stylelint stylelint-config-recommended stylelint-scss stylelint-config-recommended-scss stylelint-config-prettier stylelint-config-recess-order postcss-scss

# stylelint-standard版
# https://rinoguchi.net/2021/12/prettier-eslint-stylelint.html
# https://lab.astamuse.co.jp/entry/stylelint
# stylelintのorderモジュール選定
# https://qiita.com/nabepon/items/4168eae542861cfd69f7
# postcss-scss
# https://qiita.com/ariariasria/items/8d33943e34d94bbaa9bf
yarn-add-D-stylelint-standard:
	docker compose exec web yarn add -D stylelint stylelint-config-standard stylelint-scss stylelint-config-standard-scss stylelint-config-prettier stylelint-config-recess-order postcss-scss


# .stylelintrc.js
# module.exports = {
#   extends: ['stylelint-config-recommended'],
#   rules: {
#     'at-rule-no-unknown': [
#       true,
#       {
#         ignoreAtRules: ['extends', 'tailwind'],
#       },
#     ],
#     'block-no-empty': null,
#     'unit-whitelist': ['em', 'rem', 's'],
#   },
# }
touch-stylelintrcjs:
		docker compose exec web touch .stylelintrc.js
# https://scottspence.com/posts/stylelint-configuration-for-tailwindcss
# {
#   "extends": [
#     "stylelint-config-standard"
#   ],
#   "rules": {
#     "at-rule-no-unknown": [
#       true,
#       {
#         "ignoreAtRules": [
#           "apply",
#           "layer",
#           "responsive",
#           "screen",
#           "tailwind"
#         ]
#       }
#     ]
#   }
# }
touch-stylelintrc:
	docker compose exec web touch .stylelintrc

# .prettierrc
# {
#     "printWidth": 120,
#     "singleQuote": true,
#     "semi": false
# }
touch-prettierrc:
	docker compose exec web touch .prettierrc


# ==== テスト関連 ====

# ---- Jest ----

# https://jestjs.io/ja/
# https://jestjs.io/

# https://zenn.dev/otanu/articles/f0a0b2bd0d9c44
# https://qiita.com/hironomiu/items/eac89ca4801534862fed
# https://qiita.com/cheez921/items/a5168e4e5057c8faa897

# package.json
# "scripts": {
#     "test": "jest",
# },

yarn-add-D-jest:
	docker compose exec web yarn add -D jest ts-jest @types/jest ts-node

# https://qiita.com/suzu1997/items/e4ee2fc1f52fbf505481
# https://zenn.dev/t_keshi/articles/react-test-practice

yarn-add-D-jest-full:
	docker compose exec web yarn add -D jest jsdom eslint-plugin-jest @types/jest @types/jsdom ts-jest

# https://jestjs.io/ja/docs/tutorial-react

yarn-add-D-jest-babel-react:
	docker compose exec web yarn add -D jest babel-jest react-test-renderer

# jest.config.js生成
# roots: [
#   "<rootDir>/src"
# ],

# transform: {
#   "^.+\\.(ts|tsx)$": "ts-jest"
# },

# ? Would you like to use Jest when running "test" script in "package.json"?	n
# ? Would you like to use Typescript for the configuration file?	y
# ? Choose the test environment that will be used for testing	jsdom
# ? Do you want Jest to add coverage reports?	n
# Which provider should be used to instrument code for coverage?	babel
# https://jestjs.io/docs/cli#--coverageproviderprovider
# ? Automatically clear mock calls, instances and results before every test?	n

jest-init:
	docker compose exec web yarn jest --init

ts-jest-init:
	docker compose exec web yarn ts-jest config:init

# ---- React Testing Library ----

# https://testing-library.com/docs/react-testing-library/intro/
# https://qiita.com/ossan-engineer/items/4757d7457fafd44d2d2f

yarn-add-D-rtl:
	docker compose exec web yarn add -D @testing-library/react @testing-library/jest-dom

# https://testing-library.com/docs/ecosystem-user-event/
# https://www.npmjs.com/package/@testing-library/user-event
# https://github.com/testing-library/user-event

yarn-add-D-rtl-user-event:
	docker compose web yarn add -D @testing-library/user-event

# https://github.com/testing-library/react-hooks-testing-library
# https://www.npmjs.com/package/@testing-library/react-hooks
# https://qiita.com/cheez921/items/cd7d1d47287a35aa6723

yarn-add-D-rtl-react-hooks:
	docker compose web yarn add -D @testing-library/react-hooks

yarn-add-D-eslint-rtl:
	docker compose exec web yarn add -D eslint-plugin-testing-library eslint-plugin-jest-dom

# ---- react-test-renderer ----

# https://ja.reactjs.org/docs/test-renderer.html
# https://www.npmjs.com/package/react-test-renderer
# https://www.npmjs.com/package/@types/react-test-renderer

yarn-add-D-react-test-renderer:
	docker compose exec web yarn add -D react-test-renderer @types/react-test-renderer


# ---- Mock Service Worker ----

# https://mswjs.io/docs/
# https://github.com/mswjs/msw
# https://www.wakuwakubank.com/posts/765-react-mock-api/

yarn-add-D-msw:
	docker compose exec web yarn add -D msw

# ---- jest-fetch-mock ----

# https://www.npmjs.com/package/jest-fetch-mock

yanr-add-D-jest-fetch-mock:
	docker compose exec web yarn add -D jest-fetch-mock

# ---- Cypress ----

# https://docs.cypress.io/
# https://qiita.com/eyuta/items/a2454719c2d82c8bacd5

yarn-add-D-cypress:
	docker compose exec web yarn add -D cypress

# ==== Vue ====

# https://github.com/vuejs/vue-class-component
# https://github.com/kaorun343/vue-property-decorator

yarn-add-D-vue:
	docker compose exec web yarn add -D vue vue-class-component vue-property-decorator

# ---- Vue CLI ----

# https://cli.vuejs.org/guide/installation.html

yarn-g-add-vue-cli:
	docker compose exec web yarn global add @vue/cli

# Vue CLI のコマンド操作
# https://knooto.info/vue-cli-command-operations/

# プロジェクトの生成
# 現在地にプロジェクトを生成する
# vue create .
# 「foo」フォルダを作ってプロジェクトを生成する
# vue create foo

# Manually select features で TypeScriptなどの設定方法
# https://qiita.com/hisayuki/items/8cf2396f122ca6e452ee

# プロジェクトの実行
# npm run serve
# yarn serve

# UI 管理画面の起動
# vue ui

# Vue Router
# vue add vue-router

# Vuetify
# vue add vuetify

# ==== Nuxt ====


# ==== Chart.js ====

# chart.js
yarn-add-D-chartjs:
	docker compose exec web yarn add -D chart.js

# react-chartjs2
yarn-add-react-chartjs-2:
	docker compose exec web yarn add -D react-chartjs-2 chart.js

# ==== Swiper.js ====

# https://swiperjs.com/
# https://swiperjs.com/react

yarn-add-D-swiper:
	docker compose exec web yarn add -D swiper

# https://www.npmjs.com/package/react-id-swiper

yarn-add-D-swiper-better:
	docker compose exec web yarn add -D swiper@5.4.2 react-id-swiper@3.0.0

# ==== Three.js ====

# https://threejs.org/

yarn-add-D-three:
	docker compose exec web yarn add -D three @types/three @react-three/fiber

# ==== Framer Motion ====

# https://www.framer.com/motion/
# https://www.framer.com/docs/
# https://www.npmjs.com/package/framer-motion
# https://yarnpkg.com/package/framer-motion
# https://github.com/framer/motion

# Chakra UI + Framer Motion
# https://chakra-ui.com/guides/integrations/with-framer

yarn-add-D-framer-motion:
	docker compose exec web yarn add -D framer-motion


# ==== Firebase ====

yarn-add-firebase:
	docker compose exec web yarn add firebase react-firebase-hooks

yarn-g-add-firebase-tools:
	docker compose exec web yarn global add firebase-tools

# ==== Amplify ====

# https://aws.amazon.com/jp/amplify/

# ==== Supabase ====

# https://supabase.com/

yarn-add-D-supabase:
	docker compose exec web yarn add -D @supabase/supabase-js

# **** Supabaseの設定 ****

# ⑴ .env.localの作成
# SupabaseのAPI KEYを環境変数に追加
# NEXT_PUBLIC_SUPABASE_URL=
# NEXT_PUBLIC_SUPABASE_ANON_KEY=

# ⑵ Supabaseのダッシュボードで設定
#・設定 → API → Project URL
#・URLをコピーし、環境変数NEXT_PUBLIC_SUPABASE_URLに代入

#・設定 → API → Project API keys
#・anon publicの箇所をコピーし、環境変数NEXT_PUBLIC_SUPABASE_ANON_KEYに代入

# ⑶ ダミーのEmailを使う場合:
#・設定 → Authentication → Email Auth
#・Double confirm email changes と Enable email confirmations を無効

# ⑷ 設定した環境変数をプロジェクトに反映させる
# yarn run dev

# ⑸ utils/supabase.tsを作成
# 指定した環境変数からSupabaseのClientを作成しexport

# import { createClient } from '@supabase/supabase-js';
#
# const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
# const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
#
# export const supabase = createClient(supabaseUrl, supabaseAnonKey);

# ==== 便利なモジュール群 =====

# ---- モックサーバ ----

# json-server
# package.json
# {
#   "scripts": {
#     "start": "npx json-server --watch db.json --port 3001"
# }

yarn-add-D-jsonserver:
	docker compose yarn add -D json-server

# http-server
# https://www.npmjs.com/package/http-server

yarn-add-D-http-server:
	docker compose exec web yarn add -D http-server

# serve
# https://www.npmjs.com/package/serve

yarn-add-D-serve:
	docker compose exec web yarn add -D serve

# Servør
# https://www.npmjs.com/package/servor

yarn-add-D-servor:
	docker compose exec web yarn add -D servor

# ---- 便利なモジュール ----

# glob
# sass ファイル内で @import するときに*（アスタリスク）を使用できるようにするため

yarn-add-D-loader-importglob:
	docker compose add -D import-glob-loader

yarn-add-D-glob:
	docker compose exec web yarn add -D glob

# lodash
# https://qiita.com/soso_15315/items/a08e28def541c28458a0
# import _ from 'lodash';

yarn-add-D-lodash:
	docker compose exec web yarn add -D lodash @types/lodash

# https://www.nxworld.net/support-modules-for-npm-scripts-task.html
# publicフォルダを自動でクリーンにするコマンドも追加
# rimraf
# Linuxのrmコマンドと似たrimrafコマンドが使えるようになる

yarn-add-D-rimraf:
	docker compose exec web yarn add -D rimraf

yarn-cleanup:
	docker compose exec web yarn -D cleanup

# コピー
yarn-add-D-cpx:
	docker compose exec web yarn add -D cpx

# ディレクトリ作成
yarn-add-D-mkdirp:
	docker compose exec web yarn add -D mkdirp

# ディレクトリ・ファイル名を変更
yarn-add-D-rename:
	docker compose exec web yarn add -D rename-cli

# まとめて実行・直列/並列実行
yarn-add-D-npm-run-all:
	docker compose exec web yarn add -D npm-run-all

# 監視
yarn-add-D-onchange:
	docker compose exec web yarn add -D onchange

# 環境変数を設定・使用する
yarn-add-D-cross-env:
	docker compose exec web yarn add -D cross-env

# ブラウザ確認をサポート
yarn-add-D-browser-sync:
	docker compose exec web yarn add -D browser-sync

# axios
yarn-add-D-axios:
	docker compose exec web yarn add -D axios @types/axios

# sort-package-json
# package.json を綺麗にしてくれる

yarn-add-D-sort-package-json:
	docker compose exec web yarn add -D sort-package-json

# node-sass typed-scss-modules
# CSS Modulesを使用する際に必要
# https://www.npmjs.com/package/typed-scss-modules
# https://github.com/skovy/typed-scss-modules
# https://zenn.dev/noonworks/scraps/61091d5a367487

yarn-add-D-nodesass:
	docker compose exec web yarn add -D node-sass typed-scss-modules

# dayjs
# https://day.js.org/
# https://github.com/iamkun/dayjs/
# https://www.npmjs.com/package/dayjs

# まとめ
# https://qiita.com/tobita0000/items/0f9d0067398efdc2931e
# https://zenn.dev/biwa/articles/8d6d1030302484

yarn-add-D-dayjs:
	docker compose exec web yarn add -D dayjs

# ---- Node.js ----

# Express
# https://www.npmjs.com/package/@types/express

yarn-add-D-express:
	docker compose exec web yarn add -D express @types/express

# proxy中継
# https://github.com/chimurai/http-proxy-middleware
# https://www.npmjs.com/package/http-proxy-middleware
# https://www.twilio.com/blog/node-js-proxy-server-jp
# https://zenn.dev/daisukesasaki/articles/d67dfa0d75fdf77de4ad

yarn-add-D-proxy:
	docker compose exec web yarn add -D http-proxy-middleware

# ログ出力
# https://www.npmjs.com/package/morgan
# https://www.npmjs.com/package/@types/morgan
# https://qiita.com/mt_middle/items/543f83393c357ad3ab12

yarn-add-D-morgan:
		docker compose exec web yarn add -D morgan @types/morgan

# Sqlite3
yarn-add-D-sqlite3:
	docker compose exec web yarn add -D sqlite3

# body-parser
yarn-add-D-bodyparser:
	docker compose exec web yarn add -D body-parser

# node-dev
# package.json
# {
#   "scripts": {
#     "start": "npx node-dev app/app.js"
# }

yarn-add-D-nodedev:
	docker compose exec web yarn add -D node-dev

# node-fetch
# サーバーサイドでfetchメソッドが使える

yarn-add-D-node-fetch:
	docker compose exec web yarn add -D node-fetch


# js-base64
# APIで取得したデータをデコードできる

yarn-add-D-js-base64:
	docker compose exec web yarn add -D js-base64

# ==== Create React App 設定手順 ====

# ⑴ テンプレ生成

# yarn create react-app --template redux-typescript .

# -----------------------------------------

# ⑵ package.json修正

# "devDependencies": {
#     "@craco/craco": "^6.4.3",
#     "@typescript-eslint/eslint-plugin": "^5.19.0",
#     "@typescript-eslint/parser": "^5.19.0",
#     "eslint": "^8.13.0",
#     "eslint-config-prettier": "^8.5.0",
#     "eslint-import-resolver-alias": "^1.1.2",
#     "history": "4.10.1",
#     "lint-staged": "10.5.3",
#     "node-sass": "^7.0.1",
#     "npm-run-all": "^4.1.5",
#     "prettier": "^2.6.2",
#     "stylelint": "^14.5.1",
#     "stylelint-config-prettier": "^9.0.3",
#     "stylelint-config-recess-order": "^3.0.0",
#     "stylelint-config-standard": "^25.0.0",
#     "stylelint-config-standard-scss": "^3.0.0",
#     "stylelint-scss": "^4.1.0",
#     "typed-scss-modules": "^6.3.0"
#   },

#   "resolutions": {
#     "@types/react": "17.0.14",
#     "@types/react-dom": "17.0.14"
#   },

#   "scripts": {
#     "start": "npm run lint-fix && craco start",
#     "build": "npm run lint-fix && craco build",
#     "test": "craco test",
#     "eject": "craco eject",
#     "lint:es": "npx eslint --fix './src/**/*.{js,jsx,ts,tsx}'",
#     "lint:style": "npx stylelint --fix './src/**/*.{css,scss}'",
#     "lint": "npm-run-all lint:{es,style}",
#     "format": "npx prettier --write './src/**/*.{js,jsx,ts,tsx,css,scss}'",
#     "lint-fix": "npm run lint && npm rum format",
#     "tsm": "npx typed-scss-modules src --implementation node-sass --nameFormat none --exportType default",
#     "tsmw": "npx typed-scss-modules src --watch --implementation node-sass --nameFormat none --exportType default"
#   },

# "husky": {
#     "hooks": {
#       "pre-commit": "lint-staged"
#     }
#   },

#   "lint-staged": {
#     "./src/**/*.{js,jsx,ts,tsx}": [
#       "npm run lint-fix"
#     ]
#   }

# -----------------------------------------

# ⑶ touch craco.config.js .eslintrc.js tsconfig.paths.json

# eslintrc.js

# module.exports = {
#   settings: {
#     "import/resolver": {
#       alias: {
#         map: [["@src", "./src"]],
#         extensions: [".js", ".jsx", ".ts", ".tsx"],
#       },
#     },
#   },
#   extends: [
#     "eslint:recommended",
#     "plugin:@typescript-eslint/recommended",
#     "prettier",
#     // "prettier/@typescript-eslint"
#   ],
#   plugins: ["@typescript-eslint"],
#   parser: "@typescript-eslint/parser",
#   parserOptions: {
#     sourceType: "module",
#   },
#   env: {
#     browser: true,
#     node: true,
#     es6: true,
#   },
#   rules: {
#     // 適当なルール
#     "@typescript-eslint/ban-types": "warn",
#   },
# };

# *********************

# stylelint.config.js

# module.exports = {
#   extends: ['stylelint-config-standard', 'stylelint-config-recess-order', 'stylelint-config-prettier'],
#   plugins: ['stylelint-scss'],
#   customSyntax: 'postcss-scss',
#   ignoreFiles: ['**/node_modules/**', '/public/'],
#   root: true,
#   rules: {
#     'at-rule-no-unknown': [
#       true,
#       {
#         ignoreAtRules: ['tailwind', 'apply', 'variants', 'responsive', 'screen', 'use'],
#       },
#     ],
#     'scss/at-rule-no-unknown': [
#       true,
#       {
#         ignoreAtRules: ['tailwind', 'apply', 'variants', 'responsive', 'screen'],
#       },
#     ],
#     'declaration-block-trailing-semicolon': null,
#     'no-descending-specificity': null,
#     // https://github.com/humanmade/coding-standards/issues/193
#     'selector-class-pattern': '^[a-zA-Z][a-zA-Z0-9_-]+$',
#     'keyframes-name-pattern': '^[a-zA-Z][a-zA-Z0-9_-]+$',
#     'selector-id-pattern': '^[a-z][a-zA-Z0-9_-]+$',
#     'property-no-unknown': [
#       true,
#       {
#         ignoreProperties: ['composes'],
#       },
#     ],
#   },
# };

# *********************

# .prettierrc

# {
#   "printWidth": 120,
#   "singleQuote": true,
#   "semi": true
# }

# *********************

# craco.config.js

# const path = require("path");
# module.exports = {
#   webpack: {
#     alias: {
#       "@src": path.resolve(__dirname, "src/"),
#     },
#   },
# };

# *********************

# tsconfig.json

# {
#   "compilerOptions": {
#     "target": "es5",
#     "lib": [
#       "dom",
#       "dom.iterable",
#       "esnext"
#     ],
#     "allowJs": true,
#     "skipLibCheck": true,
#     "esModuleInterop": true,
#     "allowSyntheticDefaultImports": true,
#     "strict": true,
#     "forceConsistentCasingInFileNames": true,
#     "noFallthroughCasesInSwitch": true,
#     "module": "esnext",
#     "moduleResolution": "node",
#     "resolveJsonModule": true,
#     "isolatedModules": true,
#     "noEmit": true,
#     "jsx": "react-jsx"
#   },
#   "include": [
#     "src"
#   ],
#   "extends": "./tsconfig.paths.json"
# }

# *********************

# tsconfig.paths.json

# {
#   "compilerOptions": {
#     "baseUrl": ".",
#     "paths": {
#       "@src/*": [
#         "./src/*"
#       ],
#     }
#   }
# }

# -----------------------------------------

# ⑷ React 17に修正

# index.tsx
# App.tsx

# -----------------------------------------

# ⑸ 追加ライブラリ

# API ：

# "@types/axios": "^0.14.0",
# "axios": "^0.27.2",

# *********************

# ルーティング：

# "@types/react-router-dom": "^5.3.3",

# "connected-react-router": "^6.9.2",
# "history": "4.10.1",

# "react-router-dom": "5.3.0",

# *********************

# ロガー：

# "@types/redux-logger": "^3.0.9",

# "redux-logger": "^3.0.6",

# *********************

# フォームバリデーション：

# "@hookform/error-message": "^2.0.0",
# "@hookform/resolvers": "^2.8.8",

# "react-hook-form": "^7.29.0",

# "yup": "^0.32.11"

# *********************

# MUI：

# "@material-ui/core": "^4.12.4",
# "@material-ui/icons": "^4.11.3",
# "@material-ui/styles": "^4.11.5",
# "@material-ui/system": "^4.12.2",

# "@types/material-ui": "^0.21.12",

# *********************

# Chart.js ：

# "chart.js": "^2.9.3",
# "react-chartjs-2": "^2.9.0",

# *********************

# "firebase": "^9.6.11",

# *********************

# "node-sass": "^7.0.1",

# *********************

# "react-countup": "^6.2.0",

# "typed-scss-modules": "^6.4.0"

# *********************

# "react-icons": "^4.3.1",
