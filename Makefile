migration:
	docker-compose run app "rails db:migrate"

upgrade:
	docker-compose run app "rake decidim:upgrade"

up:
	docker-compose up

prod:
	docker-compose -f docker-compose.prod.yml up

build:
	docker-compose build

drop:
	docker-compose run app "rake db:drop"

setup:
	docker-compose run app "rake db:create db:migrate"

seed:
	docker-compose run app "SEED=true rake db:seed"
