# frozen_string_literal: true

require "benchmark/plot"
require "decidim/faker/localized"

namespace :benchmark do
  desc "Run benchmark, example: BENCHMARK_FLAGS=\"filters,address,all\" bundle exec rake benchmark:run_proposals"
  task run_proposals: :environment do
    raise "Please activate cache" unless Rails.application.config.action_controller.perform_caching

    Rails.cache.clear

    participatory_space = Decidim::ParticipatoryProcess.first
    proposal_component = Decidim::Component.find_by(participatory_space: participatory_space, manifest_name: "proposals")
    organization = proposal_component.organization

    if Decidim::AreaType.count <= 2
      puts "Creating more seeds for decidim benchmark..."

      ActiveRecord::Base.transaction do
        proposals_settings = proposal_component.dup.settings
        proposals_settings[:geocoding_enabled] = true
        proposal_component.update!(settings: proposals_settings)

        100.times do |i|
          territorial = Decidim::AreaType.create!(
            name: Decidim::Faker::Localized.literal("territorial_#{i}"),
            plural: Decidim::Faker::Localized.literal("territorials_#{i}"),
            organization: organization
          )

          sectorial = Decidim::AreaType.create!(
            name: Decidim::Faker::Localized.literal("sectorials_#{i}"),
            plural: Decidim::Faker::Localized.literal("sectorials_#{i}"),
            organization: organization
          )

          3.times do |j|
            Decidim::Area.create!(
              name: Decidim::Faker::Localized.literal("territorial_area_#{i}_#{j}"),
              area_type: territorial,
              organization: organization
            )
          end

          5.times do |j|
            Decidim::Area.create!(
              name: Decidim::Faker::Localized.literal("sectorial_area_#{i}_#{j}"),
              area_type: sectorial,
              organization: organization
            )
          end

          2.times do
            Decidim::Category.create!(
              name: Decidim::Faker::Localized.sentence(word_count: 5),
              description: Decidim::Faker::Localized.wrapped("<p>", "</p>") do
                Decidim::Faker::Localized.paragraph(sentence_count: 3)
              end,
              participatory_space: participatory_space
            )
          end

          5.times do |n|
            state, answer, state_published_at = if n > 3
                                                  ["accepted", Decidim::Faker::Localized.sentence(word_count: 10), Time.current]
                                                elsif n > 2
                                                  ["rejected", nil, Time.current]
                                                elsif n > 1
                                                  ["evaluating", nil, Time.current]
                                                elsif n.positive?
                                                  ["accepted", Decidim::Faker::Localized.sentence(word_count: 10), nil]
                                                else
                                                  [nil, nil, nil]
                                                end

            if participatory_space.scope
              scopes = participatory_space.scope.descendants
              global = participatory_space.scope
            else
              scopes = participatory_space.organization.scopes
              global = nil
            end

            params = {
              address: "#{i} avenue daumesnil 75012 paris",
              component: proposal_component,
              category: participatory_space.categories.sample,
              scope: Faker::Boolean.boolean(true_ratio: 0.5) ? global : scopes.sample,
              title: { en: Faker::Lorem.sentence(word_count: 2) },
              body: { en: Faker::Lorem.paragraphs(number: 2).join("\n") },
              state: state,
              answer: answer,
              answered_at: state.present? ? Time.current : nil,
              state_published_at: state_published_at,
              published_at: Time.current
            }

            proposal = Decidim.traceability.perform_action!(
              "publish",
              Decidim::Proposals::Proposal,
              Decidim::User.find_by(admin: true),
              visibility: "all"
            ) do
              proposal = Decidim::Proposals::Proposal.new(params)
              meeting_component = participatory_space.components.find_by(manifest_name: "meetings")

              coauthor = case n
                         when 0
                           Decidim::User.where(decidim_organization_id: participatory_space.decidim_organization_id).order(Arel.sql("RANDOM()")).first
                         when 1
                           Decidim::UserGroup.where(decidim_organization_id: participatory_space.decidim_organization_id).order(Arel.sql("RANDOM()")).first
                         when 2
                           Decidim::Meetings::Meeting.where(component: meeting_component).order(Arel.sql("RANDOM()")).first
                         else
                           participatory_space.organization
                         end
              proposal.add_coauthor(coauthor)
              proposal.save!
              proposal
            end

            if proposal.state.nil?
              email = "amendment-author-#{participatory_space.underscored_name}-#{participatory_space.id}-#{n}-amend#{n}@example.org"
              name = "#{Faker::Name.name} #{participatory_space.id} #{n} amend#{n}"

              author = Decidim::User.find_or_initialize_by(email: email)
              author.update!(
                password: "decidim123456789",
                password_confirmation: "decidim123456789",
                name: name,
                nickname: "nickname-#{participatory_space.id}-#{n}-amend#{n}",
                organization: organization,
                tos_agreement: "1",
                confirmed_at: Time.current
              )

              group = Decidim::UserGroup.create!(
                name: Faker::Name.name,
                nickname: "n-#{participatory_space.id}-#{n}-group#{n}_#{proposal.id}",
                email: Faker::Internet.email,
                extended_data: {
                  document_number: Faker::Code.isbn,
                  phone: Faker::PhoneNumber.phone_number,
                  verified_at: Time.current
                },
                decidim_organization_id: organization.id,
                confirmed_at: Time.current
              )

              Decidim::UserGroupMembership.create!(
                user: author,
                role: "creator",
                user_group: group
              )

              params = {
                address: "#{i} avenue daumesnil 75012 paris",
                component: proposal_component,
                category: participatory_space.categories.sample,
                scope: Faker::Boolean.boolean(true_ratio: 0.5) ? global : scopes.sample,
                title: { en: "#{proposal.title["en"]} #{Faker::Lorem.sentence(word_count: 1)}" },
                body: { en: "#{proposal.body["en"]} #{Faker::Lorem.sentence(word_count: 3)}" },
                state: "evaluating",
                answer: nil,
                answered_at: Time.current,
                published_at: Time.current
              }

              emendation = Decidim.traceability.perform_action!(
                "create",
                Decidim::Proposals::Proposal,
                author,
                visibility: "public-only"
              ) do
                emendation = Decidim::Proposals::Proposal.new(params)
                emendation.add_coauthor(author, user_group: author.user_groups.first)
                emendation.save!
                emendation
              end

              Decidim::Amendment.create!(
                amender: author,
                amendable: proposal,
                emendation: emendation,
                state: "evaluating"
              )
            end

            (n % 3).times do |m|
              email = "vote-author-#{participatory_space.underscored_name}-#{participatory_space.id}-#{n}-#{m}@example.org"
              name = "#{Faker::Name.name} #{participatory_space.id} #{n} #{m}"

              author = Decidim::User.find_or_initialize_by(email: email)
              author.update!(
                password: "decidim123456789",
                password_confirmation: "decidim123456789",
                name: name,
                nickname: "kname-#{participatory_space.id}-#{n}-#{m}",
                organization: organization,
                tos_agreement: "1",
                confirmed_at: Time.current,
                personal_url: Faker::Internet.url,
                about: Faker::Lorem.paragraph(sentence_count: 2)
              )

              Decidim::Proposals::ProposalVote.create!(proposal: proposal, author: author) unless proposal.published_state? && proposal.rejected?
              Decidim::Proposals::ProposalVote.create!(proposal: emendation, author: author) if emendation
            end

            unless proposal.published_state? && proposal.rejected?
              (n * 2).times do |index|
                email = "endorsement-author-#{participatory_space.underscored_name}-#{participatory_space.id}-#{n}-endr#{index}@example.org"
                name = "#{Faker::Name.name} #{participatory_space.id} #{n} endr#{index}"

                author = Decidim::User.find_or_initialize_by(email: email)
                author.update!(
                  password: "decidim123456789",
                  password_confirmation: "decidim123456789",
                  name: name,
                  nickname: "nick_#{i}_#{n}_#{index}",
                  organization: organization,
                  tos_agreement: "1",
                  confirmed_at: Time.current
                )
                if index.even?
                  group = Decidim::UserGroup.create!(
                    name: Faker::Name.name,
                    nickname: "nickgroup_#{i}_#{n}_#{index}",
                    email: Faker::Internet.email,
                    extended_data: {
                      document_number: Faker::Code.isbn,
                      phone: Faker::PhoneNumber.phone_number,
                      verified_at: Time.current
                    },
                    decidim_organization_id: organization.id,
                    confirmed_at: Time.current
                  )

                  Decidim::UserGroupMembership.create!(
                    user: author,
                    role: "creator",
                    user_group: group
                  )
                end
                Decidim::Endorsement.create!(resource: proposal, author: author, user_group: author.user_groups.first)
              end
            end

            (n % 3).times do
              author_admin = Decidim::User.where(organization: organization, admin: true).all.sample

              Decidim::Proposals::ProposalNote.create!(
                proposal: proposal,
                author: author_admin,
                body: Faker::Lorem.paragraphs(number: 2).join("\n")
              )
            end

            Decidim::Comments::Seed.comments_for(proposal)
          end
        end

        Decidim::Proposals::Proposal.where.not(address: nil).find_each do |proposal|
          latitude, longitude = proposal.geocode

          proposal.update!(
            latitude: latitude,
            longitude: longitude
          )
        end
      end
    end

    proposals_url = "http://localhost:3000/processes/#{participatory_space.slug}/f/#{proposal_component.id}"
    benchmark_times = ENV.fetch("BENCHMARK_TIMES", 10).to_i
    title = ["Performance benchmark", ENV.fetch("BENCHMARK_PREFIX", "")].join(" ")
    prefix = ENV.fetch("BENCHMARK_PREFIX", "").gsub(" ", "_")
    file_name = [prefix, "performance_benchmark", benchmark_times.to_s].reject(&:empty?).join("_")
    count = Dir.glob("benchmarks/*").map { |f| f.split("/").last.split("_")[0..-2].join("_") }.select { |f| f == file_name.downcase }.count
    flags = ["default"] + ENV.fetch("BENCHMARK_FLAGS", "all").split(",").map(&:strip).reject(&:empty?).map(&:downcase)

    curl_command = ->(url, new) { `curl -sS -H "X-FEATURE-FLAG: #{new}" -o /dev/null #{url}` }
    benchmark_command = lambda do |url, flag, iteration|
      puts "Benchmarking #{url} #{iteration + (benchmark_times * flags.find_index(flag))} of #{benchmark_times * flags.size} with #{flag} flag"
      curl_command.call(url, flag)
    end

    puts "Benchmarking #{benchmark_times} times for #{proposals_url}..."

    Dir.mkdir("benchmarks") unless File.exist?("benchmarks")

    puts "Checking if url exists..."
    raise "Url returns an non 200 status" unless `curl -o /dev/null -s -w '%{http_code}' #{proposals_url}` == "200"

    puts "Url exists! Starting benchmark..."

    Dir.chdir("benchmarks") do
      Benchmark.plot (1..benchmark_times), title: title, file_name: [file_name, count].join("_").downcase do |x|
        flags.each do |flag|
          x.report flag.titleize do |i|
            benchmark_command.call(proposals_url, flag, i)
          end
        end
      end
    end
  end

  desc "Run benchmark, example: BENCHMARK_FLAGS=\"all,cache_cell\" bundle exec rake benchmark:run_budgets"
  task run_budgets: :environment do
    raise "Please activate cache" unless Rails.application.config.action_controller.perform_caching

    Rails.cache.clear

    participatory_space = Decidim::ParticipatoryProcess.first
    budget_component = Decidim::Component.find_by(participatory_space: participatory_space, manifest_name: "budgets")
    organization = budget_component.organization
    budget = Decidim::Budgets::Budget.where(component: budget_component).last

    budgets_settings = budget_component.dup.settings
    budgets_settings.projects_per_page = 500
    budget_component.update!(settings: budgets_settings)

    if Decidim::AreaType.count <= 2
      puts "Creating more seeds for decidim benchmark..."

      ActiveRecord::Base.transaction do
        100.times do |i|
          territorial = Decidim::AreaType.create!(
            name: Decidim::Faker::Localized.literal("territorial_#{i}"),
            plural: Decidim::Faker::Localized.literal("territorials_#{i}"),
            organization: organization
          )

          sectorial = Decidim::AreaType.create!(
            name: Decidim::Faker::Localized.literal("sectorials_#{i}"),
            plural: Decidim::Faker::Localized.literal("sectorials_#{i}"),
            organization: organization
          )

          3.times do |j|
            Decidim::Area.create!(
              name: Decidim::Faker::Localized.literal("territorial_area_#{i}_#{j}"),
              area_type: territorial,
              organization: organization
            )
          end

          5.times do |j|
            Decidim::Area.create!(
              name: Decidim::Faker::Localized.literal("sectorial_area_#{i}_#{j}"),
              area_type: sectorial,
              organization: organization
            )
          end

          2.times do
            Decidim::Category.create!(
              name: Decidim::Faker::Localized.sentence(word_count: 5),
              description: Decidim::Faker::Localized.wrapped("<p>", "</p>") do
                Decidim::Faker::Localized.paragraph(sentence_count: 3)
              end,
              participatory_space: participatory_space
            )
          end

          5.times do |n|
            project = Decidim::Budgets::Project.create!(
              budget: budget,
              scope: participatory_space.organization.scopes.sample,
              category: participatory_space.categories.sample,
              title: Decidim::Faker::Localized.literal("budget_title_#{i}_#{n}"),
              description: Decidim::Faker::Localized.wrapped("<p>", "</p>") do
                Decidim::Faker::Localized.literal("budget_description_#{i}_#{n}")
              end,
              budget_amount: Faker::Number.number(digits: 8)
            )

            attachment_collection = Decidim::AttachmentCollection.create!(
              name: Decidim::Faker::Localized.literal("attachment_collection_name_#{i}_#{n}"),
              description: Decidim::Faker::Localized.literal("attachment_collection_description_#{i}_#{n}"),
              collection_for: project
            )

            Decidim::Attachment.create!(
              title: Decidim::Faker::Localized.literal("attachment_title_#{i}_#{n}"),
              description: Decidim::Faker::Localized.literal("attachment_description_#{i}_#{n}"),
              attachment_collection: attachment_collection,
              attached_to: project,
              content_type: "application/pdf",
              file: ActiveStorage::Blob.create_after_upload!(
                io: File.open(File.join(Rails.root, "db", "seeds_data", "Exampledocument.pdf")),
                filename: "Exampledocument.pdf",
                content_type: "application/pdf",
                metadata: nil
              )
            )
            Decidim::Attachment.create!(
              title: Decidim::Faker::Localized.literal("attachment_title_#{i}_#{n}"),
              description: Decidim::Faker::Localized.literal("attachment_description_#{i}_#{n}"),
              attached_to: project,
              content_type: "image/jpeg",
              file: ActiveStorage::Blob.create_after_upload!(
                io: File.open(File.join(Rails.root, "db", "seeds_data", "city.jpeg")),
                filename: "city.jpeg",
                content_type: "image/jpeg",
                metadata: nil
              )
            )
            Decidim::Attachment.create!(
              title: Decidim::Faker::Localized.literal("attachment_title_#{i}_#{n}"),
              description: Decidim::Faker::Localized.literal("attachment_description_#{i}_#{n}"),
              attachment_collection: attachment_collection,
              attached_to: project,
              content_type: "application/pdf",
              file: ActiveStorage::Blob.create_after_upload!(
                io: File.open(File.join(Rails.root, "db", "seeds_data", "Exampledocument.pdf")),
                filename: "Exampledocument.pdf",
                content_type: "application/pdf",
                metadata: nil
              )
            )
            Decidim::Comments::Seed.comments_for(project)
          end
        end

        Decidim::Budgets::Project.where.not(address: nil).find_each do |proposal|
          latitude, longitude = proposal.geocode

          proposal.update!(
            latitude: latitude,
            longitude: longitude
          )
        end
      end
    end


    proposals_url = "http://localhost:3000/processes/#{participatory_space.slug}/f/#{budget_component.id}/budgets/#{budget.id}/projects"
    benchmark_times = ENV.fetch("BENCHMARK_TIMES", 10).to_i
    title = ["Performance benchmark", ENV.fetch("BENCHMARK_PREFIX", "")].join(" ")
    prefix = ENV.fetch("BENCHMARK_PREFIX", "").gsub(" ", "_")
    file_name = [prefix, "performance_benchmark", benchmark_times.to_s].reject(&:empty?).join("_")
    count = Dir.glob("benchmarks/*").map { |f| f.split("/").last.split("_")[0..-2].join("_") }.select { |f| f == file_name.downcase }.count
    flags = ["default"] + ENV.fetch("BENCHMARK_FLAGS", "all").split(",").map(&:strip).reject(&:empty?).map(&:downcase)

    curl_command = ->(url, new) { `curl -sS -H "X-FEATURE-FLAG: #{new}" -o /dev/null #{url}` }
    benchmark_command = lambda do |url, flag, iteration|
      puts "Benchmarking #{url} #{iteration + (benchmark_times * flags.find_index(flag))} of #{benchmark_times * flags.size} with #{flag} flag"
      curl_command.call(url, flag)
    end

    puts "Benchmarking #{benchmark_times} times for #{proposals_url}..."

    Dir.mkdir("benchmarks") unless File.exist?("benchmarks")

    puts "Checking if url exists..."
    raise "Url returns an non 200 status" unless `curl -o /dev/null -s -w '%{http_code}' #{proposals_url}` == "200"

    puts "Url exists! Starting benchmark..."

    Dir.chdir("benchmarks") do
      Benchmark.plot (1..benchmark_times), title: title, file_name: [file_name, count].join("_").downcase do |x|
        flags.each do |flag|
          x.report flag.titleize do |i|
            benchmark_command.call(proposals_url, flag, i)
          end
        end
      end
    end
  end
end