bundle && \
bundle exec rails db:drop db:create && \
pg_restore -O -d "osp_app" "../decidim-cd34/pg_dump/$(ls -t ../decidim-cd34/pg_dump | head -1)";\
bundle exec rails db:schema:migrations_replace && \
bundle exec rails db:migrate