# frozen_string_literal: true

require "decidim/translator_configuration_helper"
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
# You can remove the 'faker' gem if you don't want Decidim seeds.

Decidim::TranslatorConfigurationHelper.able_to_seed?

if ENV["HEROKU_APP_NAME"].present?
  ENV["DECIDIM_HOST"] = "#{ENV.fetch("HEROKU_APP_NAME", nil)}.herokuapp.com"
  ENV["SEED"] = "true"
end
Decidim.seed!

org = Decidim::Organization.first

actives = [{
  slug: "slug-#{Random.rand(1..9_999)}",
  weight: Random.rand(10),
  start_date: 6.months.ago,
  end_date: 3.months.from_now
}, {
  slug: "slug-#{Random.rand(1..9_999)}",
  weight: Random.rand(10),
  start_date: 1.month.ago,
  end_date: 1.month.from_now
},
           {
             slug: "slug-#{Random.rand(1..9_999)}",
             weight: Random.rand(10),
             start_date: 1.year.ago,
             end_date: 2.years.from_now
           }]

futures = [{
  slug: "slug-#{Random.rand(1..9_999)}",
  weight: Random.rand(10),
  start_date: 1.year.from_now,
  end_date: 4.years.from_now
},
           {
             slug: "slug-#{Random.rand(1..9_999)}",
             weight: Random.rand(10),
             start_date: 2.months.from_now,
             end_date: 4.months.from_now
           },
           {
             slug: "slug-#{Random.rand(1..9_999)}",
             weight: Random.rand(10),
             start_date: 19.years.from_now,
             end_date: 35.years.from_now
           },
           {
             slug: "slug-#{Random.rand(1..9_999)}",
             weight: Random.rand(10),
             start_date: 1.week.from_now,
             end_date: 2.weeks.from_now
           }]

pasts = [{
  slug: "slug-#{Random.rand(1..9_999)}",
  weight: Random.rand(10),
  start_date: 1.week.ago,
  end_date: 3.days.ago
},
         {
           slug: "slug-#{Random.rand(1..9_999)}",
           weight: Random.rand(10),
           start_date: 2.months.ago,
           end_date: 1.month.ago
         },
         {
           slug: "slug-#{Random.rand(1..9_999)}",
           weight: Random.rand(10),
           start_date: 19.years.ago,
           end_date: 4.years.ago
         },
         {
           slug: "slug-#{Random.rand(1..9_999)}",
           weight: Random.rand(10),
           start_date: 10.years.ago,
           end_date: 1.week.ago
         }]

(actives + futures + pasts).each_with_index do |process, index|
  Decidim::ParticipatoryProcess.create!(
    title: { fr: "Participatory process d'essai #{index} (start: #{process[:start_date].strftime("%d-%m-%Y")})" },
    subtitle: { fr: "Participatory process d'essai" },
    description: { fr: "<p>Participatory process d'essai</p>" },
    short_description: { fr: "<p>Participatory process d'essai</p>" },
    published_at: Time.current,
    organization: org,
    slug: process[:slug],
    weight: process[:weight],
    start_date: process[:start_date],
    end_date: process[:end_date]
  )
end
